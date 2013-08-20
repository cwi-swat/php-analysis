module lang::php::analysis::callgraph::SimpleCG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::NamePaths;
import lang::php::analysis::signatures::Summaries;
import lang::php::analysis::signatures::Signatures;
import lang::php::util::System;

alias CallGraphMap = map[loc caller, set[Callee] callees];

data Callee
	= functionCallee(str functionName, loc definedAt)
	| methodCallee(str className, str methodName, loc definedAt)
	| unknownCallee(str functionOrMethodName)
	;

public CallGraphMap computeSystemCallGraph(System s) {
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
		for (fs:functionSig([global(),function(fname)], _) <- items) {
			functionCallees += < fname, functionCallee(fname, fs@at) >;
		}
		for (ms:methodSig([class(cname),method(mname)], _) <- items) {
			methodCallees += < mname, methodCallee(cname, mname, ms@at) >;
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
	
	// Now, create the map for the system from caller locations
	// to possible callees.
	CallGraphMap cgm = ( );
	for (l <- s) cgm += computeScriptCallGraph(s[l], functionCalleesMap, methodCalleesMap);
	
	return cgm;
}

public CallGraphMap computeScriptCallGraph(Script s, map[str functionName, set[Callee] callees] functionCalleesMap, map[str methodName, set[Callee] callees] methodCalleesMap) {
	CallGraphMap cgm = ( );
	set[Callee] allFunctions = { *fc | fc <- functionCalleesMap<1> };
	set[Callee] allMethods = { *mc | mc <- methodCalleesMap<1> };
	
	visit(s) {
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
						cgm[c@at] = functionCalleesMap[fn]; 
					} else {
						cgm[c@at] = { unknownCallee(fn) };
					}
				} else {
					cgm[c@at] = allFunctions;
				}
			} else if (fn in functionCalleesMap) {
				cgm[c@at] = functionCalleesMap[fn]; 
			} else {
				cgm[c@at] = { unknownCallee(fn) };
			}
		}

		case mc:methodCall(_,name(name(mn)),_) : {
			if (mn in methodCalleesMap) {
				cgm[mc@at] = methodCalleesMap[mn];
			} else {
				cgm[mc@at] = { unknownCallee(mn) };
			}
		}

		case sc:staticCall(name(name(cn)),name(name(mn)),_) : {
			if (mn in methodCalleesMap && {_*,mc:methodCallee(cn,mn,_)} := methodCalleesMap[mn]) {
				cgm[sc@at] = { mc };
			} else {
				cgm[sc@at] = { unknownCallee("<cn>::<mn>") };
			}
		}

		case sc:staticCall(_,name(name(mn)),_) : {
			if (mn in methodCalleesMap) {
				// NOTE: To be more accurate, we should filter these to just be static methods.
				cgm[sc@at] = methodCalleesMap[mn];
			} else {
				cgm[sc@at] = { unknownCallee("?::<mn>") };
			}
		}
		
		case c:call(_,_) : {
			cgm[c@at] = allFunctions;
		}

		case mc:methodCall(_,_,_) : {
			cgm[mc@at] = allMethods;
		}

		case sc:staticMethodCall(_,_,_) : {
			// NOTE: To be more accurate, we should filter these to just be static methods.
			cgm[sc@at] = allMethods;
		}
	}
	
	return cgm;
}