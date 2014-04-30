@doc{
Synopsis: extends the M3 [$analysis/m3/Core] with Php specific concepts 

Description: 

For a quick start, go find [createM3FromEclipseProject].
}
module lang::php::m3::Core
extend analysis::m3::Core;

import lang::php::m3::AST;

import analysis::graphs::Graph;
import analysis::m3::Registry;

import lang::php::ast::AbstractSyntax;
import lang::php::ast::NormalizeAST;
import lang::php::m3::Containment;
import lang::php::util::Config;
import lang::php::util::Utils;
import lang::php::util::System;

import IO;
import String;
import Relation;
import Set;
import String;
import Map;
import Node;
import List;

import ValueIO;

alias M3Collection = map[loc fileloc, M3 model];

anno rel[loc from, loc to] M3@extends;      // classes extending classes and interfaces extending interfaces
anno rel[loc from, loc to] M3@implements;   // classes implementing interfaces
anno rel[loc from, loc to] M3@usesTrait;    // classes using traits and traits using traits
anno rel[loc from, loc to] M3@aliases;      // class name aliases (new name -> old name)
anno rel[loc pos, str phpDoc] M3@phpDoc;    // Multiline php comments /** ... */

public loc globalNamespace = |php+namespace:///|;

public M3 composePhpM3(loc id, set[M3] models) {
  m = composeM3(id, models);
  
  m@extends 	= {*model@extends       | model <- models};
  m@implements 	= {*model@implements    | model <- models};
  m@annotations = {*model@annotations 	| model <- models};
  m@phpDoc 		= {*model@phpDoc 		| model <- models};
  
  return m;
}

@doc{
Synopsis: globs for jars, class files and java files in a directory and tries to compile all source files into an [$analysis/m3] model
}
public M3Collection createM3sFromDirectory(loc l) = createM3sFromDirectory(l, true);

public M3Collection createM3sFromDirectory(loc l, bool useCache) {
	if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");
	if (l.scheme != "file") throw AssertionFailed("Location <l> must be an absolute path, use |file:///|");

	System system = ();
	if (useCache && cacheFileExists(l)) {
		logMessage("Reading <l> from cache.", 2);
		system = readSystemFromCache(l);
	} else {	    
    	system = loadPHPFiles(l);
	   	writeSystemToCache(system, l); 
	}
    system = normalizeSystem(system);
    return getM3CollectionForSystem(system);
}

