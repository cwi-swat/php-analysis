@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::ResolveIncludes

import lang::php::analysis::evaluators::MagicConstants;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::analysis::includes::MatchIncludes;
import lang::php::analysis::includes::PropagateStringVars;
import lang::php::ast::AbstractSyntax;
import lang::php::util::System;
import lang::php::util::Corpus;
import lang::php::util::Utils;
import lang::php::stats::Stats;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::analysis::evaluators::DefinedConstants;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import lang::php::util::LocUtils;
import IO;
import Set;
import List;
import Map;
import String;
import DateTime;

public System resolveIncludes(System sys, loc baseLoc) {
	sys = inlineMagicConstants(sys, baseLoc);
	solve(sys) {
		sys = evalAllScalarsAndInlineUniques(sys, baseLoc);
		sys = matchIncludes(sys);
	}
	return sys;
}

public System resolveIncludesWithVars(System sys, loc baseLoc) {
	sys = inlineMagicConstants(sys, baseLoc);
	solve(sys) {
		solve(sys) {
			sys = matchIncludes(sys);
			sys = evalAllScalarsAndInlineUniques(sys, baseLoc);
		}
		sys = evalStringVars(sys);
	}	
	return sys;
}

alias IncludesInfo = tuple[System sysBefore, System sysAfter, lrel[loc,Expr] vpBefore, lrel[loc,Expr] vpAfter];

public map[str,IncludesInfo] resolveCorpusIncludes(Corpus corpus) {
	map[str,IncludesInfo] res = ( );
	for (product <- corpus) {
		sys = loadBinary(product,corpus[product]);
		vpIncludesInitial = gatherIncludesWithVarPaths(sys);
		resolved = resolveIncludes(sys, getCorpusItem(product,corpus[product]));
		vpIncludes = gatherIncludesWithVarPaths(resolved);
		res[product] = < sys, resolved, vpIncludesInitial, vpIncludes >;
	}
	return res;
}

//anno set[ConstItemExp] IncludeGraphNode@definedConstants;
anno set[ConstItem] IncludeGraphNode@definedConstants;
anno map[ConstItem,Expr] IncludeGraphNode@definingExps;

private set[str] caseInsensitiveConsts = { "TRUE", "FALSE", "NULL" };

public Expr normalizeConstCase(Expr e) {
	return bottom-up visit(e) {
		case fi:fetchConst(ni:name(s)) : {
			if (toUpperCase(s) in caseInsensitiveConsts)
				insert fi[name=ni[name=toUpperCase(s)]];
		}
	}
}

public IncludeGraphNode decorateNode(IncludeGraphNode n, map[loc,set[ConstItemExp]] loc2consts) {
	constDefs = loc2consts[n.fileLoc];
	justDefs = { normalConst(cn) | normalConst(cn,_) <- constDefs } + { classConst(cln,cn) | classConst(cln,cn,_) <- constDefs };
	exprs = ( normalConst(cn) : cne | normalConst(cn,cne) <- constDefs ) + ( classConst(cln,cn) : cne | classConst(cln,cn,cne) <- constDefs );
	return n[@definedConstants=justDefs][@definingExps=exprs];	
}

