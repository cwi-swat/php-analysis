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

public System resolve(System sys, loc baseLoc) {
	sys = inlineMagicConstants(sys, baseLoc);
	igraph = extractIncludeGraph(sys, baseLoc.path);
	cinfo = getConstInfo(sys);
	
	set[IncludeGraphNode] dirtyNodes = igraph.nodes;
	igTrans = (collapseToNodeGraph(igraph))*;
	igInverted = invert(igTrans);
	map[IncludeGraphNode,set[IncludeGraphNode]] reachable = ( n : igTrans[n] | n <- igraph.nodes );
	map[IncludeGraphNode,set[IncludeGraphNode]] impacts = ( n : igInverted[n] | n <- igraph.nodes );

	while (!isEmpty(dirtyNodes)) {
		n = getOneFrom(dirtyNodes);
		nChanged = evalConsts(sys[l],constMap,classConstMap,reachable,sigs);		
	}
}
