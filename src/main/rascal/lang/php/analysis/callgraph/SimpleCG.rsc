@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::callgraph::SimpleCG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::signatures::Summaries;
import lang::php::analysis::signatures::Signatures;
import lang::php::ast::System;

data CallTarget
	= functionTarget(str functionName, loc definedAt)
	| methodTarget(str className, str methodName, loc definedAt)
	| unknownTarget(str functionOrMethodName)
	;

alias CallGraph = rel[loc callSource, CallTarget callTarget];
alias InvertedCallGraph = rel[CallTarget callTarget, loc callSource];

public CallGraph computeSystemCallGraph(System s) {
	CallGraph res = { };

	// First, get back all the library functions and methods so we can add
	// nodes in the call graph for those that are (or may be) used
	fsum = loadFunctionSummaries();
	msum = loadMethodSummaries();
	
	// Second, generate signatures for each of the scripts, so we know
	// what functions and methods are available
	map[loc,Signature] sysSignatures = ( l : getFileSignature(l,s.files[l]) | l <- s.files );
	
	// Third, change these into a specific format that is easier to match against
	rel[str functionName, CallTarget callTargets] functionTargets = { };
	rel[str methodName, CallTarget callTargets] methodTargets = { };
	for (fileSignature(_, items) <- sysSignatures<1>) {
		for (fs <- items, fs is functionSig) {
			functionTargets += < fs.namepath.file, functionTarget(fs.namepath.file, fs.at) >;
		}
		for (ms <- items, ms is methodSig) {
			methodTargets += < ms.namepath.file, methodTarget(ms.namepath.parent.file, ms.namepath.file, ms.at) >;
		}
	}
		 
	// Fourth, turn these into maps, which are faster
	map[str functionName, set[CallTarget] callTargets] functionTargetsMap = ( );
	map[str methodName, set[CallTarget] callTargets] methodTargetsMap = ( );
	
	for (<fn,c> <- functionTargets) {
		if (fn in functionTargetsMap)
			functionTargetsMap[fn] = functionTargetsMap[fn] + c;
		else
			functionTargetsMap[fn] = { c };
	}
	
	for (<mn,c> <- methodTargets) {
		if (mn in methodTargetsMap)
			methodTargetsMap[mn] = methodTargetsMap[mn] + c;
		else
			methodTargetsMap[mn] = { c };
	}
	
	// Now, compute the call graph
	res = { *computeScriptCallGraph(s.files[l], functionTargetsMap, methodTargetsMap) | l <- s.files };
	
	return res;
}

public CallGraph computeScriptCallGraph(Script s, map[str functionName, set[CallTarget] callTargets] functionTargetsMap, map[str methodName, set[CallTarget] callTargets] methodTargetsMap) {
	set[CallTarget] allFunctions = { *fc | fc <- functionTargetsMap<1> };
	set[CallTarget] allMethods = { *mc | mc <- methodTargetsMap<1> };
	
	CallGraph res = { };
	
	s = visit(s) {
		case c:call(name(name(fn)),ps) : {
			if (fn in {"call_user_func","call_user_func_array"}) {
				// If we have a call_user_func or call_user_func_array, check for a special
				// case where the function name is given explicitly. We ignore the other
				// explicit cases here (for method calls), but TODO: these should be added.
				// If we have the function name, we treat this as a normal function call to
				// that function, else we treat it as a call to potentially any function in
				// the system. NOTE: We don't create an edge to either call_user_func or
				// call_user_func_array, even though we could create those edges as well.
				if ([actualParameter(scalar(string(_)),_,_,_)] := ps) {
					if (fn in functionTargetsMap) {
						res = res + ( { c.at } join functionTargetsMap[fn] ); 
					} else {
						res = res + < c.at, unknownTarget(fn) >;
					}
				} else {
					res = res + ( { c.at} join allFunctions );
				}
			} else if (fn in functionTargetsMap) {
				res = res + ( { c.at } join functionTargetsMap[fn] );
			} else {
				res = res + < c.at, unknownTarget(fn) >;
			}
		}

		case mc:methodCall(_,name(name(mn)),_,_) : {
			if (mn in methodTargetsMap) {
				res = res + ( { mc.at } join methodTargetsMap[mn] );
			} else {
				res = res + < mc.at, unknownTarget(mn) >;
			}
		}

		case sc:staticCall(name(name(cn)),name(name(mn)),_) : {
			if (mn in methodTargetsMap && {*_,mc:methodTarget(cn,mn,_)} := methodTargetsMap[mn]) {
				res = res + < sc.at, mc >;
			} else {
				res = res + < sc.at, unknownTarget("<cn>::<mn>") >;
			}
		}

		case sc:staticCall(_,name(name(mn)),_) : {
			if (mn in methodTargetsMap) {
				// NOTE: To be more accurate, we should filter these to just be static methods.
				res = res + ( { sc.at } join methodTargetsMap[mn] );
			} else {
				res = res + < sc.at, unknownTarget("?::<mn>") >;
			}
		}
		
		case c:call(_,_) : {
			res = res + ( { c.at} join allFunctions );
		}

		case mc:methodCall(_,_,_,_) : {
			res = res + ( { mc.at} join allMethods );
		}
	}
	
	return res;
}