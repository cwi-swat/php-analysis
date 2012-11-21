module lang::php::analysis::cfg::CFG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::DataFlow;
import lang::php::pp::PrettyPrinter;

import List;
import Set;
import Relation;
import IO;

import vis::Figure;
import vis::Render; 

public data CFG = cfg(FlowEdges edges, LabelMap lm);

public CFG createCFG(Script scr) {
	< labeled, lm > = labelScript(scr, "CFG"); 
	return cfg({ *internalFlow(b) | b <- labeled.body } + { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := labeled.body }, lm);
}

public void renderCFG(CFG c) {
	nodes = [ box(text("<n>"), id(getID(n)), size(40)) | n <- carrier(cfg) ];
	edges = [ edge(getID(n1),getID(n2)) | < n1, n2 > <- cfg ];
	render(graph(nodes,edges,gap(40)));
}

//public void renderCFGAsDot(Graph[CFGNode] cfg, loc writeTo) {
//	bool isNode(value v) = node n := v;
//	str getPrintName(CFGNode n) = (cfgNode(sn,_) := n) ? getName(sn) : getName(n);
//	
//	cfg = visit(cfg) { case v => delAnnotations(v) when isNode(v) }
//	cfg = visit(cfg) { case inlineHTML(_) => inlineHTML("") }
//	
//	nodes = [ "\"<getID(n)>\" [ label = \"<getPrintName(n)>\" ];" | n <- carrier(cfg) ];
//	edges = [ "\"<getID(n1)>\" -\> \"<getID(n2)>\";" | < n1, n2 > <- cfg ];
//	str dotGraph = "digraph \"CFG\" {
//				   '	graph [ label = \"Control Flow Graph\" ];
//				   '	node [ color = white ];
//				   '	<intercalate("\n", nodes)>
//				   '	<intercalate("\n",edges)>
//				   '}";
//	writeFile(writeTo,dotGraph);
//}
