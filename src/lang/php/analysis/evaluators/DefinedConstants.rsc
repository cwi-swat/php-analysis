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
import Set;
import List;
import String;
import Exception;

import lang::php::analysis::syntactic::Constants;

@doc{Evaluate any constants, replacing them with their assigned value in cases where this assigned value
     is itself a literal.}
public Script evalConsts(map[loc fileloc, Script scr] scripts, loc l, map[str, Expr] constMap) {
	map[str,Expr] constsInScript = getConstants(scripts, l);
	Script scr = scripts[l];  
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