public tuple[IncludeGraph,lrel[str,datetime]] resolve(System sys, loc baseLoc) {
	lrel[str,datetime] timings = [ < "Starting includes resolution", now() > ];
	
	// Inlining magic constants requires context (e.g., the method the __METHOD__
	// appears in), so we need to do this step before extracting the graph
	timings += < "Total number of includes:<size([i|/i:include(_,_) := sys])>", now() >;
	timings += < "Initial number of dynamic includes: <size(gatherIncludesWithVarPaths(sys))>", now() >;
	sys = inlineMagicConstants(sys, baseLoc);
	
	timings += < "Extracting include graph", now() >;
	igraph = extractIncludeGraph(sys, baseLoc.path);

	timings += < "After inlining: <size({e | e <- igraph.edges, e.target is unknownNode})>", now()>;
	
	igraph.edges = { (e.target is igNode) ? e : (matchIncludes(sys, igraph, e)) | e <- igraph.edges };
	unsolvedEdges = { e | e <- igraph.edges, !(e.target is igNode) };
	timings += < "After initial matching: <size(unsolvedEdges)>", now() >;
	
	if (size(unsolvedEdges) > 0) {
		// Decorate the include graph with information on constants
		timings += < "Decorating nodes with constant definition information", now() >;
		map[loc,set[ConstItemExp]] loc2consts = ( l : { cdef[e=normalizeConstCase(algebraicSimplification(simulateCalls(cdef.e)))]  | cdef <- getScriptConstDefs(sys[l]) } | l <- sys);
		igraph.nodes = ( l : decorateNode(igraph.nodes[l],loc2consts) | l <- igraph.nodes );
		
		// Find uniquely defined constants; we require these to be defined with the same scalar expression,
		// since a constant defined in terms of another constant could differ depending on the include relation
		timings += < "Identifying uniquely defined constants", now() >;
		rel[ConstItem,loc,Expr] constrel = { < (classConst(cln,cn,ce) := ci) ? classConst(cln,cn) : normalConst(ci.constName), l, ci.e > | l <- loc2consts, ci <- loc2consts[l] };
	
		map[str, Expr] constMap = ( cn : ce | ci:normalConst(cn) <- constrel<0>, csub := constrel[ci,_], size(csub) == 1, ce:scalar(sv) := getOneFrom(csub), encapsed(_) !:= sv );  
		if ("DIRECTORY_SEPARATOR" notin constMap)
			constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
		if ("PATH_SEPARATOR" notin constMap)
			constMap["PATH_SEPARATOR"] = scalar(string(":"));
	
		map[str, map[str, Expr]] classConstMap = ( );
		for (ci:classConst(cln,cn) <- constrel<0>, csub := constrel[ci,_], size(csub) == 1, ce:scalar(sv) := getOneFrom(csub), encapsed(_) !:= sv) {
			if (cln in classConstMap) {
				classConstMap[cln][cn] = ce;
			} else {
				classConstMap[cln] = ( cn : ce );
			}
		}
	
		timings += <"Found <size(constMap)> unique constants and <(0 | it + size(classConstMap[cln]) | cln <- classConstMap )> unique class constants", now()>;
		
		bool continueTrying = ( size(unsolvedEdges) > 0 );
		while(continueTrying) {
			originalUnsolved = unsolvedEdges;
			timings += <"Building current transitive includes relation", now()>;
			rel[loc,loc] includesRel = 
				({ < e.source.fileLoc, e.target.fileLoc > | e <- igraph.edges, e.target is igNode} +
				{ < e.source.fileLoc, t.fileLoc > | e <- igraph.edges, e.target is multiNode, t <- e.target.alts } +
				{ < e.source.fileLoc,l> | e <- igraph.edges, e.target is unknownNode, l <- sys })*;
			timings += <"Done building transitive includes relation", now()>;

			rel[ConstItem,loc] workingList = { };

			Expr resolveConstExpr(Expr resolveExpr, loc constLoc) {
				// Get the constants used inside resolveExpr
				usedConstants = { normalConst(cn) | /fetchConst(name(cn)) := resolveExpr } +
								{ classConst(cln,cn) | /fetchClassConst(name(name(cln)),cn) := resolveExpr };

				map[ConstItem,Expr] solvedConstants = ( );
				for (ci:normalConst(cn) <- usedConstants, cn in constMap)
					solvedConstants[ci] = constMap[cn];
				for(ci:classConst(cln,cn) <- usedConstants, cln in classConstMap, cn in classConstMap[cln])
					solvedConstants[ci] = classConstMap[cln][cn];

				for (ci <- usedConstants, ci notin solvedConstants) {
					cirel = constrel[ci];
					reachableConstLocs = includesRel[constLoc] & cirel<0>;
					definingExps = { < rl, rle > | rl <- reachableConstLocs, rle <- cirel[rl] };
					if (size(definingExps<1>) == 1 && rle:scalar(sv) := getOneFrom(definingExps<1>), encapsed(_) !:= sv) {
						solvedConstants[ci] = rle; 
					} else {
						resolvedExprs = { < rl, resolveConstants(ci, rle, rl) > | rl <- reachableConstLocs, rle <- cirel[rl] }; 
					}
				}
				
				resolvedExpr = bottom-up visit(resolveExpr) {
					case fetchConst(name(cn)) => solvedConstants[normalConst(cn)] when normalConst(cn) in solvedConstants
					
					case fetchClassConst(name(name(cln)),cn) => solvedConstants[classConst(cln,cn)] when classConst(cln,cn) in solvedConstants
				}
				resolvedExpr = normalizeConstCase(algebraicSimplification(simulateCalls(resolvedExpr)));
				return resolvedExpr;
			}						 			

			Expr resolveConstants(ConstItem toResolve, Expr resolveExpr, loc constLoc) {
				if (<toResolve,constLoc> in workingList) return resolveExpr;
				workingList = workingList + <toResolve,constLoc>;

				resolvedExpr = resolveConstExpr(resolveExpr, constLoc);
								
				if (resolveExpr != resolvedExpr) {
					constrel = constrel - < toResolve, constLoc, resolveExpr > + < toResolve, constLoc, resolvedExpr >;
				}
				return resolvedExpr;
			}
				 		
			basicMatched = { e[includeExpr=resolveConstExpr(e.includeExpr,e.source.fileLoc)] | e <- unsolvedEdges };
			solvingEdges = { };
			for (e <- basicMatched) {
				if (iexp:include(scalar(string(sp)),_) := e.includeExpr) {
					try {
						iloc = calculateLoc(sys<0>,e.source.fileLoc,sp);
						solvingEdges = solvingEdges + e[targetNode=igraph.nodes[iloc]];
					} catch UnavailableLoc(_) : {
						solvingEdges = solvingEdges + e;
					}
				} else {
					solvingEdges = solvingEdges + e;
				}
			}			
			
			igraph.edges = igraph.edges - unsolvedEdges + solvingEdges;
			igraph.edges = { (e.target is igNode) ? e : (matchIncludes(sys, igraph, e)) | e <- igraph.edges };
			unsolvedEdges = { e | e <- igraph.edges, !(e.target is igNode) };
			timings += < "After constant resolution, unsolved edges remaining: <size(unsolvedEdges)>", now() >;
			
			continueTrying = (unsolvedEdges != originalUnsolved);
		}
	}

	return < igraph, timings >;
}
