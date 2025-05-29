@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::DefinedConstants

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::signatures::Signatures;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::ast::System;
import lang::php::analysis::NamePaths;

import Set;
import List;
import Map;

data ConstItem = normalConst(str constName) | classConst(str className, str constName);

data ConstItemExp = normalConst(str constName, Expr e) | classConst(str className, str constName, Expr e);

@doc{Evaluate any constants, replacing them with their assigned value in cases where 
	 this assigned value is itself a literal.}
public Script evalConsts(loc scriptLoc, Script scr, ConstInfo cinfo, set[IncludeGraphNode] reachable, map[loc,Signature] sigs) {
	// If we can reach an unknown (i.e., dynamic) include on our include path, this means
	// we could pull in alternate definitions for the include. In this case, we just use
	// the constMap, since that contains constants that we know are uniquely defined.
	map[ConstItem,Expr] replacements = ( ); 	
	usedConsts = cinfo.systemConstUses[scriptLoc];

	if (unknownNode() in reachable) {
		//println("A dynamic include is reachable from <head(scr.body).at.path>, using unique constants");
		for (usedConst <- usedConsts) {
			if (normalConst(cn) := usedConst && cn in cinfo.constMap)
				replacements[usedConst] = cinfo.constMap[cn];
			else if (classConst(cln,cn) := usedConst && cln in cinfo.classConstMap && cn in cinfo.classConstMap[cln])
				replacements[usedConst] = cinfo.classConstMap[cln][cn];
		}
	} else {
		reachableLocs = { l | igNode(_,l) <- reachable };
		for (usedConst <- usedConsts) {
			if (normalConst(cn) := usedConst && !isEmpty(reachableLocs & cinfo.constDefLocs[cn])) {
				//definingExprs = cinfo.
				replacements[usedConst] = cinfo.constMap[cn];
			} else if (classConst(cln,cn) := usedConst && !isEmpty(reachableLocs & cinfo.classConstDefLocs[cln][cn])) {
				replacements[usedConst] = cinfo.classConstMap[cln][cn];
			}
		}
	}
		

	// Restrict the signatures we look at to only those that are reachable, based on our current
	// knowledge of the includes relation (which is what the reachable parameter is based on)
	reachableLocs = { l | igNode(_,l) <- reachable };
	reachableSigs = domainR(sigs, reachableLocs);

	// Get back all the constants, by name. Then, narrow this down -- only keep those where 
	// 1) only one constant of that name is found, and
	// 2) the definition of the constant is a constant (scalar) value.
	rel[str,Expr] constsRel = { <getConstName(np),ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], constSig(np,ce) <- items };
	map[str,Expr] constsInScript = ( cn : ce | cn <- constsRel<0>, size(constsRel[cn]) == 1, ce:scalar(sv) := getOneFrom(constsRel[cn]), encapsed(_) !:= sv );

	// Do the same as the above, but for class constants, not standard constants.
	rel[str,str,Expr] classConstsRel = { <getClassConstClassName(np), getClassConstName(np),ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], classConstSig(np,ce) <- items };
	map[str,map[str,Expr]] classConstsInScript = ( cln : 
		( cn : ce | cn <- classConstsRel[cln]<0>, size(classConstsRel[cln,cn]) == 1, ce:scalar(sv) := getOneFrom(classConstsRel[cln,cn]), encapsed(_) !:= sv ) 
		| cln <- classConstsRel<0> );

	// Replace constants and class constants with their defining values where possible
	scr = visit(scr) {
		case c:fetchClassConst(name(name(cln)), str cn) : {
			if (cln in cinfo.classConstMap && cn in cinfo.classConstMap[cln]) {
				insert(cinfo.classConstMap[cln][cn][at=c.at]);
			} else if (cln in classConstsInScript && cn in classConstsInScript[cln]) {
				insert(classConstsInScript[cln][cn][at=c.at]);
			}
		}
		
		case c:fetchConst(name(s)) : {
			if (s in cinfo.constMap) {
				insert(cinfo.constMap[s][at=c.at]);
			} else if (s in constsInScript) {
				insert(constsInScript[s][at=c.at]);
			}
		}
	}
	return scr;
}

