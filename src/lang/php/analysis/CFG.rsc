@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::CFG

import Graph;
import lang::php::ast::AbstractSyntax;
import lang::php::ast::NamePath;

data CFGNode;
data CFGEdge;

data CFG = cfg(set[CFGNode] nodes, set[CFGEdge] edges);

alias CFGMap = map[NamePath,CFG];

public CFGMap createCFG(Script scr) {
	// First, pull out the things we create CFGs for. This includes all functions
	// and all top-level methods.
}