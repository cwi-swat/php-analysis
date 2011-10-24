@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::BasicBlocks

import lang::php::pp::PrettyPrinter;
import String;
import List;

data BasicBlock = BasicBlock(list[node] nodes); 

public str printBlock(BasicBlock bb) {
	return intercalate("\n",[prettyPrinter(bbi) | bbi <- bb.nodes]); 
}

public str printBlockAsNode(node n) {
	if (BasicBlock bb:BasicBlock(_) := n) return printBlock(bb);
	return "<n>";
}