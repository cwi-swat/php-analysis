@license{

  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::Visualize

import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::CFG;
import lang::php::pp::PrettyPrinter;
import IO;
import List;
import String;
import vis::Figure;
import vis::Render; 

public void renderCFG(CFG c) {
	nodes = [ box(text("<n>"), id(getID(n)), size(40)) | n <- carrier(cfg) ];
	edges = [ edge(getID(n1),getID(n2)) | < n1, n2 > <- cfg ];
	render(graph(nodes,edges,gap(40)));
}

public str escapeForDot(str s) {
	return escape(s, ("\n" : "\\n", "\"" : "\\\""));
}

public void renderCFGAsDot(CFG c, loc writeTo) {
	renderCFGAsDot(c, writeTo, "");
}

public void renderCFGAsDot(CFG c, loc writeTo, str title) {
	str getID(CFGNode n) = "<n@lab>";
	cfg = visit(cfg) { case inlineHTML(_) => inlineHTML("HTMLCode") }
	
	nodes = [ "\"<getID(n)>\" [ label = \"<escapeForDot(printCFGNode(n))>\", labeljust=\"l\" ];" | n <- c.nodes ];
	edges = [ "\"<e.from>\" -\> \"<e.to>\" [ label = \"<printFlowEdgeLabel(e)>\"];" | e <- c.edges ];
	str dotGraph = "digraph \"CFG\" {
				   '	graph [ label = \"Control Flow Graph<size(title)>0?" for <title>":"">\" ];
				   '	node [ shape = box ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}
