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
	scr = visit(scr) {
		case c:call(name(name("dirname")),[actualParameter(scalar(string(s1)),false)]) : {
			try {
				// NOTE: This assumes that we use "/" as the directory separator. If this
				// code is Windows-specific, it could be "\" as well.
				// TODO: Parameterize this. It could be as simple as adding something into
				// the configuration, we don't want to litter the code with sep info.
				if (contains(s1, "/")) {
					parts = split("/", s1);
					dirpart = intercalate("/",take(size(parts)-1, parts));
					insert(scalar(string(dirpart))[@at=c@at]);
				} else {
					insert(scalar(string("."))[@at=c@at]);
				}
			} catch MalFormedURI(estr) : {
				; // do nothing, we just don't make any changes
			}
		}
	}
	return scr;
}

@doc{Evaluate the PHP dirname function, given a string literal argument.}
public Script evalMWStatics(Script scr) {
	scr = visit(scr) {
		case c:staticCall(name(name("MWInit")), name(name("compiledPath")), [actualParameter(scalar(string(s1)),false)]) : {
			insert(scalar(string(s1))[@at=c@at]);
		}

		case c:staticCall(name(name("MWInit")), name(name("interpretedPath")), [actualParameter(scalar(string(s1)),false)]) : {
			insert(scalar(string(s1))[@at=c@at]);
		}
	}
	return scr;
}
private map[str fname, Script(Script) fhandler] handlers =
	( "dirname" : evalDirname, "mwInit" : evalMWStatics );
	
public Script simulateCalls(Script scr) {
	solve(scr) {
		for (f <- handlers) {
			scr = handlers[f](scr);
		}
	}
	
	return scr;
}

