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

public Script evalStrrchr(Script scr) {
	scr = visit(scr) {
		case c:call(name(name("strrchr")),[actualParameter(scalar(string(s1)),false), actualParameter(scalar(string(s2)),false)]) : {
			if (size(s2) >= 1) {
				if (size(s2) > 1) s2 = s2[0];
				pos = findLast(s1,s2);
				if (pos == -1)
					insert(scalar(boolean(false)));
				else
					insert(scalar(string(substring(s1,pos))));
			}
		}
	}
	return scr;
}

// TODO: Handle the negative case for i1, which starts from the end
public Script evalSubstr(Script scr) {
	scr = visit(scr) {
		case c:call(name(name("substr")),[actualParameter(scalar(string(s1)),false), actualParameter(scalar(integer(i1)),false)]) : {
			if (size(s1) > 0) {
				if (i1 >= 0) {
					if (i1 <= (size(s1)-1)) {
						insert(scalar(string(substring(s1, i1))));
					} 
				}
			}
		} 

		case c:call(name(name("substr")),[actualParameter(scalar(string(s1)),false), actualParameter(scalar(integer(i1)),false), actualParameter(scalar(integer(i2)),false)]) : {
			if (size(s1) > 0) {
				if (i1 >= 0) {
					if (i1 <= (size(s1)-1)) {
						if (i2 >= 1) {
							s2 = substring(s1,i1);
							if (size(s2) < i2)
								insert(scalar(string(s2)));
							else
								insert(scalar(string(substring(s2, 0,i2))));
						}
					} 
				}
			}
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

