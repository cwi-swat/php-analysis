module lang::php::experiments::mscse2014::mscse2014

import IO;
import Set;
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
import lang::php::m3::TypeSymbol;

//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins/wsCorePlugin/modules/craftsman/lib|;
//loc projectLocation = |file:///PHPAnalysis/systems/WerkspotNoTests/WerkspotNoTests-oldWebsiteNoTests/plugins|;
loc projectLocation = |file:///Users/ruud/test/types|;

public void main() {
	bool useCache = false;
	logMessage("Get system...", 1);
	System system = getSystem(projectLocation, useCache);

	logMessage("Get m3 collection...", 1);
	M3Collection m3s = getM3CollectionForSystem(system, projectLocation);
	logMessage("Get m3 ...", 1);
	M3 globalM3 = M3CollectionToM3(m3s, projectLocation);

	logMessage("Fill subtype relation...", 1);
	rel[TypeSymbol, TypeSymbol] subTypeRelations =  getSubTypes(globalM3, system);

	logMessage("Populate classes with implementation of extended classes and implemented interfaces...", 1);

	rel[loc,loc] propagatedContainment 
		= globalM3@containment
		+ getPropagatedExtensions(globalM3)
		+ getPropagatedImplementations(globalM3)
		;
	
	globalM3 = calculateAfterM3Creation(globalM3, system);
	
	iprintln(globalM3@constructors);
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
		= { < \int(), float() > }
		// use the extends relation from M3
		+ { < class(c), class(e) > | <c,e> <- m3@extends }
		// add subtype of object for all classes which do not extends a class
		+ { < class(c@decl), object() > | l <- system, /c:class(n,_,noName(),_,_) <- system[l] };
		
	// compute reflexive transitive closure and return the result 
	return subtypes*;
}