// move to cache function file 
public void writeSystemToCache(System s, loc l) = writeBinaryValueFile(getCacheFileName(l), s);
public System readSystemFromCache(loc l) = readBinaryValueFile(#System, getCacheFileName(l));
public loc getCacheFileName(loc l) = |tmp:///| + "pa" +replaceAll(l.path, "/", "_");
public bool cacheFileExists(loc l) = isFile(getCacheFileName(l));
// end of cache functions

public System normalizeSystem(System s) {
	s = discardErrorScripts(s);
	
	for (l <- s) {
		s[l] = oldNamespaces(s[l]);
		s[l] = normalizeIf(s[l]);
		s[l] = flattenBlocks(s[l]);
		s[l] = discardEmpties(s[l]);
		s[l] = useBuiltins(s[l]);
		s[l] = discardHTML(s[l]);
	}
	
	return s;
}

public M3 createEmptyM3(loc file) {
	M3 m3 = composePhpM3(file, {});
	return m3;
}

public M3Collection getM3CollectionForSystem(System system) {
    M3Collection m3s = (l:createEmptyM3(l) | l <- system); // for each file, create an empty m3
	
	// fill declarations
	for (l <- system) {
		visit (system[l]) {
			case node n: {
				if ( (n@at)? && (n@decl)? ) {
					m3s[l]@declarations += {<n@decl, n@at>};
					m3s[l]@names += {<n@decl.file, n@decl>};
				}
			}
	   	}
	   	// if there are no namespaces, or no declarations at all, add global namespace
	   	if (!(m3s[l]@declarations)? || isEmpty({ ns | <ns,_> <- m3s[l]@declarations, isNamespace(ns) })) {
			m3s[l]@declarations += {<globalNamespace, l>};
	   	}
	}	
	
	// fill containtment with declarations
	for (l <- system) {
		m3s[l] = fillContainment(m3s[l], system[l]);
	}	
	
	
	// fill extends and implements, by trying to look up class names
	for (l <- system) {
		visit (system[l]) {
			case c:class(_,_,someName(name(name)),_,_): {
				set[loc] possibleExtends = getPossibleClassesInM3(m3s[l], name);
				m3s[l]@extends += {<c@decl, ext> | ext <- possibleExtends};
				fail; // continue this visit, a class can have extends and implements.
			}
			case c:class(_,_,_,list[Name] implements,_): {
				for (name <- [n | name(n) <- implements]) {
					set[loc] possibleImplements = getPossibleInterfacesInM3(m3s[l], name);
					m3s[l]@implements += {<c@decl, impl> | impl <- possibleImplements};
				}
			}	
			case c:interface(_,list[Name] implements,_): {
				for (name <- [n | name(n) <- implements]) {
					set[loc] possibleImplements = getPossibleInterfacesInM3(m3s[l], name);
					m3s[l]@implements += {<c@decl, impl> | impl <- possibleImplements};
				}
			}
	   	}
	}	
	
   	
   	// fill modifiers for classes, class fields and class methods
	for (l <- system) {
	   	visit (system[l]) {
   			case n:class(_,set[Modifier] mfs,_,_,_): 				m3s[l]@modifiers += {<n@decl, mf> | mf <- mfs};
			case n:property(set[Modifier] mfs,list[Property] ps): 	m3s[l]@modifiers += {<p@decl, mf> | mf <- mfs, p <- ps };	
			case n:method(_,set[Modifier] mfs,_,_,_):				m3s[l]@modifiers += {<n@decl, mf> | mf <- mfs};
   		}
   	}
   	 
 	// fill documentation, defined as @phpdoc
	for (l <- system) {
	  visit (system[l]) {
			case node n:
				if ( (n@decl)? && (n@phpdoc)? ) 
					m3s[l]@phpDoc += {<n@decl, n@phpdoc>};
		}	
	}

	// fill containment, for now only for compilationMethod, Class/Interface/Trait, Method, field
	for (l <- system) {
		visit (system[l]) {
			case _: ;
		}
	}

	return m3s;
}

public M3 addUsageForNode(M3 m3, Expr elm) {
	set decl = "";
	m3@uses += {<elm@at, decl> | decl <- decls};

}
 
public set[loc] getPossibleClassesInM3(M3 m3, str className) {
	set[loc] locs = {};
	
	for (name <- m3@names) 
		if (name.simpleName == className && isClass(name.qualifiedName))
			locs += name.qualifiedName;
				
	return isEmpty(locs) ? {|php+unknownClass:///| + className} : locs;
}
public set[loc] getPossibleInterfacesInM3(M3 m3, str className) {
	set[loc] locs = {};
	
	for (name <- m3@names) 
		if (name.simpleName == className && isInterface(name.qualifiedName))
			locs += name.qualifiedName;
				
	return isEmpty(locs) ? {|php+unknownInterface:///| + className} : locs;
}

public bool isNamespace(loc entity) = entity.scheme == "php+namespace";
public bool isClass(loc entity) = entity.scheme == "php+class";
public bool isInterface(loc entity) = entity.scheme == "php+interface";
public bool isTrait(loc entity) = entity.scheme == "php+trait";
public bool isMethod(loc entity) = entity.scheme == "php+method";
public bool isFunction(loc entity) = entity.scheme == "php+function";
public bool isParameter(loc entity) = entity.scheme == "php+functionParam" || entity.scheme == "php+methodParam";
public bool isVariable(loc entity) = entity.scheme == "php+globalVar" || entity.scheme == "php+functionVar" || entity.scheme == "php+methodVar";
public bool isField(loc entity) = entity.scheme == "php+field";
public bool isConstant(loc entity) = entity.scheme == "php+constant";
public bool isClassConstant(loc entity) = entity.scheme == "php+classConstant";

@memo public set[loc] namespaces(M3 m) = {e | e <- m@declarations<name>, isNamespace(e)};
@memo public set[loc] classes(M3 m) =  {e | e <- m@declarations<name>, isClass(e)};
@memo public set[loc] interfaces(M3 m) =  {e | e <- m@declarations<name>, isInterface(e)};
@memo public set[loc] traits(M3 m) = {e | e <- m@declarations<name>, isTrait(e)};
@memo public set[loc] functions(M3 m)  = {e | e <- m@declarations<name>, isFunction(e)};
@memo public set[loc] variables(M3 m) = {e | e <- m@declarations<name>, isVariable(e)};
@memo public set[loc] methods(M3 m) = {e | e <- m@declarations<name>, isMethod(e)};
@memo public set[loc] parameters(M3 m)  = {e | e <- m@declarations<name>, isParameter(e)};
@memo public set[loc] fields(M3 m) = {e | e <- m@declarations<name>, isField(e)};
@memo public set[loc] constants(M3 m) =  {e | e <- m@declarations<name>, isconstant(e)};
@memo public set[loc] classConstants(M3 m) =  {e | e <- m@declarations<name>, isClassConstant(e)};

public set[loc] elements(M3 m, loc parent) = { e | <parent, e> <- m@containment };

@memo public set[loc] fields(M3 m, loc class) = { e | e <- elements(m, class), isField(e) };
@memo public set[loc] methods(M3 m, loc class) = { e | e <- elements(m, class), isMethod(e) };
