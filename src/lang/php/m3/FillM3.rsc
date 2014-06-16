module lang::php::m3::FillM3
extend lang::php::m3::Core;

import Message;

import lang::php::m3::Containment;
import lang::php::m3::Aliases;
import lang::php::m3::Containment;
import lang::php::m3::Declarations;
import lang::php::m3::Types;
import lang::php::m3::Uses;

import lang::php::ast::NormalizeAST;
import lang::php::ast::Scopes;
import lang::php::ast::System;

import Set;

@doc { extract M3 relations from a single PHP script }
public M3 createM3forScript(loc filename, Script script)
{
	M3 m3 = createEmptyM3(filename);

	if (errscript(m) := script)
	{
		m3@messages += error(m, filename);
		return m3;
	}
	
	try
	{
		script = setEmptyModifiersToPublic(script); // set Modifiers when they are not provided, like function => public function
   		m3 = fillDeclarations(m3, script); // fill @declarations and @names	
	   	script = propagateDeclToScope(script); // propagate @decl to @scope
   	
		m3 = fillContainment(m3, script); // fill containment with declarations 
		m3 = fillExtendsAndImplements(m3, script); // fill extends, implements and traitUse, by trying to look up class names 
		m3 = fillModifiers(m3, script); // fill modifiers for classes, class fields and class methods 
		m3 = fillPhpDocAnnotations(m3, script); // fill documentation, defined as @phpdoc
	
		m3 = calculateAliasesFlowInsensitive(m3, script); // fill aliases 
		m3 = calculateUsesFlowInsensitive(m3, script); // fill uses which are resolvable without type information
	}
	catch Exception e:
	{
		logMessage("Error: <e>", 1);
		m3@messages += error("<e>", |unknown:///|);
	}

	return m3;
}

public M3 calculateAfterM3Creation(M3 m3, System system) 
{
	int systemSize = size(system), counter = 0, modulo = 50;
	
	logMessage("calculateTypesFlowInsensitive :: <systemSize>", 2);
	for (filename <- system) 
	{
		// fill types of variables
		m3 = calculateTypesFlowInsensitive(m3, propagateDeclToScope(system[filename])); 
		counter = counterPlusPlusAndPrint(counter, systemSize, modulo);
	}
	
	counter = 0;	
	logMessage("calculateUsesAfterTypes :: <systemSize>", 2);
	for (filename <- system) 
	{
		// fill uses using type information of variables
		m3 = calculateUsesAfterTypes(m3, propagateDeclToScope(system[filename])); 
		counter = counterPlusPlusAndPrint(counter, systemSize, modulo);
	}
		
	logMessage("propagateUsesForUnresolvedItems", 2);
	m3 = propagateUsesForUnresolvedItems(m3);
	
	return m3;
}

private int counterPlusPlusAndPrint(int counter, int size, int modulo) 
{
	if (logLevel >= 2) return counter;
	
	counter += 1;
		
	if (counter == size) 
		println(".. <counter>"); 
	else if (counter % modulo == 0)
		print(".. <counter>"); 
	
	return counter;
}

private M3 propagateUsesForUnresolvedItems(M3 m3) 
{
	for (m3Use <- m3@uses) {
		switch(m3Use.name.scheme) {
			case "php+unresolved+field":   m3@uses += { <m3Use.src, anyField> | anyField <- fields(m3) };
			case "php+unresolved+method":  m3@uses += { <m3Use.src, anyMethod> | anyMethod <- methods(m3) };
			case /^php+unresolved+.*Var$/: m3@uses += { <m3Use.src, anyVariable> | anyVariable <- variables(m3) };
		}
	}
	
	return m3;
}

private bool useCacheDefault = false;
// get a system for a specific location
public System getSystem(loc l) = getSystem(l, useCacheDefault);
public System getSystem(loc l, bool useCache) = isCacheUsed(l, useCache) ? readSystemFromCache(l) : loadSystem(l, useCache);

public M3 M3CollectionToM3 (M3Collection m3s, loc l) = composeM3(l, range(m3s));

public M3Collection getM3CollectionForSystem(System system, loc l) = (filename:createM3forScript(filename, system[filename]) | filename <- system);

//public M3 getM3ForDirectory(loc l) = getM3ForSystem(discardErrorScripts(getSystem(l)), l);
public M3 getM3ForSystem(System system, loc l)
{ 
	M3Collection m3s = getM3CollectionForSystem(system, l);
	M3 globalM3 = M3CollectionToM3(m3s, l);
	globalM3 = calculateAfterM3Creation(globalM3, system);
	
	return globalM3;
}

private M3 fillExtendsAndImplements(M3 m3, Script script) 
{
	visit (script) 
	{
		case c:class(_, _, someName(extends), implements, body): {
			m3@extends += {<c@decl, nameToLoc(extends, "class")>};
			m3@implements += {<c@decl, nameToLoc(name, "interface")> | name <- implements};
			
			for (traitUse(names, _) <- body) {
				m3@traitUses += {<c@decl, nameToLoc(name, "trait")> | name <- names};
			}		
		}
		
		case i:interface(_, extends, _): {
			m3@extends += {<i@decl, nameToLoc(name, "interface")> | name <- extends};
		}
		
		case t:trait(_, body): { 
			for (traitUse(names, _) <- body) {
				m3@traitUses += {<t@decl, nameToLoc(name, "trait")> | name <- names};
			}		
		}
   	}	
   	
   	return m3;
}

private M3 fillModifiers(M3 m3, Script script) {
   	// fill modifiers for classes, class fields and class methods
   	visit (script) {
		case n:class(_,set[Modifier] mfs,_,_,_): 				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		case n:property(set[Modifier] mfs,list[Property] ps): 	m3@modifiers += {<p@decl, mf> | mf <- mfs, p <- ps };	
		case n:method(_,set[Modifier] mfs,_,_,_):				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		
		//traitAlias isn't done here
	}
	return m3;
}

private M3 fillPhpDocAnnotations(M3 m3, Script script) {
	visit (script) {
		case node n:
			if ( (n@decl)? && (n@phpdoc)? ) 
				m3@phpDoc += {<n@decl, n@phpdoc>};
	}
	return m3;
}
	
// getSystem helper methods
private bool isCacheUsed(loc l, bool useCache) = useCache && cacheFileExists(l);
private System loadSystem(l, false) = loadPHPFiles(l); 
private System loadSystem(l, true) { 
	System system = loadPHPFiles(l); 
	logMessage("Writing system to cache...", 2);
	writeSystemToCache(system, l); 
	logMessage("Writing done.", 2);
	return system;
}
// end of getSystem helper methods

// to cache functions
private void writeSystemToCache(System s, loc l) = writeBinaryValueFile(getCacheFileName(l), s);
private System readSystemFromCache(loc l) {
	logMessage("Reading system from cache...", 2);
	System system = readBinaryValueFile(#System, getCacheFileName(l));
	logMessage("Reading done.", 2);
	return system;
}
private bool cacheFileExists(loc l) = isFile(getCacheFileName(l));
private loc getCacheFileName(loc l) = |tmp:///| + "pa" +replaceAll(l.path, "/", "_");
// end of cache functions
