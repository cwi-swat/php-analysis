@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::DefinedConstants

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::signatures::Signatures;
import lang::php::analysis::includes::IncludeGraph;

import Set;
import List;
import String;
import Exception;
import Map;
import IO;

@doc{Evaluate any constants, replacing them with their assigned value in cases where 
	 this assigned value is itself a literal.}
public Script evalConsts(Script scr, map[str, Expr] constMap, map[str, map[str, Expr]] classConstMap, set[IncludeGraphNode] reachable, map[loc,Signature] sigs) {
	// If we can reach an unknown (i.e., dynamic) include on our include path, this means
	// we could pull in alternate definitions for the include. In this case, we just use
	// the constMap, since that contains constants that we know are uniquely defined. 	
	if (unknownNode() in reachable) {
		println("A dynamic include is reachable from <head(scr.body)@at.path>, using unique constants");
		scr = visit(scr) {
			case c:fetchConst(name(s)) : {
				if (s in constMap) { 
					insert(constMap[s][@at=c@at]);
				}
			}

			case c:fetchClassConst(name(name(cln)), cn) : {
				if (cln in classConstMap && cn in classConstMap[cln]) {
					insert(classConstMap[cln][cn][@at=c@at]);
				}
			}
		}
		return scr;
	}

	// Restrict the signatures we look at to only those that are reachable, based on our current
	// knowledge of the includes relation (which is what the reachable parameter is based on)
	reachableLocs = { l | igNode(_,l) <- reachable };
	reachableSigs = domainR(sigs, reachable);

	// Get back all the constants, by name. Then, narrow this down -- only keep those where 
	// 1) only one constant of that name is found, and
	// 2) the definition of the constant is a constant (scalar) value.
	rel[str,Expr] constsRel = { <cn,ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], constSig([global(),const(cn)],ce) <- items };
	map[str,Expr] constsInScript = ( cn : ce | cn <- constsRel<0>, size(constsRel[cn]) == 1, ce:scalar(sv) := getOneFrom(constsRel[cn]), encapsed(_) !:= sv );

	// Do the same as the above, but for class constants, not standard constants.
	rel[str,str,Expr] classConstsRel = { <cln,cn,ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], classConstSig([class(cln),const(cn)],ce) <- items };
	map[str,map[str,Expr]] classConstsInScript = ( cln : ( cn : ce | cn <- classConstsRel[cln]<0>, size(classConstsRel[cln,cn]) == 1, ce:scalar(sv) := getOneFrom(classConstsRel[cln,cn]) ) | cln <- classConstsRel<0>, encapsed(_) !:= sv);

	// Replace constants and class constants with their defining values where possible
	scr = visit(scr) {
		case c:fetchClassConst(name(name(cln)), cn) : {
			if (cln in classConstMap && cn in classConstMap[cln]) {
				insert(classConstMap[cln][cn][@at=c@at]);
			} else if (cln in classConstsInScript && cn in classConstsInScript[cln]) {
				insert(classConstsInScript[cln][cn][@at=c@at]);
			}
		}
		
		case c:fetchConst(name(s)) : {
			if (s in constMap) {
				insert(constMap[s][@at=c@at]);
			} else if (s in constsInScript) {
				insert(constsInScript[s][@at=c@at]);
			}
		}
	}
	return scr;
}