public set[ConstItem] getScriptConstUses(Script scr) {
	set[ConstItem] res = { };
	visit(scr) {
		case fetchConst(name(s)) :
			res += normalConst(s);
		case fetchClassConst(name(name(cln)), cn) :
			res += classConst(cln, cn);
	}
	return res;
}

public set[ConstItemExp] getScriptConstDefs(Script scr) =
	{ classConst(cln, cn, ce) | /class(cln,_,_,_,cis,_) := scr, classConst(consts,_,_) <- cis, const(cn,ce) <- consts } + // TODO: Do we need to worry about const modifiers?
	{ normalConst(cn, ce) | /call(name(name("define")),[actualParameter(scalar(string(cn)),false,false,_),actualParameter(ce,false,false,_)]) := scr } +
	{ normalConst(cn, ce) | /Stmt::const(cl) := scr, Const::const(cn,ce) <- cl };

public set[ConstItemExp] getSignatureConsts(Signature sig) {
	set[ConstItemExp] res = { };
	if (fileSignature(_,items) := sig) {
		res = { classConst(getClassConstClassName(np), getClassConstName(np), ce) | classConstSig(np,ce) <- items } + 
			  { normalConst(getConstName(np), ce) | constSig(np,ce) <- items };
	}
	return res; 
}

data ConstInfo = constInfo(
	map[loc,set[ConstItemExp]] systemConstDefs,
	map[str constName, set[loc] defLocs] constDefLocs,
	map[str className, map[str constName, set[loc] defLocs] clLocs] classConstDefLocs,
	map[str constName, map[loc defLoc,set[Expr] defExprs] defLocMap] constDefExprs,
	map[str className, map[str constName, map[loc defLoc,set[Expr] defExprs] defLocMap] clLocs] classConstDefExprs,
	map[loc,set[ConstItem]] systemConstUses,
	map[str constName, set[loc] useLocs] constUses,
	map[str className, map[str constName, set[loc] useLocs] clLocs] classConstUses,
	map[str, Expr] constMap,
	map[str, map[str, Expr]] classConstMap);

public ConstInfo getConstInfo(System sys) {
	sigs = getSystemSignatures(sys);
	
	systemConstDefs = getSystemConstDefs(sigs);
	constDefLocs = getConstDefLocs(systemConstDefs);
	classConstDefLocs = getClassConstDefLocs(systemConstDefs);
	constDefExprs = getConstDefExprs(systemConstDefs);
	classConstDefExprs = getClassConstDefExprs(systemConstDefs);

	systemConstUses = getSystemConstUses(sys);
	constUseLocs = getConstUseLocs(systemConstUses);
	classConstUseLocs = getClassConstUseLocs(systemConstUses);
	
	map[str, Expr] constMap = ( );
	predefined = { constName | cl <- systemConstDefs, normalConst(str constName, _) <- systemConstDefs[cl] };
	if ("DIRECTORY_SEPARATOR" notin predefined)
		constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
	if ("PATH_SEPARATOR" notin predefined)
		constMap["PATH_SEPARATOR"] = scalar(string(":"));
	constMap += ( cn : ce | cn <- constDefExprs, cset := { de | l <- constDefExprs[cn], de <- constDefExprs[cn][l] }, size(cset) == 1, ce:scalar(sv) := getOneFrom(cset), encapsed(_) !:= sv );  

	map[str, map[str, Expr]] classConstMap = ( );
	for (cln <- classConstDefExprs) {
		constsForCln = classConstDefExprs[cln];
		mapForCn = ( cn : ce | cn <- constsForCln, cset := { de | l <- constsForCln[cn], de <- constsForCln[cn][l] }, size(cset) == 1, ce:scalar(sv) := getOneFrom(cset), encapsed(_) !:= sv );
		classConstMap[cln] = mapForCn; 
	}
	
	return constInfo(systemConstDefs, constDefLocs, classConstDefLocs, constDefExprs,
					 classConstDefExprs, systemConstUses, constUseLocs, classConstUseLocs,
					 constMap, classConstMap); 	
}
	
