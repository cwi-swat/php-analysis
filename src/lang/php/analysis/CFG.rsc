@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::CFG

import IO;
import Node;
import List;
import Set;
import lang::php::analysis::BasicBlocks;
import lang::php::analysis::Split;
import lang::php::analysis::ProgramPoints;
import lang::php::pp::PrettyPrinter;
import lang::php::util::Constants;
import lang::php::analysis::InlineIncludes;
import vis::Figure;
import vis::Render;

data CFG = cfg(node startNode, node endNode, rel[node,node,node] edges);

public CFG formCFG(list[node] bs) {

	list[BasicBlock] bblist = [ ];
	list[node] bbitems = [ ];
	
	for (b <- bs) {
		if (label(_) := b) {
			// The current node is a label. This is the header for a new basic block.
			if (size(bbitems) > 0) {
				bblist = bblist + BasicBlock(bbitems);
			}
			bbitems = [ b ];
		} else if (goto(_) := b) {
			// The current node is an unconditional branch. This ends a basic block.
			bblist = bblist + BasicBlock(bbitems + b);
			bbitems = [ ];
		} else if (\return() := b) {
			// The current node is an unconditional branch. This ends a basic block.
			bblist = bblist + BasicBlock(bbitems + b);
			bbitems = [ ];
		} else if (\return(_) := b) {
			// The current node is an unconditional branch. This ends a basic block.
			bblist = bblist + BasicBlock(bbitems + b);
			bbitems = [ ];
		} else if (branch(_,_,_) := b) {
			// The current node is a conditional branch. This ends a basic block.
			bblist = bblist + BasicBlock(bbitems + b);
			bbitems = [ ];
		} else {
			bbitems = bbitems + b;
		}
	}
	
	if (size(bbitems) > 0) bblist = bblist + BasicBlock(bbitems);
	
	node startnode = "start"();
	node endnode = "end"();
	
	// Special case: if the body is empty, just return the empty CFG
	if (size(bblist) == 0) return cfg(startnode, endnode, { < startnode, "unconditional"(), endnode > });
	
	map[node,BasicBlock] jumpMap = ( ln : bb | bb:BasicBlock([label(ln),_*]) <- bblist);
	rel[node,node,node] edges = { < startnode, "unconditional"(), bblist[0] > };
	
	// TODO: The edge mapping should account for throw as well
	for (idx <- index(bblist)) {
		//println(edges);
		if (BasicBlock(bbl) := bblist[idx], goto(ln) := last(bbl)) {
			edges = edges + < bblist[idx], "unconditional"(), jumpMap[ln] >;
		} else if (BasicBlock(bbl) := bblist[idx], branch(vn,tln,fln) := last(bbl)) {
			edges = edges + < bblist[idx], "ontrue"(vn), jumpMap[tln] > + < bblist[idx], "onfalse"(vn), jumpMap[fln] >;
		} else if (BasicBlock(bbl) := bblist[idx], \return() := last(bbl)) {
			edges = edges + < bblist[idx], "unconditional"(), endnode >;
		} else if (BasicBlock(bbl) := bblist[idx], \return(_) := last(bbl)) {
			edges = edges + < bblist[idx], "unconditional"(), endnode > ;
		} else if (BasicBlock(bbl) := bblist[idx], (idx + 1) != size(bblist)) {
			edges = edges + < bblist[idx],"unconditional"(), bblist[idx + 1] >;
		} else if (BasicBlock(bbl) := bblist[idx]) {
			edges = edges + < bblist[idx], "unconditional"(), endnode >;
		}
	}
	
	return cfg(startnode, endnode, edges);
}

public CFG getCFG(map[str,node] phpScripts, str scriptName, str className, str methodName) {
	s = splitScript(phpScripts[scriptName]);
	return formCFG(getOneFrom(s[classOwns(className),methodName]));
} 

public CFG getCFG(map[str,node] phpScripts, str scriptName, str methodName) {
	s = splitScript(phpScripts[scriptName]);
	return formCFG(getOneFrom(s[globalOwns(),methodName]));
} 

public void displayCFG(CFG c) {
	//displayCFG = formCFG(getOneFrom(piSplit[classOwns("profile_point"),"display"]));
	nodeset = { n | n <- c.edges<0>} + { n | n <- c.edges<2>} - c.startNode - c.endNode;
	nodemap = ( idx : l[idx] |  l := toList(nodeset), idx <- index(l) );
	nodenames = ( l[idx] : "node<idx>" |  l := toList(nodeset), idx <- index(l) );
	nodes4g = [ box(text("<printBlockAsNode(nodemap[idx])>"), id(nodenames[nodemap[idx]])) | idx <- nodemap<0> ];
	nodenames[c.startNode] = "start";
	nodenames[c.endNode] = "end";
	nodes4g = nodes4g + [ box(text("Start"),id("start")),box(text("End"),id("end"))];
	edges4g = [ edge(nodenames[n1], nodenames[n2]) | <n1,_,n2> <- c.edges];
	render(graph(nodes4g,edges4g,std(gap(10))));
}

public alias ScriptAsCFGs = rel[Owner,str,CFG];

public ScriptAsCFGs getCFGsForScript(map[str,node] phpScripts, str scriptName) {
	//ss = addProgramPoints(splitScript(phpScripts[scriptName]));
	ss = addProgramPoints(splitScript(inlineIncludesForFile(mediawiki162, scriptName, phpScripts, mediawiki162Prefixes, mediawiki162Libs)));
	return { < owner, s, formCFG(getOneFrom(ss[owner,s])) > | < owner,s,_ > <- ss };
} 

