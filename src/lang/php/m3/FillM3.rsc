module lang::php::m3::FillM3
extend lang::php::m3::Core;

import Message;

import lang::php::m3::Containment;
import lang::php::m3::Aliases;
import lang::php::m3::Annotations;
import lang::php::m3::Containment;
import lang::php::m3::Declarations;
import lang::php::m3::Types;
import lang::php::m3::Uses;

import lang::php::ast::NormalizeAST;
import lang::php::ast::Scopes;
import lang::php::ast::System;

import Set;

private System modifiedSystem = ();
public System getModifiedSystem() = modifiedSystem;
public void resetModifiedSystem() { modifiedSystem = (); } // used in tests

private bool useCacheDefault = false;
// get a system for a specific location
public System getSystem(loc l) = getSystem(l, useCacheDefault);
public System getSystem(loc l, bool useCache) = isCacheUsed(l, useCache) ? readSystemFromCache(l) : loadSystem(l, useCache);

public M3Collection getM3CollectionForSystem(System system, loc l) = (filename:createM3forScript(filename, system[filename]) | filename <- system);

public M3 getM3ForSystem(System system, loc l)
{ 
	M3Collection m3s = getM3CollectionForSystem(system, l);
	M3 globalM3 = M3CollectionToM3(m3s, l);
	globalM3 = calculateAfterM3Creation(globalM3, system);
	
	return globalM3;
}

public M3 M3CollectionToM3 (M3Collection m3s, loc l) = composePhpM3(l, range(m3s));

@doc { extract M3 relations from a single PHP script }
private M3 createM3forScript(loc filename, Script script)
{
	M3 m3 = createEmptyM3(filename);

	if (errscript(m) := script)
	{
		m3@messages += [ error(m, filename) ];
		return m3;
	}
	
	try
	{
		script = addPublicModifierWhenNotProvided(script); // set Modifiers when they are not provided, like function => public function
   		m3 = fillDeclarations(m3, script); // fill @declarations and @names	
	   	script = propagateDeclToScope(script); // propagate @decl to @scope
	   	modifiedSystem[filename] = script; // a dirty hack to reuse this modified script...
   	
		m3 = fillContainment(m3, script); // fill containment with declarations 
		m3 = fillExtendsAndImplements(m3, script); // fill extends, implements and traitUse, by trying to look up class names 
		m3 = fillModifiers(m3, script); // fill modifiers for classes, class fields and class methods 
		m3 = fillPhpDocAnnotations(m3, script); // fill documentation, defined as @phpdoc
	
		m3 = calculateAliasesFlowInsensitive(m3, script); // fill aliases 
		m3 = calculateUsesFlowInsensitive(m3, script); // fill uses which are resolvable without type information
		
		m3 = fillParameters(m3, script); // add the parameters of all the methods
	}
	catch Exception e:
	{
		logMessage("Error: <e>", 1);
		m3@messages += error("<e>", filename); 
	}

	return m3;
}

public M3 calculateAfterM3Creation(M3 m3, System system) 
{ 
	// todo, add these predefined classes as scripts and run them through createM3forScript
	// tood: also add function like this
	m3 = addPredefinedDeclarations(m3);

	int counter = 0;
	int total = size(system);	
	println("calculateUsesAfterTypes for <total> files");
	for (l <- system) {
		counter += 1;
		//logMessage("running file: <l>", 1);
		if (counter%10==0) logMessage("<counter> (<(100*counter)/total>)%.. ", 1);	
		m3 = calculateUsesAfterTypes(m3, system[l]);
	}
	
	// todo enable this!
	//m3 = resolveTypes(m3, system);
	
	//logMessage("propagateUsesForUnresolvedItems", 2);
	//m3 = propagateUsesForUnresolvedItems(m3);
	
	return m3;
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

private M3 fillParameters(M3 m3, Script script)
{
	// add method and function parameters to m3@parameters
   	visit (script) {
		case f:function(_, _, list[Param] params, _): {
			ps = getParams(m3, params);
			m3@parameters += { <f@decl, ps> };	
		}
		case m:method(_, _, _, list[Param] params, _): {
			ps = getParams(m3, params);
			m3@parameters += { <m@decl, ps> };	
		}
   	}

	return m3;
}

private PhpParams getParams(M3 m3, list[Param] params)
{
	return {
		for (p:param(_, defaultValue, typeHint, ref) <- params) {
			bool dv = someExpr(_) := defaultValue ? true : false;
			set[loc] th = {};
			if (someName(name) := typeHint) {
				th = m3@uses[name@at];
				th = !isEmpty(th) ? th : { unknownLocation };
			}
			append <p@decl, th, dv, ref>;
		}
	}	
}

private M3 fillM3Constructors(M3 m3)
{
	for (c <- classes(m3)) {
		set[loc] constructors = getConstructorForClass(c, m3);
		if (!isEmpty(constructors)) {
			assert size(constructors)==1 : "More than one constructor found for class `<c>`";
			m3@constructors += <c, getOneFrom(constructors)>;
		}
	}
	
	return m3;
}

private set[loc] getConstructorForClass(loc class, M3 m3) {
	// how to find the constructor:
	// step 1: first check if method __construct is implemented
	// step 2: if the class is in the global namespace, check if there is a method with the same name as the class
	// step 3: try the same thing for the parent (extended) class
	set[loc] constructors = {};
	solve(class) {	
		// step 1:
		constructors = { m | m <- m3@containment[class], isMethod(m) && m.file == "__construct" };
		if (!isEmpty(constructors)) return constructors;	
	
		// step 2:
		if (globalNamespace == getNamespace(m3@containment, class)) {
			constructors = { m | m <- m3@containment[class], isMethod(m) && m.file == class.file };
			if (!isEmpty(constructors)) return constructors;	
		}
		
		// step 3:
		set[loc] extendedClass = m3@extends[class];
		if (!isEmpty(extendedClass)) {
			class = getOneFrom(extendedClass);
		}
	}
	
	return constructors;	
	
	if (methodName == "__construct") 
		return true; // __construct is always a constructor

	// if a class is in a global namespace, the constructor can be the name of the class (but only if __construct does not exist);		
	if (globalNamespace == getNamespace(scriptM3@containment, methodDecl)) 
	{
		loc classDecl = getClassTraitOrInterface(scriptM3@containment, methodDecl);
		set[str] classMethods = { elm.file | elm <- elements(scriptM3, classDecl), isMethod(elm) };
		if ("__construct" in classMethods) 
		{
			return false; // this method is not the constructor because __construct is.
		}
		else if (toLowerCase(methodName) == toLowerCase(classDecl.file)) 
		{
			return true; // __construct does not exist and this method has the same name as the class.	
		}
	}
	// the class of the method is not in global namespace and is not called "__construct"	
	return false; 
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
