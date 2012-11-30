@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::syntactic::Constants

import lang::php::ast::AbstractSyntax;
import Set;
import List;
import String;
import Exception;

@doc{An exception representing the case where a location is not a valid location in the system.}
data RuntimeException = UnavailableLoc(loc l);

@doc{Calculate a loc based on the base loc and an addition to the base loc path. This also ensures that the resulting
     loc is one of the possible locs, else an exception is thrown.}
public loc calculateLoc(set[loc] possibleLocs, loc baseLoc, str path) {
	list[str] parts = split("/",path);
	while([a*,b,"..",c*] := parts) parts = [*a,*c];
	while([a*,".",c*] := parts) parts = [*a,*c];
	if (parts[0] == "") {
		newLoc = |file:///| + intercalate("/",parts);
		if (newLoc in possibleLocs) return newLoc;
		throw UnavailableLoc(newLoc);
	} else {
		newLoc = baseLoc + intercalate("/",parts);
		if (newLoc in possibleLocs) return newLoc;
		throw UnavailableLoc(newLoc);
	}
}

@doc{Get constant definitions from the script at location l, including definitions from other scripts this script includes.}
public map[str,Expr] getConstants(map[loc fileloc, Script scr] scripts, loc l) = getConstants(scripts,{},l);

@doc{Get constant definitions from the script at location l, including definitions from other scripts this script includes. The
     set includeLocs ensures we do not loop; if we have already processed the location in this set, we just return immediately.}
public map[str,Expr] getConstants(map[loc fileloc, Script scr] scripts, set[loc] includedLocs, loc l) {
	rel[str,Expr] resRel = { };
	
	// First, check to make sure we don't loop. Then, throw the current loc in so we don't later. Note: this 
	// doesn't mean we cannot visit the same loc twice, we just won't ever loop.
	if (l in includedLocs) return ( );
	includedLocs += l;
	
	// This just gets back the current script we are working on
	s = scripts[l];
	
	// Then, grab back all includes which only have a string as the path, as we can figure
	// these out statically.
	set[str] scalarIncs = { pth | /i:include(scalar(string(pth)),_) := s };
	
	// For each of these includes, go through and get the constants. Note that, at this point,
	// we are just building a relation; this is because we could have a situation where the
	// same constant is defined with multiple values, and we are looking just for those that
	// have a unique definition.
	for (pth <- scalarIncs) {
		try {
			includeLoc = calculateLoc(scripts<0>, l, pth);
			resMap = getConstants(scripts, includedLocs, includeLoc);
			for (rk <- resMap<0>) resRel += < rk, resMap[rk] >;
		} catch UnavailableLoc(ul) : {
			;
		}
	}
	
	// Next, add any constants in this script into the constant rel.
	resRel += { < cn, e > | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e:scalar(sv),false)]) := s };
	
	// Finally, build a map of constant results. This is just those results that appear only once
	// in the result relation.
	return ( cn : e | <cn,e> <- resRel, size(resRel[cn]) == 1 );
}

data SignatureItem
	= functionSig(str functionName, int parameterCount)
	| constSig(str constName, Expr e)
	| classSig(str className)
	| methodSig(str className, str methodName, int parameterCount)
	| classConstSig(str className, str constName, Expr e)
	;

data Signature
	= fileSignature(loc fileloc, set[SignatureItem] items)
	;
		
public Signature getFileSignature(loc fileloc, Script scr) {
	set[SignatureItem] items = { };
	
	// First, pull out all class definitions
	classDefs = { c | /ClassDef c := scr };
	for (class(cn,_,_,_,cis) <- classDefs) {
		items += classSig(cn);
		for (method(mn,_,_,mps,_) <- cis) {
			items += methodSig(cn, mn, size(mps));
		}
		for(constCI(consts) <- cis, const(name,ce) <- consts) {
			items += classConstSig(cn, name, ce);
		}
	}
	
	// Second, get all top-level functions
	items += { functionSig(fn,size(fps)) | /f:function(fn,_,fps,_) := scr };

	// TODO: We also want to add global variables here, but need to do this in the
	// right way -- we don't know, at this point, if a name is introduced here for
	// the first time, or is brought in through another include. The only way to
	// know this for sure is either to a) resolve the includes here, or b) determine
	// that there are no includes.
		
	// Finally, get all defined constants
	items += { constSig(cn,e) | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e,false)]) := scr };
	
	return fileSignature(fileloc, items);
}
		
public map[loc,Signature] getSystemSignatures(map[loc fileloc, Script scr] scripts) {
	return ( l : getFileSignature(l,scripts[l]) | l <- scripts );
}

public rel[str, loc] getAllDefinedConstants(map[loc fileloc, Script scr] scripts) {
	ssigs = getSystemSignatures(scripts);
	return { < cn, l > | fileSignature(l,sis) <- ssigs<1>, constSig(cn) <- sis };
}

// Goal: generate a module signature with all public info in the module; this can be used to constrain which
// files could be included
