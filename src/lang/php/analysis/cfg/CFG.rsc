module lang::php::analysis::cfg::CFG

import lang::php::ast::AbstractSyntax;
import List;
import Set;
import Relation;
import Graph;
import vis::Figure;
import vis::Render; 
import IO;
import Node;

public data CFGNode = cfgNode(Stmt stmt, int pp) | entry() | exit() | exitScript() | caseEntry(int pp) | loopEntry(Expr cond, int pp) | loopExit(int pp);
public data CFID = main() | function(str fn) | method(str cn, str mn);

public default CFGNode cfgNode(Stmt stmt) = cfgNode(stmt, stmt@pp);

public Graph[CFGNode] makeCFGraph(list[Stmt] body, CFGNode startNode, CFGNode endNode, CFGNode returnNode, list[CFGNode] breakStack, list[CFGNode] continueStack, list[CFGNode] catchStack, map[str,CFGNode] jumpTargets) {
	
	CFGNode priorNode(int idx) {
		if (idx <= 0)
			return startNode;
		else
			return cfgNode(body[idx-1]);
	}
	
	CFGNode nextNode(int idx) {
		if (idx == size(body) - 1)
			return endNode;
		else
			return cfgNode(body[idx+1]);
	}

	if (size(body) == 0) return { < startNode, endNode > };
	Graph[CFGNode] res = { < startNode, cfgNode(head(body)) >, < cfgNode(last(body)), endNode > };
	
	for (idx <- index(body)) {
		stmt = body[idx];
		switch(stmt) {
			case \break(noExpr()) : res = res + < cfgNode(stmt), head(breakStack) >;
			case \break(someExpr(_)) : res = res +  { < cfgNode(stmt), i > | i <- breakStack }; 

			case \continue(noExpr()) : res = res + < cfgNode(stmt), head(continueStack) >;
			case \continue(someExpr(_)) : res = res +  { < cfgNode(stmt), i > | i <- continueStack }; 
		
			case declare(_,dbody) :
				if (size(dbody) > 0)
					res = res + < cfgNode(stmt), cfgNode(dbody[0]) > + makeCFGraph(dbody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
				else 
					res = res + < cfgNode(stmt), nextNode(idx) >;

			case do(_,dbody) :
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) >, < cfgNode(stmt), cfgNode(stmt) > } + makeCFGraph(dbody, cfgNode(stmt), nextNode(idx), returnNode, [ nextNode(idx) ] + breakStack, [ cfgNode(stmt) ] + continueStack, catchStack, jumpTargets);

			case \for(_,_,_,dbody) :
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) >, < cfgNode(stmt), cfgNode(stmt) > } + makeCFGraph(dbody, cfgNode(stmt), nextNode(idx), returnNode, [ nextNode(idx) ] + breakStack, [ cfgNode(stmt) ] + continueStack, catchStack, jumpTargets);

			case \foreach(_,_,_,_,dbody) :
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) >, < cfgNode(stmt), cfgNode(stmt) > } + makeCFGraph(dbody, cfgNode(stmt), nextNode(idx), returnNode, [ nextNode(idx) ] + breakStack, [ cfgNode(stmt) ] + continueStack, catchStack, jumpTargets);

			case goto(l) : res = res + < cfgNode(stmt), jumpTargets[l] >;
			
			case haltCompiler(_) : res = res + < cfgNode(stmt), exitScript() >;

			case \if(_,ibody,elifs,noElse()) : {
				res = res + < cfgNode(stmt), nextNode(idx) >;
				for (elseIf(_,eibody) <- elifs)
					res = res + makeCFGraph(eibody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
				res = res + makeCFGraph(ibody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
			}
							 			
			case \if(_,ibody,elifs,someElse(\else(ebody))) : {
				for (elseIf(_,eibody) <- elifs)
					res = res + makeCFGraph(eibody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
				res = res + makeCFGraph(ibody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
				res = res + makeCFGraph(ebody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
			}

			case namespace(_,nbody) :
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) > } +
						    makeCFGraph(ebody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
				
			case \return(_) :
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), returnNode > };

			case \switch(_, cases) : {
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) > };
				for (caseidx <- index(cases), \case(_,cbody) := cases[caseidx]) {
					if (caseidx < (size(cases)-1))
						res = res + makeCFGraph(cbody, cfgNode(stmt), caseEntry(cases[caseidx+1]@pp), returnNode, [ nextNode(idx) ] + breakStack, [ nextNode(idx) ] + continueStack, catchStack, jumpTargets);
					else
						res = res + makeCFGraph(cbody, cfgNode(stmt), nextNode(idx), returnNode, [ nextNode(idx) ] + breakStack, [ nextNode(idx) ] + continueStack, catchStack, jumpTargets);
				}
			}

			case \throw(_) :
				res = res + { < cfgNode(stmt), c > | c <- catchStack } + < priorNode(idx), cfgNode(stmt) > + 
					          < cfgNode(stmt), returnNode > + < cfgNode(stmt), exitScript() >;

			case tryCatch(tbody, catches) : {
				res = res + { < priorNode(idx), cfgNode(stmt) >, < cfgNode(stmt), nextNode(idx) > };
				res = res + makeCFGraph(tbody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, [ cfgNode(c) | c <- catches ] + catchStack, jumpTargets);
				for (\catch(_,_,cbody) <- catches)
					res = res + makeCFGraph(cbody, cfgNode(stmt), nextNode(idx), returnNode, breakStack, continueStack, catchStack, jumpTargets);
			}
			
			// NOTE: Here we always loop back to the entry node. The condition is checked here. We could also just add
			// an edge from the loop exit to the next statement. 
			case \while(cexp,wbody) : {
				res2 = { < priorNode(idx), cfgNode(stmt) >, 			// entry into statement
							  < cfgNode(stmt), loopEntry(cexp,stmt@pp) >,	// statement to loop header 
							  < loopEntry(cexp,stmt@pp), nextNode(idx) >, 	// entry to next statement (condition false)
							  < loopExit(stmt@pp), loopEntry(cexp,stmt@pp) > }; 	// exit to entry (iteration)
				res3 = makeCFGraph(wbody, loopEntry(cexp,stmt@pp), loopExit(stmt@pp), returnNode, [ nextNode(idx) ] + breakStack, [ loopEntry(cexp,stmt@pp) ] + continueStack, catchStack, jumpTargets);
				//for (<r1,r2> <- res3) println("FROM:\n<r1>\nTO:\n<r2>\n");
				res = res + res2 + res3;
				}
			

			default : res = res + < cfgNode(stmt), nextNode(idx) >;
		}
	}
	
	return res;
}

