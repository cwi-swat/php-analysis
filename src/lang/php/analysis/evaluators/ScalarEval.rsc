@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::ScalarEval

import lang::php::ast::AbstractSyntax;
import Set;
import List;
import String;
import Exception;

public Script evalMagicConstants(Script scr, loc l) {
	// TODO: Add the rest of the cases when we have the proper context (e.g.,
	// we do not know what class we are in, so we cannot add support for the
	// class name magic constant at this point in time)
	scr2 = bottom-up visit(scr) {
		case s:scalar(fileConstant()) => scalar(string(l.path))[@at=s@at]
		case s:scalar(dirConstant()) => scalar(string(l.parent.path))[@at=s@at]
		case s:scalar(lineConstant()) : {
			try {
				insert(scalar(integer(s@at.begin.line))[@at=s@at]);
			} catch UnavailableInformation() : {
				println("Tried to extract line number from location <s@at> with no line number information");
			}
		}
	}
	return scr2;
}

public Script evalOps(Script scr) {
	scr2 = bottom-up visit(scr) {
		case e:binaryOperation(scalar(string(s1)),scalar(string(s2)),concat()) =>
			 scalar(string(s1+s2))[@at=e@at]
	}
	return scr2;
}

public Script evalDirname(Script scr) {
	scr2 = visit(scr) {
		case c:call(name(name("dirname")),[actualParameter(scalar(string(s1)),false)]) : {
			try {
				repLoc = |file:///| + s1;
				insert(scalar(string(repLoc.parent.path))[@at=c@at]);
			} catch MalFormedURI(estr) : {
				; // do nothing, we just don't make any changes
			}
		}
	}
	return scr2;
}

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
public map[str,Expr] getConstants(rel[loc fileloc, Script scr] corpus, loc l) = getConstants(corpus,{},l);

@doc{Get constant definitions from the script at location l, including definitions from other scripts this script includes. The
     set includeLocs ensures we do not loop; if we have already processed the location in this set, we just return immediately.}
public map[str,Expr] getConstants(rel[loc fileloc, Script scr] corpus, set[loc] includedLocs, loc l) {
	rel[str,Expr] resRel = { };
	
	// First, check to make sure we don't loop. Then, throw the current loc in so we don't later. Note: this 
	// doesn't mean we cannot visit the same loc twice, we just won't ever loop.
	if (l in includedLocs) return ( );
	includedLocs += l;
	
	// This just gets back the current script we are working on
	s = getOneFrom(corpus[l]);
	
	// Then, grab back all includes which only have a string as the path, as we can figure
	// these out statically.
	set[str] scalarIncs = { pth | /i:include(scalar(string(pth)),_) := s };
	
	// For each of these includes, go through and get the constants. Note that, at this point,
	// we are just building a relation; this is because we could have a situation where the
	// same constant is defined with multiple values, and we are looking just for those that
	// have a unique definition.
	for (pth <- scalarIncs) {
		try {
			includeLoc = calculateLoc(corpus<0>, l, pth);
			resMap = getConstants(corpus, includedLocs, includeLoc);
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

@doc{Evaluate any constants, replacing them with their assigned value in cases where this assigned value
     is itself a literal.}
public Script evalConsts(rel[loc fileloc, Script scr] corpus, loc l, map[str, Expr] constMap) {
	map[str,Expr] constsInScript = getConstants(corpus, l);
	Script scr = getOneFrom(corpus[l]);  
	scr2 = visit(scr) {
		case c:fetchConst(name(s)) : {
			if (s in constsInScript)
				insert(constsInScript[s][@at=c@at]);
			else if (s in constMap) 
				insert(constMap[s][@at=c@at]);
		}
	}
	return scr2;
}

public rel[str product, str version, loc fileloc, Script scr] evalAllScalars(rel[str product, str version, loc fileloc, Script scr] corpus, str p, str v) {
	solve(corpus) {
		corpus = { <p,v,l,evalOps(evalDirname(evalMagicConstants(s,l)))> | <p,v,l,s> <- corpus };

		// This is in the solve because it can change on each iteration. This is all the constants that are
		// defined just once in the system. This is used as a "backup" to the more detailed analysis above,
		// since it could be that these constants are brought in with an include that itself has a non-literal
		// path (meaning the more detailed analysis won't find it).
		//
		// NOTE: This could give a wrong result, in the sense that we would have a constant that would actually,
		// at runtime, be an error, for instance if the programmer uses the constant without actually importing
		// the defining script.
		rel[str,Expr] constRel = { < cn, e > | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e:scalar(sv),false)]) := corpus[p,v,_] };
		map[str,Expr] constMap = ( s : e | <s,e> <- constRel, size(constRel[s]) == 1 ); 

		corpus = { <p,v,l,evalConsts(corpus<2,3>,l,constMap)> | <p,v,l,s> <- corpus };
	}			
	return corpus;
}
