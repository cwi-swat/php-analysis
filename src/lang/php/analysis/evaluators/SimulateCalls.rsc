@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::SimulateCalls

import lang::php::ast::AbstractSyntax;
import Set;
import List;
import String;
import Exception;

@doc{Evaluate the PHP dirname function, given a string literal argument.}
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

private map[str fname, Script(Script) fhandler] handlers =
	( "dirname" : evalDirname );
	
public Script simulateCalls(Script scr) {
	solve(scr) {
		for (f <- handlers) {
			scr = handlers[f](scr);
		}
	}
	
	return scr;
}

