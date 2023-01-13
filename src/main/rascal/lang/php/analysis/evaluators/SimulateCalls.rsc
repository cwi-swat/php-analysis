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

private set[str] simulatedFunctions = { "dirname", "MWInit", "strrchr", "substr" };

@doc{Evaluate the PHP dirname function, given a string literal argument.}
public Expr simulateCall(Expr e) {
	if (Expr c:call(name(name("dirname")),[actualParameter(scalar(string(s1)),false,false)]) := e) {
		try {
			// NOTE: This assumes that we use "/" as the directory separator. If this
			// code is Windows-specific, it could be "\" as well.
			// TODO: Parameterize this. It could be as simple as adding something into
			// the configuration, we don't want to litter the code with sep info.
			if (trim(s1) == "/") return scalar(string("/"))[@at=c@at];
			if (contains(s1, "/")) {
				parts = split("/", s1);
				dirpart = intercalate("/",take(size(parts)-1, parts));
				return scalar(string(dirpart))[@at=c@at];
			} else {
				return scalar(string("."))[@at=c@at];
			}
		} catch : {
			; // do nothing, we just don't make any changes
		}
	} else if (Expr c:staticCall(name(name("MWInit")), name(name("compiledPath")), [actualParameter(scalar(string(s1)),false,false)]) := e) {
		return scalar(string(s1))[@at=c@at];
	} else if (Expr c:staticCall(name(name("MWInit")), name(name("interpretedPath")), [actualParameter(scalar(string(s1)),false,false)]) := e) {
		return scalar(string(s1))[@at=c@at];
	} else if (Expr c:call(name(name("strrchr")),[actualParameter(scalar(string(s1)),false,false), actualParameter(scalar(string(s2)),false,false)]) := e) {
		if (size(s2) >= 1) {
			if (size(s2) > 1) s2 = s2[0];
			pos = findLast(s1,s2);
			if (pos == -1)
				return fetchConst(name("false"))[@at=c@at];
			else
				return scalar(string(substring(s1,pos)))[@at=c@at];
		}
	} else if (Expr c:call(name(name("substr")),[actualParameter(scalar(string(s1)),false,false), actualParameter(scalar(integer(i1)),false,false)]) := e) {
		if (size(s1) > 0) {
			if (i1 >= 0) {
				if (i1 <= (size(s1)-1)) {
					return scalar(string(substring(s1, i1)))[@at=c@at];
				} 
			}
		}
	} else if (Expr c:call(name(name("substr")),[actualParameter(scalar(string(s1)),false,false), actualParameter(scalar(integer(i1)),false,false), actualParameter(scalar(integer(i2)),false,false)]) := e) {
		if (size(s1) > 0) {
			if (i1 >= 0) {
				if (i1 <= (size(s1)-1)) {
					if (i2 >= 1) {
						s2 = substring(s1,i1);
						if (size(s2) < i2)
							return scalar(string(s2))[@at=c@at];
						else
							return scalar(string(substring(s2, 0,i2)))[@at=c@at];
					}
				} 
			}
		}
	} else if (Expr c:call(name(name("sprintf")),[actualParameter(scalar(string(s1)),false,false), ps*]) := e) {
		markers = findAll(s1,"%");
		doReplacement = [ false | i <- markers ];
		for (i <- index(markers), size(s1) >= (markers[i]+1), s1[markers[i]+1] == "s", size(ps) >= i, scalar(string(_)) := ps[i].expr) {
			doReplacement[i] = true;		
		}
		
		doReplacement = reverse(doReplacement);
		markers = reverse(markers);
		
		for (i <- index(markers), doReplacement[i], scalar(string(rs)) := ps[i].expr) {
			s1 = s1[..markers[i]] + rs + s1[markers[i]+2..];
		}
		
		doReplacement = [false] + reverse(doReplacement);
		toRemove = reverse([ i | i <- index(doReplacement), doReplacement[i] ]);
		for (i <- toRemove) c.parameters = remove(c.parameters,i);
		
		c.parameters[0].expr.scalarVal.strVal = s1;
		
		if (size(findAll(s1,"%")) == 0) {
			return scalar(string(s1))[@at=c@at];
		}
		return c;
	}

	return e;
}

public Script simulateCalls(Script scr) {
	return bottom-up visit(scr) {
		case c:call(name(name(s)),ps) : {
			if (s in simulatedFunctions) {
				newcall = simulateCall(c);
				if (c != newcall) insert(newcall);
			}
		}
	}
}

public Expr simulateCalls(Expr expr) {
	return bottom-up visit(expr) {
		case c:call(name(name(s)),ps) : {
			if (s in simulatedFunctions) {
				newcall = simulateCall(c);
				if (c != newcall) insert(newcall);
			}
		}
	}
}
