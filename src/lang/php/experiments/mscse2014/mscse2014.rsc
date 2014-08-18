module lang::php::experiments::mscse2014::mscse2014

import IO;
import Relation;
import Set;
import String;
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
import lang::php::types::TypeConstraints;

import lang::php::experiments::mscse2014::Constraints;

//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins/wsCorePlugin/modules/craftsman/lib|;
//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins|;
//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/|;
loc projectLocation = |file:///PHPAnalysis/systems/Kohana|;
//loc projectLocation = |file:///Users/ruud/test/types|;
//loc projectLocation = |file:///Users/ruud/tmp/solve/scalar|;

private loc getProjectLocation() = projectLocation;
private void setProjectLocation(loc pl) { projectLocation = pl; }

loc cacheFolder = |file:///Users/ruud/tmp/m3/|;
loc firstM3CacheFile = cacheFolder + "first_m3_<projectLocation.file>.bin";
loc finalM3CacheFile = cacheFolder + "final_m3_<projectLocation.file>.bin";

loc getLastM3CacheFile() = cacheFolder + "last_m3_<getProjectLocation().file>.bin";
loc getModifiedSystemCacheFile() = cacheFolder + "last_system_<getProjectLocation().file>.bin";
loc getLastConstraintsCacheFile() = cacheFolder + "last_constraints_<getProjectLocation().file>.bin";
loc getParsedSystemCacheFile() = cacheFolder + "plain_system_<getProjectLocation().file>.bin";


//public void main() {
//	println("Run instructions:");
//	println("----------------");
//	println("1) Run run1() to create the m3 (and save system and m3 to cache)");
//	println("2) Run run3() to collect constraints (and save the constraints to cache)");
//	println("3) Run run4() to solve the constraints (and print the results)");
//	println("----------------");
//}
private map[str,str] corpus = (
	"osCommerce":"2.3.1",
	"ZendFramework":"1.11.12",
	"CodeIgniter":"2.1.2",
	"Symfony":"2.0.12",
	"SilverStripe":"2.4.7",
	"WordPress":"3.4",
	"Joomla":"2.5.4",
	"phpBB":"3",
	"Drupal":"7.14",
	"MediaWiki":"1.19.1",
	"Gallery":"3.0.4",
	"SquirrelMail":"1.4.22",
	"Moodle":"2.3",
	//"Smarty":"3.1.11"//,
	"Kohana":"3.2",
	"phpMyAdmin":"3.5.0-english",
	"PEAR":"1.9.4",
	"CakePHP":"2.2.0-0",
	"DoctrineORM":"2.2.2",
	"WerkspotNoTests":"oldWebsiteNoTests"
);

public void run() {
	run1();
	run3();
	run4();
	run4();
}

public void run1() {
	println("This first step will save the parsed files to the filesystem");
	bool useCache = false;
	logMessage("Get system...", 1);
	System system = getSystem(getProjectLocation(), useCache);
	writeBinaryValueFile(getParsedSystemCacheFile(), system);
	println("This first step will save the parsed files to the filesystem");
	
}

