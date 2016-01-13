@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::ScriptResolve

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::LocUtils;
import lang::php::ast::System;
import lang::php::analysis::includes::IncludesInfo;
import lang::php::analysis::includes::MatchIncludes;
import lang::php::analysis::includes::QuickResolve;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::analysis::evaluators::DefinedConstants;
import lang::php::analysis::includes::NormalizeConstCase;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;

import Set;
import Relation;
import String;
import DateTime;
import Map;

private map[loc,set[loc]] reachableCache = ( );

private set[loc] reachable(IncludeGraph igraph, loc l) {
	if (l in reachableCache) return reachableCache[l];
	set[loc] res = { l };
	solve(res) {
		for (e <- igraph.edges, e.source.fileLoc in res) {
			if (e.target is unknownNode) {
				reachableCache[l] = igraph.nodes<0>;
				return reachableCache[l];
			}
			res += getEdgeTargets(igraph,e);
		}		
	}
	reachableCache[l] = res;
	return res;
}

private Expr replaceConstants(Expr e, IncludesInfo iinfo) {
	return bottom-up visit(e) {
		case fc:fetchConst(name(cn)) => (iinfo.constMap[cn])[@at=fc@at]
			when cn in iinfo.constMap
			
		case fcc:fetchClassConst(name(name(cln)),str cn) => (iinfo.classConstMap[cln][cn])[@at=fcc@at]
			when cln in iinfo.classConstMap && cn in iinfo.classConstMap[cln]
	}
}

anno set[ConstItem] IncludeGraphNode@definedConstants;
anno map[ConstItem,Expr] IncludeGraphNode@definingExps;
anno bool IncludeGraphNode@setsIncludePath;

public IncludeGraphNode decorateNode(IncludeGraphNode n, map[loc,set[ConstItemExp]] loc2consts, bool setsip) {
	if (n.fileLoc notin loc2consts) {
		return n[@definedConstants={}][@definingExps=()][@setsIncludePath=false];
	} else {
		constDefs = loc2consts[n.fileLoc];
		justDefs = { normalConst(cn) | normalConst(cn,_) <- constDefs } + { classConst(cln,cn) | classConst(cln,cn,_) <- constDefs };
		exprs = ( normalConst(cn) : cne | normalConst(cn,cne) <- constDefs ) + ( classConst(cln,cn) : cne | classConst(cln,cn,cne) <- constDefs );
		return n[@definedConstants=justDefs][@definingExps=exprs][@setsIncludePath=setsip];	
	}
}

