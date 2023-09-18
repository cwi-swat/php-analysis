@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::Visualize

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::CFG;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::cfg::BasicBlocks;
import IO;
import List;
import String;
// import vis::Figure;
// import vis::Render; 

//public void renderCFG(CFG c) {
//	str getID(CFGNode n) = "<n.lab>";
//	nodes = [ box(text("<escapeForDot(printCFGNode(n))>"), id(getID(n)), size(40)) | n <- c.nodes ];
//	edges = [ edge("<e.from>","<e.to>") | e <- c.edges ];
//	render(graph(nodes,edges,gap(40)));
//}

public str escapeForDot(str s) {
	return escape(s, ("\n" : "\\n", "\"" : "\\\""));
}

public void renderCFGAsDot(CFG c, loc writeTo, str title = "") {
	str getID(CFGNode n) = "<n.lab>";
	c = visit(c) { case inlineHTML(_) => inlineHTML("HTMLCode") }
	
	nodes = [ "\"<getID(n)>\" [ label = \"<getID(n)>:<escapeForDot(printCFGNode(n))>\", labeljust=\"l\" ];" | n <- c.nodes ];
	edges = [ "\"<e.from>\" -\> \"<e.to>\" [ label = \"<printFlowEdgeLabel(e)>\"];" | e <- c.edges ];
	str dotGraph = "digraph \"CFG\" {
				   '	graph [ label = \"Control Flow Graph<size(title)>0?" for <title>":"">\" ];
				   '	node [ shape = box ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}