public void run2() {
	assert isFile(getParsedSystemCacheFile()) : "Please run run1() first. Error: file(<getParsedSystemCacheFile()>) was not found";
	
	println("This second step will save a modified system and create a global M3 file");
	logMessage("Reading parsed system from cache...", 1);
	System system = readBinaryValueFile(#System, getParsedSystemCacheFile());
	
	bool useCache = false;
	logMessage("Get M3 For System...", 1);
	M3 m3 = getM3ForSystem(system, useCache);
	logMessage("Get modified system...", 1);
	system = getModifiedSystem(); // for example the script is altered with scope information
	logMessage("Calculate After M3 Creation...", 1);
	m3 = calculateAfterM3Creation(m3, system);

	logMessage("Writing system and m3 to filesystem", 1);	
	writeBinaryValueFile(getLastM3CacheFile(), m3);
	writeBinaryValueFile(getModifiedSystemCacheFile(), system);
	
	logMessage("M3 and System are written to the file system. Please run run3() now.",1);
}

public void run3() {
	// precondition: system and m3 cache file must exist
	assert isFile(getModifiedSystemCacheFile()) : "Please run run1() first. Error: file(<getModifiedSystemCacheFile()>) was not found";
	assert isFile(getLastM3CacheFile())     : "Please run run1() first. Error: file(<getLastM3CacheFile()>) was not found";
	
	logMessage("Reading system from cache...", 1);
	System system = readBinaryValueFile(#System, getModifiedSystemCacheFile());
	logMessage("Reading M3 from cache...", 1);
	M3 m3 = readBinaryValueFile(#M3, getLastM3CacheFile());
	logMessage("Reading done.", 1);

	set[Constraint] constraints = getConstraints(system, m3);
	
	logMessage("Writing contraints to the file system", 1);
	writeBinaryValueFile(getLastConstraintsCacheFile(), constraints);
	logMessage("Writing done. Now please run run4() (once it is created...)", 1);

	// not sure yet, if this is the way to go... because there 
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

public void run4()
{
	// precondition: constraints and m3 cache file must exist
	assert isFile(getLastConstraintsCacheFile()) : "Please run run1() first. Error: file(<getLastConstraintsCacheFile()>) was not found";
	assert isFile(getLastM3CacheFile())          : "Please run run1() first. Error: file(<getLastM3CacheFile()>) was not found";
	
	logMessage("Reading constraints from cache...", 1);
	set[Constraint] constraints = readBinaryValueFile(#set[Constraint], getLastConstraintsCacheFile());
	logMessage("Reading M3 from cache...", 1);
	M3 m3 = readBinaryValueFile(#M3, getLastM3CacheFile());
	logMessage("Reading done.", 1);

	logMessage("Now solving the constraints...", 1);	
	map[TypeOf var, TypeSet possibles] solveResult = solveConstraints(constraints, m3);
	logMessage("Done. Printing results:", 1);
	println(solveResult);
}

private M3 getM3ForSystem(System system, bool useCache)
{
	M3 globalM3;
	
	if (useCache && isFile(firstM3CacheFile)) {
		logMessage("Reading M3 from cache...", 1);
		globalM3 = readBinaryValueFile(#M3, firstM3CacheFile);
	} else {
		logMessage("Get m3 collection...", 1);
		M3Collection m3s = getM3CollectionForSystem(system, getProjectLocation());
		logMessage("Get m3 ...", 1);
		globalM3 = M3CollectionToM3(m3s, getProjectLocation());
		logMessage("Writing first m3 to cache ...", 1);
		writeBinaryValueFile(firstM3CacheFile, globalM3);
		logMessage("Writing done.", 1);
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

// moved to constraints
//public rel[TypeSymbol, TypeSymbol] getSubTypes(M3 m3, System system) 
//{
//	rel[TypeSymbol, TypeSymbol] subtypes
//		// add int() as subtype of float()
//		= { < integerType(), floatType() > }
//		// use the extends relation from M3
//		+ { < classType(c), classType(e) > | <c,e> <- m3@extends }
//		// add subtype of object for all classes which do not extends a class
//		+ { < classType(c@decl), objectType() > | l <- system, /c:class(n,_,noName(),_,_) <- system[l] };
//		
//	// compute reflexive transitive closure and return the result 
//	return subtypes*;
//}

// Helper methods, maybe remove this some at some moment
// Display number of duplicate classnames or classpaths (path is namespace+classname)
public void printDuplicateDeclInfo() = printDuplicateDeclInfo(readBinaryValueFile(#M3, finalM3CacheFile));
public void printDuplicateDeclInfo(M3 m3)
{
	// provide some cache:
	writeBinaryValueFile(finalM3CacheFile, m3);
	
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

public void printIncludeScopeInfo() {
	// precondition: system and m3 cache file must exist
	assert isFile(getModifiedSystemCacheFile()) : "Please run run1() first. Error: file(<getModifiedSystemCacheFile()>) was not found";
	
	logMessage("Reading system from cache...", 1);
	System system = readBinaryValueFile(#System, getModifiedSystemCacheFile());	
	
	rel[loc, loc, IncludeType] includeInScope = {};
	for (s <- system) {
		println(s);
		visit(system[s]) {
			case i:include(_,t): 
				includeInScope += { <i@at, i@scope, t> };
		}
	}
		
	println("all scopes (<size(includeInScope)>):");
	iprintln(domain(includeInScope));
}

public void run1ForAll() {
	loc projectLoc;	
	for(c <- corpus) {
		setProjectLocation(toLocation("file:///PHPAnalysis/systems/<c>"));
		if (isFile(getParsedSystemCacheFile())) {
			println("Skipped! If you want to recreate the files, please remove this file: <getParsedSystemCacheFile()>");	
		} else {
			println("Run1 for location: <getProjectLocation()>");
			run1();
		}
	}
}	

public void run2ForAll() {
	loc projectLoc;	
	for(c <- corpus) {
		setProjectLocation(toLocation("file:///PHPAnalysis/systems/<c>"));
		if (isFile(getModifiedSystemCacheFile()) && isFile(getLastM3CacheFile())) {
			println("Skipped! If you want to recreate the files, please remove these files: <getModifiedSystemCacheFile()> and <getLastM3CacheFile()>");
		} else {
			println("Run2 for location: <getProjectLocation()>");
			run2();
		}
	}
}	

public void printIncludeScopeInfoForAll() {
	loc projectLoc;	
	for(c <- corpus) {
		setProjectLocation(toLocation("file:///PHPAnalysis/systems/<c>"));
		println("Running printIncludeScopeInfoFor <getProjectLocation()>");
		printIncludeScopeInfo();
	}
}	