public tuple[rel[loc,loc] resolved, lrel[str,datetime] timings] scriptResolve(System sys, str p, str v, loc toResolve, loc baseLoc, set[loc] libs = { }, list[str] ipath=[], map[loc,rel[loc,Expr,loc]] quickResolveInfo = ( )) {
	lrel[str,datetime] timings = [ < "Starting includes resolution", now() > ];
	clearLookupCache();
	
	// First find all the includes in the script. If we don't have any, we are already done.
	includeMap = ( i@at : i | /i:include(_,_) := sys.files[toResolve] );
	timings += < "Starting number of includes:<size(includeMap)>", now() >;
	if (size(includeMap) == 0) return < {}, timings >;
		
	// Next run the quick includes over the current script. This will fully
	// resolve some of the includes, partially resolve some others (maybe),
	// and perform simplifications
	IncludesInfo iinfo = loadIncludesInfo(p, v);
	timings += < "Includes info loaded", now()>;
	quickResolved = (size(quickResolveInfo) > 0) ? ( (toResolve in quickResolveInfo) ? quickResolveInfo[toResolve] : { }) : quickResolveExpr(sys, iinfo, toResolve, baseLoc, libs=libs);
	timings += < "Finished with initial quick resolve", now()>;
	
	// This gives us a base model of what can be immediately included
	// into this script. Now we work out from here, figuring out
	// what could be included in each of these, etc. Note: we don't
	// try to narrow this down at this point, since it often depends
	// on the reachability relation, which realistically we need to
	// gradually narrow.
	set[loc] worked = { toResolve } + { qri | qri <- quickResolved<2>, qri.scheme == "php+lib" };
	set[loc] worklist = { qri | qri <- quickResolved<2>, qri.scheme != "php+lib" } - worked;
	while (! isEmpty(worklist) ) {
		next = getOneFrom(worklist); worklist -= next; worked += next;
		includeMap += ( i@at : i | /i:include(_,_) := sys.files[next] );
		nextResolved = (size(quickResolveInfo) > 0) ? ( (next in quickResolveInfo) ? quickResolveInfo[next] : { } ) : quickResolveExpr(sys, iinfo, next, baseLoc, libs=libs);
		quickResolved += nextResolved;
		worklist += ({ qri | qri <- nextResolved<2>, qri.scheme != "php+lib" } - worked);
		worked += { qri | qri <- nextResolved<2>, qri.scheme == "php+lib" };
	} 
	timings += < "Finished with initial reachability model", now()>;

	// Now we have enough information to build an initial version of the includes
	// graph starting from the current script. We add a node for each script and
	// edges based on the quickResolved relation. The type of edge is based on
	// how many edges exist from the source to the target node.
	// NOTE: We assume here that we know which libraries exist. If we don't
	// make this assumption, we would have to assume, for every included
	// file that hits the library path, that other files could be included
	// as well. Essentially we are enforcing a "closed world" assumption,
	// assuming we are examining the entire system that will be run.
	timings += < "Building includes graph based on model", now()>;
	int sizeToRemove = size(baseLoc.path);
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode((l.scheme != "php+lib") ? substring(l.path,sizeToRemove) : l.path,l) | l <- worked );// + (|file:///synthesizedLoc/<lib.path>| : libNode(lib.name,lib.path) | lib <- libraries);	
	set[IncludeGraphEdge] edgeSet = { };
	for (l <- includeMap) {
		possibleTargets = (l in quickResolved) ? quickResolved[l] : { };
		if (size(possibleTargets) == 0) {
			// This means that no possible files could be included.
			edgeSet += igEdge(nodeMap[l.top], unknownNode(), includeMap[l]); // TODO: Should use resolved version, just for completeness	
		} else if (size(possibleTargets) == 1 && < ie,tn > := getOneFrom(possibleTargets)) {
			// This means we have exactly one file included, so we consider this to be resolved.
			edgeSet += igEdge(nodeMap[l.top], nodeMap[tn], ie);
		} else if (size(possibleTargets) >= size(sys.files<0>)) {
			// This means that every possible file could be included. TODO: Alter this to better represent
			// the result of using libraries.
			edgeSet += igEdge(nodeMap[l.top], anyNode(), getOneFrom(possibleTargets<0>));
		} else {
			// This last condition means we have a partial match, which could reference multiple
			// possible include files.
			edgeSet += igEdge(nodeMap[l.top], multiNode({nodeMap[tn] | tn <- possibleTargets<1>}), getOneFrom(possibleTargets<0>));
		}
	}
	igraph = igGraph(nodeMap, edgeSet);
	timings += < "Graph construction complete, <size(edgeSet)> edges, <size({e | e <- igraph.edges, e.target is igNode})> resolved, <size({e | e <- igraph.edges, e.target is multiNode})> multi, <size({e | e <- igraph.edges, e.target is anyNode})> any, <size({e | e <- igraph.edges, e.target is unknownNode})> unknown", now()>;

	// Determine which files in the system may set the include path. This is any file that either a) calls set_include_path directly, or
	// b) calls ini_set and either sets the include path OR sets something given in a variable (not a common occurrence). NOTE: there
	// could be a dynamic call to these functions, using variable functions or dynamic invocations, that is not detected here. This
	// could happen, but seemingly would be done with the intent to obfuscate the changing of the path. TODO: it would be good to do
	// a string analysis to rule this out, though, if possible.	
	set[loc] setsIncludePath = { l | l <- worked, l.scheme != "php+lib", /call(name(name("set_include_path")),_) := sys.files[l] } +
							   { l | l <- worked, l.scheme != "php+lib", /call(name(name("chdir")),_) := sys.files[l] } + 
							   { l | l <- worked, l.scheme != "php+lib", /call(name(name("ini_set")),[actualParameter(pe,_)]) := sys.files[l], (scalar(string("include_path")) := pe || scalar(string(_)) !:= pe) };
	timings += < "Found <size(setsIncludePath)> locations that set the include path", now() >;

	// Decorate the nodes in the include graph with info on constants and behaviors.
	igraph.nodes = ( l : decorateNode(igraph.nodes[l], iinfo.loc2consts, l in setsIncludePath) | l <- igraph.nodes, igraph.nodes[l] is igNode );
	timings += < "Decorating nodes with constant definition information", now() >;
	
	// Grab the starting constrel from the includes info; this includes all the constants in the system,
	// with expressions normalized but no constants (except magic constants) replaced
	constrel = iinfo.constRel;
	
	// This function attempts to resolve the constants used in an expression. Globally unique constants
	// are just replaced with defining values (if they are scalars), while otherwise we look to see
	// what constants are actually reachable from the current location, based on the includes graph.
	Expr resolveConstExpr(Expr resolveExpr, loc constLoc) {
		// Get the constants used inside resolveExpr
		usedConstants = { normalConst(cn) | /fetchConst(name(cn)) := resolveExpr } +
						{ classConst(cln,cn) | /fetchClassConst(name(name(cln)),str cn) := resolveExpr };

		// Find any of these that are uniquely defined (e.g., defined once or always defined as the
		// same literal expression)
		map[ConstItem,Expr] solvedConstants = ( );
		for (ci:normalConst(cn) <- usedConstants, cn in iinfo.constMap)
			solvedConstants[ci] = iinfo.constMap[cn];
		for(ci:classConst(cln,cn) <- usedConstants, cln in iinfo.classConstMap, cn in iinfo.classConstMap[cln])
			solvedConstants[ci] = iinfo.classConstMap[cln][cn];

		// For the rest, use the includes graph to find any constant definitions reachable
		// from this current location -- since the relation is an over-approximation of
		// reality, this may include defs that are not reachable, but will not miss any that
		// are (givin the stipulation about libraries). If we have one defining expression
		// that is a non-encapsed scalar we use that, else we attempt to use this same process
		// to solve any constants in this expression.
		for (ci <- usedConstants, ci notin solvedConstants) {
			cirel = constrel[ci];
			reachableConstLocs = reachable(igraph,constLoc) & cirel<0>;
			definingExps = { < rl, rle > | rl <- reachableConstLocs, rle <- cirel[rl] };
			if (size(definingExps<1>) == 1 && rle:scalar(sv) := getOneFrom(definingExps<1>), encapsed(_) !:= sv) {
				solvedConstants[ci] = rle; 
			} else {
				// With poorly written code we could have circular dependencies on constant
				// values, so TODO: Add a check to break circular dependencies
				resolvedExprs = { < rl, resolveConstants(ci, rle, rl) > | rl <- reachableConstLocs, rle <- cirel[rl] };
				
				// Now check again to see if it was solved; if it isn't at this point, we assume we cannot
				// resolve it yet.
				if (size(resolvedExprs<1>) == 1 && rle:scalar(sv) := getOneFrom(resolvedExprs<1>), encapsed(_) !:= sv) {
					solvedConstants[ci] = rle;
				} 
			}
		}
		
		// Use any of the constants we have already resolved, replacing them in the resolvedExpr with
		// their actual values. 
		resolvedExpr = bottom-up visit(resolveExpr) {
			case fetchConst(name(cn)) => solvedConstants[normalConst(cn)] when normalConst(cn) in solvedConstants
			
			case fetchClassConst(name(name(cln)),str cn) => solvedConstants[classConst(cln,cn)] when classConst(cln,cn) in solvedConstants
		}
		
		// Finally, perform our standard simplifications on the expression, performing
		// concatenations, etc.
		resolvedExpr = normalizeExpr(resolvedExpr, baseLoc);
		return resolvedExpr;
	}						 			
	
	
	// This function also attempts to resolve the constants used in an expression. However,
	// we also include logic specifically for expressions that are used to define constants,
	// using the resolved expression to replace the defining expression in the constrel.
	Expr resolveConstants(ConstItem toResolve, Expr resolveExpr, loc constLoc) {
		resolvedExpr = resolveConstExpr(resolveExpr, constLoc);
						
		if (resolveExpr != resolvedExpr) {
			constrel = constrel - < toResolve, constLoc, resolveExpr > + < toResolve, constLoc, resolvedExpr >;
		}
		return resolvedExpr;
	}

	// Find any unsolved edges, defined as edges that do not target a standard include graph node.
	unsolvedEdges = { e | e <- igraph.edges, !(e.target is igNode) };
	
	// Build a model of the files in the site; we may want to cache this...
	Branch site = buildSiteTree(baseLoc);
	
	// This is our loop flag: it will be true as long as there are unsolved edges AND we
	// make progress on trying to solve them.
	bool continueTrying = ( size(unsolvedEdges) > 0 );
	while(continueTrying) {
		timings += < "Attempting to solve remaining edges, <size(unsolvedEdges)> left", now() >;
		originalUnsolved = unsolvedEdges;
		reachableCache = ( );

		// First, try to resolve the include expressions in all the edges
		basicMatched = { e[includeExpr=resolveConstExpr(e.includeExpr,e.source.fileLoc)] | e <- unsolvedEdges };
		solvingEdges = { };
		
		// Second, if we could resolve any of them, try to match the result to a file or files (even if we can't
		// resolve to a specific file, maybe we can winnow the choices down). This first part, with the call to
		// calculateLoc, will do the single file match, while matchIncludes below will possibly return
		// multiple matches.
		for (e <- basicMatched) {
			if (iexp:include(scalar(string(sp)),_) := e.includeExpr) {
				try {
					iloc = calculateLoc(toResolve,baseLoc,sp,site,pathMayBeChanged=size(reachable(igraph,baseLoc) & setsIncludePath) > 0,ipath=ipath);
					solvingEdges = solvingEdges + e[target=igraph.nodes[iloc]];
				} catch UnavailableLoc(_) : {
					solvingEdges = solvingEdges + e;
				}
			} else {
				solvingEdges = solvingEdges + e;
			}
		}			
		
		igraph.edges = igraph.edges - unsolvedEdges + solvingEdges;
		
		igraph.edges = { (e.target is igNode) ? e : (matchIncludes(sys, igraph, e, size(reachable(igraph,e.source.fileLoc) & setsIncludePath) > 0, ipath)) | e <- igraph.edges };
		unsolvedEdges = { e | e <- igraph.edges, !(e.target is igNode) };
		timings += < "After constant resolution, unsolved edges remaining: <size(unsolvedEdges)>", now() >;
		
		continueTrying = (unsolvedEdges != originalUnsolved);
	}	
	
	finalResult = { < edge.includeExpr@at, et > | edge <- igraph.edges, et <- getEdgeTargets(igraph, edge) }; 
	return < finalResult, timings >;
}