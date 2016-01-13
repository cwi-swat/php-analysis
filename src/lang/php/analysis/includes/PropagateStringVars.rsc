@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::PropagateStringVars

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::NamePaths;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BuildCFG;
import lang::php::ast::System;
import lang::php::analysis::includes::IncludeGraph;

import Set;
import Relation;
import Map;
import analysis::graphs::Graph;
import IO;

data StringVal = unknown() | moreThanOne() | unique(str sval);
data Strings = var2String(map[str,StringVal] mappings);

public System evalStringVars(System sys) {
	return ( l : evalStringVars(sys.files[l]) | l <- sys.files );
}
 
public Script evalStringVars(Script scr) {
	StringVal lubSV(StringVal v1, StringVal v2) {
		if (v1 == v2) return v1;
		if (v1 == moreThanOne() || v2 == moreThanOne()) return moreThanOne();
		if (v1 == unknown() ) return v2;
		if (v2 == unknown() ) return v1;
		if (unique(s1) := v1 && unique(s2) := v2) return moreThanOne();
	}
	
	StringVal lubSV(set[StringVal] svs) {
		res = getOneFrom(svs);
		for (sv <- svs) res = lubSV(res,sv);
		return res;
	}
	
	map[str,StringVal] mergeMappings(set[Strings] mappings, set[str] allVars) {
		assignments = { < vn, vv > | vn <- allVars, m <- mappings, vv := m.mappings[vn] };
		map[str,StringVal] res = ( );
		for (vn <- allVars) {
			if (size(assignments[vn]) == 1)
				res[vn] = getOneFrom(assignments[vn]);
			else
				res[vn] = lubSV(assignments[vn]);
		}
		return res;				
	}
	
	if (size({i|/i:include(ipath,_) := scr, scalar(string(_)) !:= ipath }) == 0) return scr;
	
	// Build control-flow graphs for the entire script 
	< lscr, cfgs > = buildCFGsAndScript(scr);
	
	// Now, just process those items in the script that contain at least one dynamic
	// include -- the winnowing is done in a separate conditional, since we don't want
	// to repeat the logic in the loop if we have multiple includes we can match... 
	map[Lab,Strings] labStrings = ( );
		for (np <- cfgs) {
			dynamicIncludes = { en | en:exprNode(include(ipath,_),_) <- cfgs[np].nodes, scalar(string(str lpath)) !:= ipath };
			if (size(dynamicIncludes) != 0) {
				cfgGraph = cfgAsGraph(cfgs[np]);
				cfgBackwards = invert(cfgGraph);
	
				allVars = { vn | /var(name(name(str vn))) := cfgs[np] };
				initialMapping = ( vn : unknown() | vn <- allVars );
				overdefinedMapping = ( vn : moreThanOne() | vn <- allVars );
				
				map[CFGNode,Strings] entryMappings = ( n : var2String( initialMapping ) | n <- carrier(cfgGraph) );
				map[CFGNode,Strings] exitMappings = ( n : var2String( initialMapping ) | n <- carrier(cfgGraph) );
	
				// Provide seed values for the exit mappings 			
				for (n:exprNode(e,l) <- carrier(cfgGraph), assign(e1,e2) := e) {
					if (var(name(name(str vn))) := e1) {
						if (scalar(string(str vv)) := e2) {
							exitMappings[n].mappings[vn] = unique(vv);
						} else {
							exitMappings[n].mappings[vn] = moreThanOne();
						}
					} else {
						exitMappings = ( n2 : var2String( overdefinedMapping ) | n2 <- carrier(cfgGraph) );
					}
				}
	
				// Iterate until the entry and exit mappings stabilize
				solve(entryMappings, exitMappings) {
					for (n <- carrier(cfgGraph)) {
						// Calculate the current IN mappings for the node
						inputs = cfgBackwards[n];
						map[str,StringVal] workingMapping = ( );
						if (size(inputs) == 1) {
							workingMapping = exitMappings[getOneFrom(inputs)].mappings;
						} else if (size(inputs) == 0) {
							workingMapping = initialMapping;
						} else {
							workingMapping = mergeMappings({exitMappings[inputNode] | inputNode <- inputs}, allVars);
						}
						
						entryMappings[n] = var2String(workingMapping);
						
						// Then, calculate the values leaving the node, which depends on what
						// the node itself actually does.
						// TODO: There are two cases we need to take care of here. First, if we
						// have an actual include expression, we need to check to see if we can
						// flatten it, since it could have an impact on the values assigned to
						// variables. Second, if we have a case where a reference is taken, we
						// should instantly set the variable value to 0. We also need proper
						// handling of global vars, for now we focus just on local variables.
						switch(n) {
							case en:exprNode(assign(var(name(name(str vn))),av),l) : {
								// If we have an assignment to a variable, 
								if (scalar(string(str vv)) := av)
									workingMapping[vn] = unique(vv);
								else
									workingMapping[vn] = moreThanOne(); 
							}
							case en:exprNode(assign(var(expr(_)),av),l) : {
								// Uses of variable variables will kill all the assignments and
								// set them to the assigned value; since we don't know which assignments
								// are being killed, though, we set everything to top
								workingMapping = ( vn : moreThanOne() | vn <- allVars );
							}
						}
						
						exitMappings[n] = var2String(workingMapping);
					}
				}
				labStrings = labStrings + 
					( l : entryMappings[n] | n <- carrier(cfgGraph), exprNode(ex,l) := n ) +
					( l : entryMappings[n] | n <- carrier(cfgGraph), stmtNode(st,l) := n );
			}
		}
	
	Expr replaceStr(Expr e, str rs) = bottom-up visit(e) { case str s2repl => rs };
	
	if (size(labStrings) > 0) {
		lscr = top-down visit(lscr) {
			case n:include(ipath,itype) : {
				if (scalar(string(str lpath)) !:= ipath) {
					altpath = top-down visit(ipath) {
						case vnode:var(name(name(str vn))) : {
							if (vnode@lab in labStrings && vn in labStrings[vnode@lab].mappings && unique(uval) := labStrings[vnode@lab].mappings[vn]) {
								insert(scalar(string(uval)[@at=vnode@at])[@at=vnode@at]);							
							}
						}
					}
					if (altpath != ipath)
						insert(include(altpath,itype)[@at=n@at]);
				}
			}
		}
	}
	return stripLabels(lscr);
}

