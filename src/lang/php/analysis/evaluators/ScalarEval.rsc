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
import lang::php::analysis::evaluators::MagicConstants;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import Set;
import List;
import String;
import Exception;

@doc{Perform all scalar evaluations above.}
public map[loc fileloc, Script scr] evalAllScalars(map[loc fileloc, Script scr] scripts) {
	solve(scripts) {
		scripts = ( l : algebraicSimplification(simulateCalls(inlineMagicConstants(scripts[l],l))) | l <- scripts );

		// This is in the solve because it can change on each iteration. This is all the constants that are
		// defined just once in the system. This is used as a "backup" to the more detailed analysis above,
		// since it could be that these constants are brought in with an include that itself has a non-literal
		// path (meaning the more detailed analysis won't find it).
		//
		// NOTE: This could give a wrong result, in the sense that we would have a constant that would actually,
		// at runtime, be an error, for instance if the programmer uses the constant without actually importing
		// the defining script.
		rel[str,Expr] constRel = { < cn, e > | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e:scalar(sv),false)]) := scripts<1> };
		map[str,Expr] constMap = ( s : e | <s,e> <- constRel, size(constRel[s]) == 1 ); 
		
		// Add in some predefined constants as well. These are from the Directories extension.
		// TODO: We should factor these out somehow.
		constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
		constMap["PATH_SEPARATOR"] = scalar(string(":"));
		constMap["SCANDIR_SORT_ASCENDING"] = scalar(integer(0));
		constMap["SCANDIR_SORT_DESCENDING"] = scalar(integer(0));
		constMap["SCANDIR_SORT_NONE"] = scalar(integer(1));

		scripts = ( l : evalConsts(scripts,l,constMap) | l <- scripts );
	}			
	return scripts;
}
