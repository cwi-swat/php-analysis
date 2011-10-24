@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::CallGraph

import lang::php::analysis::CFG;
import lang::php::analysis::Split;
import Set;
import IO;

public anno rel[Owner,str] node@callee;

public ScriptAsCFGs addCallGraphInfo(ScriptAsCFGs cfgs) {
	println("Adding call annotations to invoke nodes");
	ScriptAsCFGs res = { };
	for (<o,s,c> <- cfgs) {
		c = visit(c) {
			case i:invoke(target(), method_name(mn), actuals(al)) : 
				if (mn in cfgs[globalOwns()]<0>) 
					insert(i[@callee={<globalOwns(),mn>}]);
			
			case i:invoke(target(t), method_name(mn), actuals(al)) :
				if (!isEmpty({ mn | <classOwns(_),mn,_> <- cfgs }))  
					insert(i[@callee={<oi,mn> | <oi,mn,_> <- cfgs, classOwns(_) := oi}]);
		};
		res = res + < o,s,c >;	
	}
	return res;
}

public SplitScript addCallGraphInfo(SplitScript scrs) {
	println("Adding call annotations to invoke nodes");
	SplitScript res = { };
	for (<o,s,c> <- scrs) {
		c = visit(c) {
			case i:invoke(target(), method_name(mn), actuals(al)) : 
				if (mn in scrs[globalOwns()]<0>) 
					insert(i[@callee={<globalOwns(),mn>}]);
			
			case i:invoke(target(t), method_name(mn), actuals(al)) :
				if (!isEmpty({ mn | <classOwns(_),mn,_> <- scrs }))  
					insert(i[@callee={<oi,mn> | <oi,mn,_> <- scrs, classOwns(_) := oi}]);
		};
		res = res + < o,s,c >;	
	}
	return res;
}