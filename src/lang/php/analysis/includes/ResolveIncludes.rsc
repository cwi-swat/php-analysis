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
import lang::php::ast::AbstractSyntax;
import lang::php::util::System;
import lang::php::util::Corpus;
import lang::php::util::Utils;
import lang::php::stats::Stats;

public System resolveIncludes(System sys, loc baseLoc) {
	sys = inlineMagicConstants(sys);
	sys = evalAllScalarsAndInlineUniques(sys, baseLoc);
	sys = matchIncludes(sys);
	return sys;
}

public map[str,tuple[System,System,lrel[loc,Expr]]] resolveCorpusIncludes(Corpus corpus) {
	map[str,tuple[System,System,lrel[loc,Expr]]] res = ( );
	for (product <- corpus) {
		sys = loadBinary(product,corpus[product]);
		resolved = resolveIncludes(sys, getCorpusItem(product,corpus[product]));
		vpIncludes = gatherIncludesWithVarPaths(resolved);
		res[product] = < sys, resolved, vpIncludes >;
	}
	return res;
}