public map[loc,set[ConstItem]] getSystemConstUses(System sys) = ( l : getScriptConstUses(sys.files[l]) | l <- sys.files);

public map[str constName, set[loc] useLocs] getConstUseLocs(map[loc,set[ConstItem]] constUses) {
	map[str constName, set[loc] useLocs] res = ( );
	for (l <- constUses, normalConst(cn) <- constUses[l]) 
		if (cn in res)
			res[cn] = res[cn] + l;
		else
			res[cn] = { l };
	return res;
}

public map[str className, map[str constName, set[loc] useLocs] clLocs] getClassConstUseLocs(map[loc,set[ConstItem]] constUses) {
	map[str className, map[str constName, set[loc] useLocs] clLocs] res = ( );
	for (l <- constUses, classConst(cln,cn) <- constUses[l]) {
		if (cln in res)
			if (cn in res[cln])
				res[cln][cn] = res[cln][cn] + l;
			else
				res[cln][cn] = { l };
		else
			res[cln] = ( cn : { l } );
	}
	return res;
}

public map[str constName, set[loc] defLocs] getConstDefLocs(map[loc,set[ConstItemExp]] constDefs) {
	map[str constName, set[loc] defLocs] res = ( );
	for (l <- constDefs, normalConst(cn,_) <- constDefs[l]) 
		if (cn in res)
			res[cn] = res[cn] + l;
		else
			res[cn] = { l };
	return res;
}

map[str constName, map[loc defLoc,set[Expr] defExprs] defLocMap] getConstDefExprs(map[loc,set[ConstItemExp]] constDefs) {
	map[str constName, map[loc defLoc,set[Expr] defExprs] defLocMap] res = ( );
	for (l <- constDefs, normalConst(cn,ce) <- constDefs[l]) 
		if (cn in res) {
			if (l in res[cn]) {
				res[cn][l] = res[cn][l] + ce;
			} else {
				res[cn] = ( l : { ce });
			}
		} else {
			res[cn] = ( l : { ce });
		}
	return res;
}

public map[str className, map[str constName, set[loc] defLocs] clLocs] getClassConstDefLocs(map[loc,set[ConstItemExp]] constDefs) {
	map[str className, map[str constName, set[loc] defLocs] clLocs] res = ( );
	for (l <- constDefs, classConst(cln,cn,_) <- constDefs[l]) {
		if (cln in res)
			if (cn in res[cln])
				res[cln][cn] = res[cln][cn] + l;
			else
				res[cln][cn] = { l };
		else
			res[cln] = ( cn : { l } );
	}
	return res;
}

public map[str className, map[str constName, map[loc defLoc,set[Expr] defLocs] defLocMap] clLocs] getClassConstDefExprs(map[loc,set[ConstItemExp]] constDefs) {
	map[str className, map[str constName, map[loc defLoc,set[Expr] defLocs] defLocMap] clLocs] res = ( );
	for (l <- constDefs, classConst(cln,cn,ce) <- constDefs[l]) {
		if (cln in res)
			if (cn in res[cln])
				if (l in res[cln][cn])
					res[cln][cn][l] = res[cln][cn][l] + ce;
				else
					res[cln][cn] = res[cln][cn] + ( l : { ce });
			else
				res[cln] = ( cn : ( l : { ce }));
		else
			res[cln] = ( cn : ( l : { ce } ) );
	}
	return res;
}

public map[loc,set[ConstItemExp]] getSystemConstDefs(map[loc,Signature] sigs) = ( l : getSignatureConsts(sigs[l]) | l <- sigs );

