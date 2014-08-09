module lang::php::experiments::mscse2014::mscse2014

import IO;
import Set;
import Relation;
import ValueIO;

import lang::php::util::Utils;
import lang::php::util::Corpus;

import lang::php::ast::System;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;
import lang::php::m3::FillM3;
import lang::php::m3::Declarations;
import lang::php::m3::Containment;
import lang::php::pp::PrettyPrinter;
import lang::php::types::TypeSymbol;
//import lang::php::types::TypeConstraints;

import lang::php::experiments::mscse2014::Constraints;

//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins/wsCorePlugin/modules/craftsman/lib|;
//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins|;
//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/|;
loc projectLocation = |file:///PHPAnalysis/systems/Kohana|;

loc cacheFolder = |file:///Users/ruud/tmp/m3/|;
loc firstM3CacheFile = cacheFolder + "first_m3_<projectLocation.file>.txt";
loc finalM3CacheFile = cacheFolder + "final_m3_<projectLocation.file>.txt";
//loc projectLocation = |file:///Users/ruud/test/types|;

public void run() {
	bool useCache = true;
	logMessage("Get system...", 1);
	System system = getSystem(projectLocation, useCache);
	M3 m3 = getM3ForSystem(system, useCache);

// all the needed 'facts' are already in the M3.
//	logMessage("Gathering facts", 1);
//	TypeFacts facts = getFacts(globalM3, system);

	logMessage("Fill subtype relation...", 1);
	rel[TypeSymbol, TypeSymbol] subTypeRelations = getSubTypes(m3, system);
	
	set[Constraint] constraints = getConstraints(system, m3);

	// find illegal subtype relations
	//globalM3 = calculateAfterM3Creation(globalM3, system);

	// not sure yet, if this is the way to go...
	//
	//logMessage("Populate classes with implementation of extended classes and implemented interfaces...", 1);
	//rel[loc,loc] propagatedContainment 
	//	= globalM3@containment
	//	+ getPropagatedExtensions(globalM3)
	//	+ getPropagatedImplementations(globalM3)
	//	;

	// print m3 info
	//printDuplicateDeclInfo(globalM3);
	

	//iprintln(globalM3@constructors);
	//iprintln(globalM3@modifiers);
	//iprintln(size(globalM3@modifiers));
}

private M3 getM3ForSystem(System system, bool useCache)
{
	M3 globalM3;
	
	if (useCache && isFile(firstM3CacheFile)) {
		logMessage("Reading M3 from cache...", 1);
		globalM3 = readBinaryValueFile(#M3, firstM3CacheFile);
	} else {
		logMessage("Get m3 collection...", 1);
		M3Collection m3s = getM3CollectionForSystem(system, projectLocation);
		logMessage("Get m3 ...", 1);
		globalM3 = M3CollectionToM3(m3s, projectLocation);
		writeBinaryValueFile(firstM3CacheFile, globalM3);
	}
	
	return globalM3;
}

// implement overloading (fields, methods and constants)
public rel[loc,loc] getPropagatedExtensions(M3 m3) 
{
	rel[loc,loc] extSet = {};
	
	for (<base,extends> <- m3@extends+) {
		// add the fields, methods and constants of the parent class to the 'base' class
		//extSet += { <base, ext[path=base.path+"/"+ext.file]> | ext <- m3@containment[extends] };
		extSet += { <base, ext> | ext <- m3@containment[extends] };
	}
	
	return extSet;
}

// implement intefaces (constants and methods)
public rel[loc,loc] getPropagatedImplementations(M3 m3) 
{
	rel[loc,loc] implSet = {};
	
	for (<base, implements> <- m3@implements) {
		// add the interface implementation to the base class
		//implSet += { <base, impl[path=base.path+"/"+impl.file]> | impl <- m3@containment[implements] };
		implSet += { <base, impl> | impl <- m3@containment[implements] };
	}
	
	return implSet;
}

public rel[TypeSymbol, TypeSymbol] getSubTypes(M3 m3, System system) 
{
	rel[TypeSymbol, TypeSymbol] subtypes
		// add int() as subtype of float()
		= { < integer(), float() > }
		// use the extends relation from M3
		+ { < class(c), class(e) > | <c,e> <- m3@extends }
		// add subtype of object for all classes which do not extends a class
		+ { < class(c@decl), object() > | l <- system, /c:class(n,_,noName(),_,_) <- system[l] };
		
	// compute reflexive transitive closure and return the result 
	return subtypes*;
}

// Helper methods, maybe remove this some at some moment
// Display number of duplicate classnames or classpaths (path is namespace+classname)
public void printDuplicateDeclInfo() = printDuplicateDeclInfo(readTextValueFile(#M3, finalM3CacheFile));
public void printDuplicateDeclInfo(M3 m3)
{
	// provide some cache:
	writeTextValueFile(finalM3CacheFile, m3);
	
	set[loc] classes = { d | <d,_> <- m3@declarations, isClass(d) };
	printMap("class", infoToMap(classes));
	
	set[loc] interfaces = { d | <d,_> <- m3@declarations, isInterface(d) };
	printMap("interfaces", infoToMap(interfaces));
	
	set[loc] traits = { d | <d,_> <- m3@declarations, isTrait(d) };
	printMap("trait", infoToMap(traits));
	
	set[loc] mixed = { d | <d,_> <- m3@declarations, isClass(d) || isInterface(d) || isTrait(d) };
	printMap("mixed", infoToMap(mixed));
	
	rel[str className, loc decl, loc fileName] t = { <d.file,d,f> | <d,f> <- m3@declarations, isClass(d) || isInterface(d) || isTrait(d) };
	iprintln({ x | x <- t, size(domainR(t, {x.className})) > 1});
}

public void printMap(str name, map[str, int] info) {
	println("------------------------------------");
	println("Total number of <name> decls: <info["total"]>");
	println("Unique <name> paths: <info["uniquePaths"]> (<(info["uniquePaths"]*100)/info["total"]>%)");
	println("Unique <name> names: <info["uniqueNames"]> (<(info["uniqueNames"]*100)/info["total"]>%)");
}

public map[str, int] infoToMap(set[loc] decls) 
	= (
		"total" : size(decls),
		"uniquePaths" : 	size({ d.path | d <- decls }),
		"uniqueNames" : 	size({ d.file | d <- decls })
	);
