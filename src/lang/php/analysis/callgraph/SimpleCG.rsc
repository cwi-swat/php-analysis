module lang::php::analysis::callgraph::SimpleCG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::NamePaths;
import lang::php::analysis::signatures::Summaries;
import lang::php::analysis::signatures::Signatures;
import lang::php::ast::System;

data Callee
	= functionCallee(str functionName, loc definedAt)
	| methodCallee(str className, str methodName, loc definedAt)
	| unknownCallee(str functionOrMethodName)
	;

public anno set[Callee] Expr@callees;
 
public System computeSystemCallGraph(System s) {
	// First, get back all the library functions and methods so we can add
	// nodes in the call graph for those that are (or may be) used
	fsum = loadFunctionSummaries();
	msum = loadMethodSummaries();
	
	// Second, generate signatures for each of the scripts, so we know
	// what functions and methods are available
	map[loc,Signature] sysSignatures = ( l : getFileSignature(l,s[l]) | l <- s );
	
	// Third, change these into a specific format that is easier to match against
	rel[str functionName, Callee callees] functionCallees = { };
	rel[str methodName, Callee callees] methodCallees = { };
	for (fileSignature(fileloc, items) <- sysSignatures<1>) {
		for (fs:functionSig(path, _) <- items) {
			functionCallees += < path.file, functionCallee(path.file, fs@at) >;
		}
		for (ms:methodSig(path, _) <- items) {
			methodCallees += < path.file, methodCallee(path.parent.file, path.file, ms@at) >;
		}
	}
		 
	// Fourth, turn these into maps, which are faster
	map[str functionName, set[Callee] callees] functionCalleesMap = ( );
	map[str methodName, set[Callee] callees] methodCalleesMap = ( );
	
	for (<fn,c> <- functionCallees) {
		if (fn in functionCalleesMap)
			functionCalleesMap[fn] = functionCalleesMap[fn] + c;
		else
			functionCalleesMap[fn] = { c };
	}
	
	for (<mn,c> <- methodCallees) {
		if (mn in methodCalleesMap)
			methodCalleesMap[mn] = methodCalleesMap[mn] + c;
		else
			methodCalleesMap[mn] = { c };
	}
	
	// Now, annotate all calls with callee information
	s = ( l : computeScriptCallGraph(s[l], functionCalleesMap, methodCalleesMap) | l <- s );
	
	return s;
}

public Script computeScriptCallGraph(Script s, map[str functionName, set[Callee] callees] functionCalleesMap, map[str methodName, set[Callee] callees] methodCalleesMap) {
	set[Callee] allFunctions = { *fc | fc <- functionCalleesMap<1> };
	set[Callee] allMethods = { *mc | mc <- methodCalleesMap<1> };
	
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
				if ([scalar(string(fn2))] := ps) {
					if (fn in functionCalleesMap) {
						insert(c[@callees=functionCalleesMap[fn]]); 
					} else {
						insert(c[@callees={ unknownCallee(fn) }]);
					}
				} else {
					insert(c[@callees = allFunctions]);
				}
			} else if (fn in functionCalleesMap) {
				insert(c[@callees=functionCalleesMap[fn]]);
			} else {
				insert(c[@callees={ unknownCallee(fn) }]);
			}
		}

		case mc:methodCall(_,name(name(mn)),_) : {
			if (mn in methodCalleesMap) {
				insert(mc[@callees=methodCalleesMap[mn]]);
			} else {
				insert(mc[@callees={ unknownCallee(mn) }]);
			}
		}

		case sc:staticCall(name(name(cn)),name(name(mn)),_) : {
			if (mn in methodCalleesMap && {_*,mc:methodCallee(cn,mn,_)} := methodCalleesMap[mn]) {
				insert(sc[@callees={ mc }]);
			} else {
				insert(sc[@callees={ unknownCallee("<cn>::<mn>") }]);
			}
		}

		case sc:staticCall(_,name(name(mn)),_) : {
			if (mn in methodCalleesMap) {
				// NOTE: To be more accurate, we should filter these to just be static methods.
				insert(sc[@callees=methodCalleesMap[mn]]);
			} else {
				insert(sc[@callees={ unknownCallee("?::<mn>") }]);
			}
		}
		
		case c:call(_,_) : {
			insert(c[@callees=allFunctions]);
		}

		case mc:methodCall(_,_,_) : {
			insert(mc[@callees=allMethods]);
		}

		case sc:staticMethodCall(_,_,_) : {
			// NOTE: To be more accurate, we should filter these to just be static methods.
			insert(sc[@callees=allMethods]);
		}
	}
	
	return s;
}