public Graph[CFGNode] makeCFGraph(list[Stmt] body) {
	return makeCFGraph(body, entry(), exit(), exit(), [ ], [ ], [ ], ( s : cfgNode(n) | /n:label(s) := body) );
}

public anno int Stmt@pp;
public anno int Case@pp;

public map[CFID,Graph[CFGNode]] formCFG(Script scr) {
	int nextppid = 0;
	int nextpp() { nextppid = nextppid + 1; return nextppid; }
	
	// First, assign program points, i.e. unique IDs
	scr = top-down visit(scr) {
		case Stmt s => s[@pp=nextpp()]
		case Case c => c[@pp=nextpp()]
	}
	
	// Second, pull out all class defs, interface defs, trait defs, and function defs. These are all top-level items
	// are are not actually part of the control flow.
	functionDefs = { f | /f:function(_,_,_,_) := scr };
	classDefs = { c | /c:classDef(_) := scr };
	interfaceDefs = { i | /i:interfaceDef(_) := scr };
	traitDefs = { t | /t:traitDef(_) := scr };
	
	scr = top-down visit(scr) {
		case [a*,function(_,_,_,_),b*] => [*a,*b]
		case [a*,classDef(_),b*] => [*a,*b]
		case [a*,interfaceDef(_),b*] => [*a,*b]
		case [a*,traitDef(_),b*] => [*a,*b]
	}
	
	// Third, form the control flow graph for each list of statements that is the body of either
	// a function, a method, or the top-level script.
	mainBlock = scr.body;
	map[CFID,Graph[CFGNode]] cfgs = ( );
	
	cfgs[main()] = makeCFGraph(mainBlock);
	
	for (function(fn,_,_,body) <- functionDefs)
		cfgs[function(fn)] = makeCFGraph(body);
		
	for (classDef(class(cn,_,_,_,mbrs)) <- classDefs, method(mn,_,_,_,body) <- mbrs)
		cfgs[method(cn,mn)] = makeCFGraph(body);
		
	return cfgs; 
}

public void renderCFG(Graph[CFGNode] cfg) {
	nodes = [ box(text("<n>"), id(getID(n)), size(40)) | n <- carrier(cfg) ];
	edges = [ edge(getID(n1),getID(n2)) | < n1, n2 > <- cfg ];
	render(graph(nodes,edges,gap(40)));
}

public void renderCFGAsDot(Graph[CFGNode] cfg, loc writeTo) {
	bool isNode(value v) = node n := v;
	str getPrintName(CFGNode n) = (cfgNode(sn,_) := n) ? getName(sn) : getName(n);
	
	cfg = visit(cfg) { case v => delAnnotations(v) when isNode(v) }
	cfg = visit(cfg) { case inlineHTML(_) => inlineHTML("") }
	
	nodes = [ "\"<getID(n)>\" [ label = \"<getPrintName(n)>\" ];" | n <- carrier(cfg) ];
	edges = [ "\"<getID(n1)>\" -\> \"<getID(n2)>\";" | < n1, n2 > <- cfg ];
	str dotGraph = "digraph \"CFG\" {
				   '	graph [ label = \"Control Flow Graph\" ];
				   '	node [ color = white ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}

//public data CFGNode = cfgNode(Stmt stmt, int pp) | entry() | exit() | exitScript() | caseEntry(int pp);

public str getID(cfgNode(Stmt s, int pp)) = "n:<pp>";
public str getID(entry()) = "entry";
public str getID(CFGNode::exit()) = "exit";
public str getID(exitScript()) = "exitScript";
public str getID(caseEntry(int pp)) = "c:<pp>";
public str getID(loopEntry(Expr e, int pp)) = "loopEntry:<pp>";
public str getID(loopExit(int pp)) = "loopExit:<pp>";
