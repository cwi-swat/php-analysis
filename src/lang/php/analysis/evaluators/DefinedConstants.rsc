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
import lang::php::analysis::syntactic::Constants;

import Set;
import List;
import String;
import Exception;
import Map;

@doc{Evaluate any constants, replacing them with their assigned value in cases where this assigned value
     is itself a literal.}
public Script evalConsts(Script scr, map[str, Expr] constMap, set[loc] reachable, map[loc,Signature] sigs) {
	reachableSigs = domainR(sigs, reachable);

	rel[str,Expr] constsRel = { <cn,ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], constSig(cn,ce) <- items };
	map[str,Expr] constsInScript = ( cn : ce | cn <- constsRel<0>, size(constsRel[cn]) == 1, ce:scalar(sv) := getOneFrom(constsRel[cn]) );

	rel[str,str,Expr] classConstsRel = { <cln,cn,ce> | l <- reachableSigs, fileSignature(_,items) := reachableSigs[l], classConstSig(cln,cn,ce) <- items };
	map[str,map[str,Expr]] classConstsInScript = ( cln : ( cn : ce | cn <- classConstsRel[cln]<0>, size(classConstsRel[cln,cn]) == 1, ce:scalar(sv) := getOneFrom(classConstsRel[cln,cn]) ) | cln <- classConstsRel<0> );

	scr = visit(scr) {
		case c:fetchClassConst(name(name(cln)), cn) : {
			if (cln in classConstsInScript && cn in classConstsInScript[cln])
				insert(classConstsInScript[cln][cn][@at=c@at]);
		}
		
		case c:fetchConst(name(s)) : {
			if (s in constsInScript)
				insert(constsInScript[s][@at=c@at]);
			else if (s in constMap) 
				insert(constMap[s][@at=c@at]);
		}
	}
	return scr;
}