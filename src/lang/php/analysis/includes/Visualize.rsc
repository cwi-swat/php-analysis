module lang::php::analysis::includes::Visualize

import lang::php::analysis::includes::IncludeGraph;
import vis::Figure;
import vis::Render; 

public void renderIncludeGraph(IncludeGraph ig) {
	nodes = [ box(text(fileName), id(fileName), size(40)) | igNode(fileName, fileLoc) <- ig.nodes ];
	edges = [ edge(fn1,fn2) | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges ];
	render(graph(nodes,edges,gap(40)));
}

public void renderIncludeGraphAsDot(IncludeGraph ig, str product, str version, loc writeTo) {
	nodes = [ "\"<fileName>\";" | igNode(fileName, fileLoc) <- ig.nodes ];
	edges = [ "\"<fn1>\" -\> \"<fn2>\";" | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges ];
	str dotGraph = "digraph \"includeGraph\" {
				   '	graph [ label = \"Include Graph for <product> version <version>\" ];
				   '	node [ color = white ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}
