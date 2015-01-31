@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::dataflow::SimpleStringDefs

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::NamePaths;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import analysis::graphs::Graph;
import lang::php::analysis::cfg::BuildCFG;

public Script evalStringVars(Script scr) {
	cfgs = buildCFGs(scr);
	return scr;
}

public set[NamePath] kills(Expr e) {
	return { };
}