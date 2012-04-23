@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::IncludeCP

import lang::php::ast::AbstractSyntax;
import Expression;

data RuntimeException = CannotEval(Expr expr);

anno int Expr@includeId;

@doc{Perform light-weight constant propagation and evaluation to attempt to resolve any
     expressions used in includes.}
public Script resolveIncludes(Script scr) {
	int incId = 0;
	int nextIncId() { incId += 1; return incId; }
	
	// Step 1: give each include a numeric id; this way, once we transform it, we know where
	// to put the new version.
	scr = visit(scr) { case i:include(_,_) => i[@includeId = nextIncId()] };
	
	// Step 2: gather them all so we can process them, figure out dependencies
	list[Expr] includes = [ i | /i:include(_,_) := scr ];
	
	// Step 3: get rid of all the includes that use literals, we don't need to change
	// those, they are already in the form we prefer
	includes = [ i | i <- includes, include(scalar(string(_)),_) !:= i ];
	
	// Step 4: try to evaluate the include; this will take care of simple cases that
	// just append a literal to the directory constant (for instance)
	list[Expr] evaluated = [ ];
	list[Expr] unevaluated = [ ];
	for (i <- includes) {
		try {
			e = evaluateLiterals(i);
			evaluated += e;
		} catch CannotEval(_) : {
			unevaluated += i;
		}
	} 
}

