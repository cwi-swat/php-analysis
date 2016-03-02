@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::IncludeCP

import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::stats::Stats;
import lang::php::ast::System;
import lang::php::util::Utils;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::includes::MatchIncludes;
import Exception;
import IO;
import List;
import String;
import Set;
import Relation;
import util::Math;

data RuntimeException = CannotEval(Expr expr);

anno int Expr@includeId;

public System resolveIncludes(System scripts) {
	println("Unresolved includes: <size(gatherIncludesWithVarPaths(scripts))>");
	println("Solving scalars");
	scripts2 = evalAllScalars(scripts);
	println("Unresolved includes: <size(gatherIncludesWithVarPaths(scripts2))>");
	println("Resolving includes on original using path pattern matching");
	scripts3 = matchIncludes(scripts);
	println("Unresolved includes: <size(gatherIncludesWithVarPaths(scripts3))>");
	println("Resolving includes using path pattern matching");
	scripts4 = matchIncludes(scripts2);
	println("Unresolved includes: <size(gatherIncludesWithVarPaths(scripts4))>");
	return scripts4;
}



public IncludeGraph computeGraph(System prod, loc l) {
	println("Solving scalars");
	prod2 = evalAllScalars(prod);
	println("Resolving includes using path pattern matching");
	prod3 = matchIncludes(prod2);
	println("Extracting include graph");
	return extractIncludeGraph(prod3,l.path);
}