public set[NamePath] kills(Expr e) {
	return { };
}

public void simpleStringFlow(System sys, loc fileLoc, IncludeGraph igraph) {
	< lscr, cfgs > = buildCFGsAndScript(sys.files[fileLoc]);
	edgesToResolve = { e | e <- igraph.edges, igraph.nodes[fileLoc] == e.source, !(e.target is igNode) };
	locsToResolve= { e.includeExpr@at | e <- edgesToResolve };
	
	for (e <- edgesToResolve) {
		// Get back the proper CFG
		cfgsWithInclude = { c | c <- cfgs<1>, /i:include(_,_) := c, i@at == e.includeExpr@at };
		if (size(cfgsWithInclude) != 1) continue;
		cfgWithInclude = getOneFrom(cfgsWithInclude);
		
		// Using this CFG, find the node for the include we are trying to resolve 
		g = cfgAsGraph(cfgWithInclude);
		flipped = invert(g);
		inode = getOneFrom({ n | n:exprNode(i:include(_,_),_) <- carrier(g), i@at == e.includeExpr@at });
		
		// Get the variables out of this expression
		ivars = { v | /v:var(name(name(_))) := e.includeExpr.expr };
		
		// Be reckless -- just see if we can find a def that could possibly reach here
		map[Expr,Expr] varDefs = ( );
		for (iv <- ivars) {
			reachableAssignments = { av | a:assign(iv,av) <- flipped[inode] };
			if (size(reachableAssignments) == 1)
				varDefs[iv] = av;
		}
		
		for (vd <- varDefs) {
			println("Found mapping <pp(vd)> = <pp(varDefs[vd])>");			
		}
	}		
}