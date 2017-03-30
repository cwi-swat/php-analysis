@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::BuildCFG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::NamePaths;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::LabelState;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BasicBlocks;
import lang::php::util::Utils;

import IO;
import List;
import Set;
import Node;
import Relation;
import Exception;

// TODOs:
// 4. Initializations of properties in classes, and of parameters with
//    defaults, both need to be accounted for in the control flow graph.
//    For the first, this should be done by moving the initializations
//    into the constructor (if it exists) or adding a constructor (if
//    needed). For the second, this should be done by adding these as
//    possible assignments coming out of the entry node for the method.
//
// UPDATE: This is done for parameters with defaults, but still needs
//   to be done for class properties.
//
// * We currently don't catch cases where gotos jump into a loop or
//   switch from outside. These are disallowed by PHP, so they don't
//   correspond to possible (executable) programs, but we should catch
//   those cases here during CFG construction.
//
// * We need edges representing exceptions. We capture explicit throws,
//   but need to handle exceptions coming from method calls, function
//   calls, etc. NOTE: most PHP code uses the old error mechanism,
//   which doesn't throw exceptions unless explicit error handlers that
//   convert these to exceptions have been added.
//
@doc{Build the CFGs for a single PHP file, given as a location}
public map[NamePath,CFG] buildCFGs(loc l, bool buildBasicBlocks=true) {
	return buildCFGs(loadPHPFile(l), buildBasicBlocks=buildBasicBlocks);
}

@doc{Build the CFGs for a PHP script, returning both the CFGs and the labeled script.}
public tuple[Script scr, map[NamePath,CFG] cfgs] buildCFGsAndScript(Script scr, bool buildBasicBlocks=true) {
	lstate = newLabelState();
	< scrLabeled, lstate > = labelScript(scr, lstate);
	
	map[NamePath,CFG] res = ( );

	//println("Creating CFG for top-level script");
	< scriptCFG, lstate > = createScriptCFG(scrLabeled, lstate);
	res[scriptPath()] = scriptCFG;
		
	for (/class(cname,_,_,_,mbrs) := scrLabeled, m:method(mname,_,_,params,body) <- mbrs) {
		methodNamePath = methodPath(cname,mname);
		//println("Creating CFG for <cname>::<mname>");
		< methodCFG, lstate > = createMethodCFG(methodNamePath, m, lstate);
		res[methodNamePath] = methodCFG;
	}

	for (/f:function(fname,_,params,body) := scrLabeled) {
		functionNamePath = functionPath(fname);
		//println("Creating CFG for <fname>");
		< functionCFG, lstate > = createFunctionCFG(functionNamePath, f, lstate);
		res[functionNamePath] = functionCFG;
	}
	 
	if (buildBasicBlocks) {
		res = ( np : createBasicBlocks(res[np]) | np <- res );
	}
	 
	return < scrLabeled, res >;
}

@doc{Build just the CFGs for a PHP script}
public map[NamePath,CFG] buildCFGs(Script scr, bool buildBasicBlocks=true) = buildCFGsAndScript(scr, buildBasicBlocks=buildBasicBlocks).cfgs;

@doc{Strip the label annotations off of the nodes in the script.}
public Script stripLabels(Script scr) {
	str labAnno = "lab";
	return visit(scr) {
		case Expr e => delAnnotation(e, labAnno) when (e@lab)?
		case Stmt s => delAnnotation(s, labAnno) when (s@lab)?
	}
}

@doc{Retrieve all method declarations from a script.}
private map[NamePath, ClassItem] getScriptMethods(Script scr) =
	( [class(cname),method(mname)] : m | /class(cname,_,_,_,mbrs) := scr, m:method(mname,_,_,params,body) <- mbrs );

// TODO: It is possible in PHP to have non-unique or conditional declarations. We may need a way to represent
// that here, assuming we ever run across it.

@doc{Retrieve all function declarations from a script. Note: this assumes that definitions are unique.}
private map[NamePath, Stmt] getScriptFunctions(Script scr) =
	( functionPath(fname) : f | /f:function(fname,_,_,_) := scr );

private tuple[set[CFGNode] nodes, set[FlowEdge] edges] cleanUpGraph(LabelState lstate, set[FlowEdge] edges) {
	allTargets = { e.to | e <- edges };
	allSources = { e.from | e <- edges };
	unusedFooters = { n | n <- lstate.nodes, n is footerNode, n@lab notin allTargets };
	unusedFooterLabels = { n@lab | n <- unusedFooters };
	isolatedNodes = { n | n <- lstate.nodes, /Exit/ !:= getName(n), n@lab notin allTargets, n@lab notin allSources };
	
	nodes = (lstate.nodes - unusedFooters) - isolatedNodes; //  - unusedFooters - isolatedNodes;
	edges = { e | e <- edges, e.from notin unusedFooterLabels };

	return < nodes, edges >;
}

private set[FlowEdge] removeUnrealizablePaths(set[FlowEdge] edges) {
	jumpingEdgeNames = { "jumpEdge", "escapingBreakEdge", "escapingContinueEdge", "escapingGotoEdge" };
	jumpingEdges = { e | e <- edges, getName(e) in jumpingEdgeNames };
	jumpSources = { e.from | e <- jumpingEdges };
	unrealizableEdges = { e | e <- edges, e notin jumpingEdges, e.from in jumpSources };
	
	return edges - unrealizableEdges;
}

private tuple[CFG scriptCFG, LabelState lstate] createScriptCFG(Script scr, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	entryLabel = incLabel(); exitLabel = incLabel();
	cfgEntryNode = scriptEntry(entryLabel)[@lab=entryLabel];
	cfgExitNode = scriptExit(exitLabel)[@lab=exitLabel];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

	if (script(list[Stmt] b) !:= scr)
		return < cfg(scriptPath(), lstate.nodes, { }, cfgEntryNode, cfgExitNode), lstate >;
	
	scriptBody = scr.body;
	sbReduced = visit(scriptBody) {
		case r:classDef(_) => emptyStmt()[@lab=r@lab]
		case r:interfaceDef(_) => emptyStmt()[@lab=r@lab]
		case r:traitDef(_) => emptyStmt()[@lab=r@lab]
		case r:function(_,_,_,_) => emptyStmt()[@lab=r@lab]
	}
	
	lstate.gotoNodes = ( ln : lstmt@lab | /lstmt:label(ln) := sbReduced ); 
	
	// Add all the statements and expressions as CFG nodes
	// TODO: Remove this, we should only add nodes that correspond to
	// sources or targets for edges...
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := sbReduced };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := sbReduced };
	
	set[FlowEdge] edges = { };
	for (b <- sbReduced) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, sbReduced);
	if (size(sbReduced) > 0) {
		edges += { flowEdge(cfgEntryNode@lab, i) | i <- init(head(sbReduced), lstate) };
		edges += { flowEdge(f, cfgExitNode@lab) | f <- final(last(sbReduced), lstate)};
		// TODO: Need to be more careful with adding edges, it may be a dup if we have
		// another type of edge here already
		//edges += { flowEdge(f, lstate.footerNodes[f]), flowEdge(lstate.footerNodes[f], cfgExitNode@lab) | f <- final(last(sbReduced)), f in lstate.footerNodes };
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}

	< nodes, edges > = cleanUpGraph(lstate, edges);
	edges = removeUnrealizablePaths(edges); 
	lstate = shrink(lstate);

	//< nodes, edges, lstate > = addFooterNodes(nodes, edges, lstate);
	
	// Adding CFG nodes for the expressions and statements above added in all
	// the nested nodes from inside functions and methods as well. Here, we
	// discard these.
	labels = { e.from, e.to | e <- edges };
	nodes = { n | n <- nodes, n@lab in labels } + { cfgEntryNode, cfgExitNode };
	
 	return < cfg(scriptPath(), nodes, edges, cfgEntryNode, cfgExitNode), lstate >;   
}

// TODO: The code for functions and methods is very similar, so refactor to remove
// this duplication...
private tuple[CFG methodCFG, LabelState lstate] createMethodCFG(NamePath np, ClassItem m, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	entryLabel = incLabel(); exitLabel = incLabel();
	cfgEntryNode = methodEntry(np.parent.file, np.file, entryLabel)[@lab=entryLabel];
	cfgExitNode = methodExit(np.parent.file, np.file, exitLabel)[@lab=exitLabel];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

    methodBody = m.body;
	lstate.gotoNodes = ( ln : lstmt@lab | /lstmt:label(ln) := methodBody); 
	
	// Add all the statements and expressions as CFG nodes
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := methodBody };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := methodBody };
	
	// Add any initializer expressions from the parameters as CFG nodes
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := m.params };
	
	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	notProvided = [ actualNotProvided(pn, e, br, newLabel)[@lab=newLabel] | param(pn,someExpr(e),_,br) <- m.params, newLabel := incLabel() ];
	lstate.nodes += toSet(notProvided);

	set[FlowEdge] edges = { };
	for (b <- methodBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, methodBody);

	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	paramNodes = [ ];
	for (param(pn,oe,ot,br) <- m.params) {
		newLabel = incLabel();
		newNode = (someExpr(e) := oe) ? actualNotProvided(pn, e, br, newLabel)[@lab=newLabel] : actualProvided(pn, br, newLabel)[@lab=newLabel];
		lstate.nodes = lstate.nodes + newNode;

		if (size(paramNodes) > 0) {
			if (someExpr(e) := oe) {
				edges += { flowEdge(last(paramNodes)@lab, i) | i <- init(e, lstate) };  
			} else {
				edges += flowEdge(last(paramNodes)@lab, newNode@lab);
			}
		}

		paramNodes = paramNodes + newNode; 

		if (someExpr(e) := oe) {
			< edges, lstate > += addExpEdges(edges, lstate, e);
			edges += { flowEdge(fi, newNode@lab) | fi <- final(e, lstate) };
		}
	}
	
	// Wire up the entry, exit, default init, and body nodes.
	if (size(paramNodes) > 0) {
		if (head(paramNodes) is actualNotProvided) {
			edges += { flowEdge(cfgEntryNode@lab, i) | i <- init(head(paramNodes).expr, lstate) };
		} else {
			edges += flowEdge(cfgEntryNode@lab, head(paramNodes)@lab);
		}
		
		if (size(methodBody) > 0) {
			edges += { flowEdge(last(paramNodes)@lab, i) | i <- init(head(methodBody), lstate) };
			edges += { flowEdge(fe, cfgExitNode@lab) | fe <- final(last(methodBody), lstate) };
		} else {
			edges += flowEdge(last(paramNodes)@lab, cfgExitNode@lab);
		}
	} else if (size(methodBody) > 0) {
		edges += { flowEdge(cfgEntryNode@lab, i) | i <- init(head(methodBody), lstate) };
		edges += { flowEdge(fe, cfgExitNode@lab) | fe <- final(last(methodBody), lstate) };
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}


	< nodes, edges > = cleanUpGraph(lstate, edges);
	edges = removeUnrealizablePaths(edges); 
	lstate = shrink(lstate);

 	return < cfg(np, nodes, edges, m@at, cfgEntryNode, cfgExitNode), lstate >;   
}

// TODO: The code for functions and methods is very similar, so refactor to remove
// this duplication...
private tuple[CFG functionCFG, LabelState lstate] createFunctionCFG(NamePath np, Stmt f, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	entryLabel = incLabel(); exitLabel = incLabel();
	cfgEntryNode = functionEntry(np.file, entryLabel)[@lab=entryLabel];
	cfgExitNode = functionExit(np.file, exitLabel)[@lab=exitLabel];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

    functionBody = f.body;
	lstate.gotoNodes = ( ln : lstmt@lab | /lstmt:label(ln) := functionBody); 
	
	// Add all the statements and expressions as CFG nodes
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := functionBody };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := functionBody };
	
	// Add any initializer expressions from the parameters as CFG nodes
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := f.params };
	
	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	notProvided = [ actualNotProvided(pn, e, br, newLabel)[@lab=newLabel] | param(pn,someExpr(e),_,br) <- f.params, newLabel := incLabel() ];
	lstate.nodes += toSet(notProvided);

	set[FlowEdge] edges = { };
	for (b <- functionBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, functionBody);

	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	paramNodes = [ ];
	for (param(pn,oe,ot,br) <- f.params) {
		newLabel = incLabel();
		newNode = (someExpr(e) := oe) ? actualNotProvided(pn, e, br, newLabel)[@lab=newLabel] : actualProvided(pn, br, newLabel)[@lab=newLabel];
		lstate.nodes = lstate.nodes + newNode;

		if (size(paramNodes) > 0) {
			if (someExpr(e) := oe) {
				edges += { flowEdge(last(paramNodes)@lab, i) | i <- init(e, lstate) };  
			} else {
				edges += flowEdge(last(paramNodes)@lab, newNode@lab);
			}
		}

		paramNodes = paramNodes + newNode; 

		if (someExpr(e) := oe) {
			< edges, lstate > += addExpEdges(edges, lstate, e);
			edges += { flowEdge(fi, newNode@lab) | fi <- final(e, lstate) };
		}
	}
	
	// Wire up the entry, exit, default init, and body nodes.
	if (size(paramNodes) > 0) {
		if (head(paramNodes) is actualNotProvided) {
			edges += { flowEdge(cfgEntryNode@lab, i) | i <- init(head(paramNodes).expr, lstate) };
		} else {
			edges += flowEdge(cfgEntryNode@lab, head(paramNodes)@lab);
		}
		
		if (size(functionBody) > 0) {
			edges += { flowEdge(last(paramNodes)@lab, i) | i <- init(head(functionBody), lstate) };
			edges += { flowEdge(fe, cfgExitNode@lab) | fe <- final(last(functionBody), lstate) };
		} else {
			edges += flowEdge(last(paramNodes)@lab, cfgExitNode@lab);
		}
	} else if (size(functionBody) > 0) {
		edges += { flowEdge(cfgEntryNode@lab, i) | i <- init(head(functionBody), lstate) };
		edges += { flowEdge(fe, cfgExitNode@lab) | fe <- final(last(functionBody), lstate) };
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}

	< nodes, edges > = cleanUpGraph(lstate, edges);
	edges = removeUnrealizablePaths(edges); 
	lstate = shrink(lstate);

 	return < cfg(np, nodes, edges, f@at, cfgEntryNode, cfgExitNode), lstate >;   
}

// Find the initial label for each statement. We return a set since, in some cases,
// there may be no initial label available.
public set[Lab] init(Stmt s, LabelState lstate) {
	if (s@lab in lstate.headerNodes) return { lstate.headerNodes[s@lab] };
	
	switch(s) {
		case emptyStmt() : return { s@lab };
		
		// If the break statement has an expression, that is the first thing that occurs in
		// the statement. If not, the break itself is the first thing that occurs.
		case \break(someExpr(Expr e)) : return init(e, lstate);
		case \break(noExpr()) : return { s@lab };

		// Given a list of constants, the first thing that occurs is the expression that is
		// assigned to the first constant in the list.
		case const(list[Const] consts) : {
			return init(head(consts).constValue, lstate);
		}

		// If the continue statement has an expression, that is the first thing that occurs in
		// the statement. If not, the continue itself is the first thing that occurs.
		case \continue(someExpr(Expr e)) : return init(e, lstate);
		case \continue(noExpr()) : return { s@lab };

		// Given a declaration list, the first thing that occurs is the expression in the first declaration.
		case declare(list[Declaration] decls, _) : {
			return init(head(decls).val, lstate);
		}

		// For a do/while loop, the first body statement is the first thing to occur. If the body
		// is empty, the condition is the first thing that happens.
		case do(Expr cond, list[Stmt] body) : return isEmpty(body) ? init(cond, lstate) : init(head(body), lstate);

		// Given an echo statement, the first expression in the list is the first thing that occurs.
		case echo(list[Expr] exprs) : return init(head(exprs), lstate);

		// An expression statement is just an expression treated as a statement; just check the
		// expression.
		case exprstmt(Expr expr) : return init(expr, lstate);

		// The various parts of the for are optional, so we check in the following order to find
		// the first item: first inits, than conds, than body, than exprs (which fire after the
		// body is evaluated).
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			if (!isEmpty(inits)) {
				return init(head(inits), lstate);
			} else if (!isEmpty(conds)) {
				return init(head(conds), lstate);
			} else if (!isEmpty(body)) {
				return init(head(body), lstate);
			} else if (!isEmpty(exprs)) {
				return init(head(exprs), lstate);
			}
		}

		// In a foreach loop, the array expression is required and is the first thing that is evaluated.
		case foreach(Expr arrayExpr, _, _, _, _) : return init(arrayExpr, lstate);

		// In a global statement, the first expression to be made global is the first item.
		case global(list[Expr] exprs) : {
			return init(head(exprs), lstate);
		}

		// A goto is a unit.
		case goto(_) : return { s@lab };

		// Halt compiler is a unit.
		case haltCompiler(_) : return { s@lab };

		// In a conditional, the condition is the first thing that occurs.
		case \if(Expr cond, _, _, _) : return init(cond, lstate);

		// Inline HTML is a unit.
		case inlineHTML(_) : return { s@lab };

		// A label is a unit.
		case label(_) : return { s@lab };

		// If the namespace has a body, the first thing that occurs is the first item in the
		// body
		case namespace(_, list[Stmt] body) : if (!isEmpty(body)) return init(head(body), lstate);

		// In a return, if we have an expression it provides the first label; if not, the
		// statement itself does.
		case \return(someExpr(Expr returnExpr)) : return init(returnExpr, lstate);
		case \return(noExpr()) : return { s@lab };

		// In a static declaration, the first initializer provides the first label. If we
		// have no initializers, than the statement itself provides the label.
		case static(list[StaticVar] vars) : {
			initializers = [ e | staticVar(str name, someExpr(Expr e)) <- vars ];
			if (! isEmpty(initializers)) {
				return init(head(initializers), lstate);
			} else {
				return { s@lab };
			}
		}

		// In a switch statement, the condition provides the first label.
		case \switch(Expr cond, _) : return init(cond, lstate);

		// In a throw statement, the expression to throw provides the first label.
		case \throw(Expr expr) : return init(expr, lstate);

		// In a try/catch, the body provides the first label. If the body is empty, we
		// just use the label from the statement (the catch clauses would never fire, since
		// nothing could trigger them in an empty body).
		case tryCatch(list[Stmt] body, _) : if (!isEmpty(body)) return init(head(body), lstate);

		// In a try/catch, the body provides the first label. If the body is empty, we
		// check the finally clause. If that is empty as well, we use the statement.
		case tryCatchFinally(list[Stmt] body, _, list[Stmt] finallyBody) : {
			if (isEmpty(body)) {
				if (! isEmpty(finallyBody)) {
					return init(head(finallyBody), lstate);
				}	
			} else {
				return init(head(body), lstate);
			}
		}

		// In an unset, the first expression to unset provides the first label. If the list is
		// empty, the statement itself provides the label.
		case unset(list[Expr] unsetVars) : return init(head(unsetVars), lstate);

		// A use statement is atomic.
		case use(_) : return { s@lab };

		// In a while loop, the while condition is executed first and thus provides the first label.
		case \while(Expr cond, _) : return init(cond, lstate);	
		
		// In a block, the first statement provides the first label. If there is no body,
		// the statement itself provides the label.
		case block(list[Stmt] body) : if (!isEmpty(body)) return init(head(body), lstate);
	}
	
	// This handles cases, like interfaceDef, that have no runtime behavior that should
	// be included in the control flow graph.
	return { };
}

// Find the initial label for each expression. In the case of an expression with
// children, this is the label of the first child that is executed. If the 
// expression is instead viewed as a whole (e.g., a scalar, or a variable
// lookup), the initial label is the label of the expression itself.
public set[Lab] init(Expr e, LabelState lstate) {
	if (e@lab in lstate.headerNodes) return { lstate.headerNodes[e@lab] };

	switch(e) {
		case array(list[ArrayElement] items) : {
			if (size(items) == 0) {
				return { e@lab };
			} else if (arrayElement(someExpr(Expr key), Expr val, bool byRef) := head(items)) {
				return init(key, lstate);
			} else if (arrayElement(noExpr(), Expr val, bool byRef) := head(items)) {
				return init(val, lstate);
			}
		}
		
		case fetchArrayDim(Expr var, OptionExpr dim) : return init(var, lstate);
		
		case fetchClassConst(name(Name className), str constName) : return { e@lab };

		case fetchClassConst(expr(Expr className), str constName) : return init(className, lstate);
		
		case assign(Expr assignTo, Expr assignExpr) : return init(assignExpr, lstate);
		
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) : return init(assignExpr, lstate);
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) : return init(assignExpr, lstate);
		
		case refAssign(Expr assignTo, Expr assignExpr) : return init(assignExpr, lstate);
		
		case binaryOperation(Expr left, Expr right, Op operation) : return init(left, lstate);
		
		case unaryOperation(Expr operand, Op operation) : return init(operand, lstate);
		
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			if (expr(Expr cname) := className)
				return init(cname, lstate);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr, lstate);
			return { e@lab };
		}
		
		case cast(CastType castType, Expr expr) : return init(expr, lstate);
		
		case clone(Expr expr) : return init(expr, lstate);
		
		// TODO: Add support for closures -- we should probably give them
		// anonymous names and create independent CFGs for them as well
		case closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static) : {
			println("WARNING: Closures not yet fully supported");
			return { e@lab };
		}
		
		case fetchConst(Name name) : return { e@lab };
		
		case empty(Expr expr) : return init(expr, lstate);
		
		case suppress(Expr expr) : return init(expr, lstate);
		
		case eval(Expr expr) : return init(expr, lstate);
		
		case exit(someExpr(Expr exitExpr)) : return init(exitExpr, lstate);
		case exit(noExpr()) : return { e@lab };
		
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			if (expr(Expr fname) := funName)
				return init(fname, lstate);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr, lstate);
			return { e@lab };
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			return init(target, lstate);
		}
		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			if (expr(Expr sname) := staticTarget)
				return init(sname, lstate);
			else if (expr(Expr mname) := methodName)
				return init(mname, lstate);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr, lstate);
			return { e@lab };
		}
		
		case include(Expr expr, IncludeType includeType) : return init(expr, lstate);
		
		case instanceOf(Expr expr, NameOrExpr toCompare) : return init(expr, lstate);
		
		case isSet(list[Expr] exprs) : {
			if (size(exprs) > 0)
				return init(head(exprs), lstate);
			return { e@lab };
		}
		
		case print(Expr expr) : return init(expr, lstate);
		
		case propertyFetch(Expr target, NameOrExpr propertyName) : return init(target, lstate);
		
		case shellExec(list[Expr] parts) : {
			if (size(parts) > 0)
				return init(head(parts), lstate);
			return { e@lab };
		}
		
		case ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch) : return init(cond, lstate);
		
		case staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName) : {
			if (expr(Expr cname) := className)
				return init(cname, lstate);
			else if (expr(Expr pname) := propertyName)
				return init(pname, lstate);
			return { e@lab };
		}
		
		case scalar(encapsed(parts)) : return init(head(parts), lstate);
		case scalar(Scalar scalarVal) : return { e@lab };
		
		case var(expr(Expr varName)) : return init(varName, lstate);
		case var(name(Name varName)) : return { e@lab };
		
		case yield(someExpr(key), _) : return init(key, lstate);
		case yield(noExpr(), someExpr(val)) : return init(val, lstate);
		case yield(noExpr(), noExpr()) : return { e@lab };
		
		case listExpr(exprs) : {
			actualExprs = [ ei | someExpr(ei) <- exprs ];
			return isEmpty(actualExprs) ? { e@lab } : init(head(actualExprs), lstate);
		}
	}
}

@doc{Find the label of the final step taken in computing the given statement.}
private set[Lab] final(Stmt s, LabelState lstate) {
	if (s@lab in lstate.footerNodes) return { lstate.footerNodes[s@lab] };

	switch(s) {
		case emptyStmt() : {
			return { s@lab };
		}
		
		// The final thing a break does is break, so the statement itself
		// provides the final label.
		case \break(_) : {
			return { s@lab };
		}
		
		// We always have at least one const; the final const provides the labels.
		case const(list[Const] consts) : {
			return final(last(consts).constValue, lstate);
		}

		// The final thing a continue does is continue, so the statement itself
		// provides the final label.
		case \continue(_) : {
			return { s@lab };
		}
		
		// The declare body could be empty, or an empty block; if so, the last
		// decl provides the final labels, otherwise we use the labels from the
		// final statement in the body
		case declare(list[Declaration] decls, list[Stmt] body) : {
			set[Lab] finalLabels = isEmpty(body) ? { } : final(last(body), lstate);
			if (isEmpty(finalLabels)) finalLabels = final(last(decls).val, lstate);
			return finalLabels;
		}

		// The condition is always checked last, so it provides the final labels
		case do(Expr cond, list[Stmt] body) : {
			return final(cond, lstate);
		}

		// We always have at least one expr; the final expr provides the labels.
		case echo(list[Expr] exprs) : {
			return { s@lab };
		}

		// In an expression statement, the expression provides the final labels.
		case exprstmt(Expr expr) : {
			return final(expr, lstate);
		}

		// This is just the reverse of the for logic in init; most items are optional,
		// so we check the conds, then the increments (which would run before the conds
		// check to see if we keep going), then the body, then the inits.
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			set[Lab] finalLabels = isEmpty(conds) ? { } : final(last(conds), lstate);
			if (isEmpty(finalLabels) && !isEmpty(exprs)) finalLabels = final(last(exprs), lstate);
			if (isEmpty(finalLabels) && !isEmpty(body)) finalLabels = final(last(body), lstate);
			if (isEmpty(finalLabels) && !isEmpty(inits)) finalLabels = final(last(inits), lstate);
			return finalLabels;
		}

		// We know the asVar will run, so we fall back to that if the body is empty.
		case foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body) : {
			set[Lab] finalLabels = isEmpty(body) ? { } : final(last(body), lstate);
			if (isEmpty(finalLabels)) finalLabels = final(asVar, lstate);
			return finalLabels;
		}

		// In a global statement, the last expression provides the labels.
		case global(list[Expr] exprs) : {
			return final(last(exprs), lstate);
		}

		// In a goto statement, the goto jump is the last thing we do, so it provides
		// the label.
		case goto(_) : {
			return { s@lab };
		}
		
		// haltCompiler is treated as a unit
		case haltCompiler(_) : {
			return { s@lab };
		}
		
		// In a conditional, we look to each branch for the final labels; if all the
		// branches are somehow empty, we will look to the if condition instead.
		case \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause) : {
			// The body could be empty			
			set[Lab] bodyLabels = isEmpty(body) ? { } : final(last(body), lstate);
			// We may also have no else, or an empty else
			set[Lab] elseLabels = (someElse(\else(list[Stmt] ebody)) := elseClause && !isEmpty(ebody)) ? final(last(ebody), lstate) : { };
			set[Lab] finalLabels = elseLabels;
			
			// For each elseif, either the body or (if that is empty) the guard provides
			// the final labels.
			for (elseIf(Expr econd, list[Stmt] ebody) <- elseIfs) {
				set[Lab] elseifLabels = isEmpty(ebody) ? { } : final(last(ebody), lstate);
				if (isEmpty(elseifLabels)) elseifLabels = final(econd, lstate);
				finalLabels += elseifLabels; 
			}

			// If the body is empty, or we have no other labels as final labels so far,
			// meaning no labels from the else or the elseifs (body labels are separate),
			// the condition is the final part of this construct that runs.
			if (isEmpty(body) || isEmpty(finalLabels)) finalLabels += final(cond, lstate);
			
			// We didn't add body labels in above so the above check would work; now we
			// can throw them in.
			finalLabels += bodyLabels;		

			return finalLabels;
		}

		// Inline HTML provides its own final statement, it is treated as a unit.
		case inlineHTML(_) : return { s@lab };

		// A label is a unit.
		case label(_) : return { s@lab };

		// If the namespace has a body, the last thing that occurs is the final item in the
		// body, else nothing happens at all.
		case namespace(_, list[Stmt] body) : {
			if (! isEmpty(body) ) return final(last(body), lstate);
		}

		// The last thing the return does is actually return, so the statement itself
		// provides the final label.
		case \return(_) : {
			return { s@lab };
		}
		
		// In a static declaration, the final initializer provides the final label.
		case static(list[StaticVar] vars) : {
			initializers = [ e | staticVar(str name, someExpr(Expr e)) <- vars ];
			if (! isEmpty(initializers)) {
				return final(last(initializers), lstate);
			} else {
				return { s@lab };
			}
		}

		// The switch statement has such complicated logic, and always uses a join
		// node, so we won't even bother with trying to compute what could be the
		// final labels.
		case \switch(Expr cond, list[Case] cases) : return { s@lab };

		// In a throw statement, the last thing we do is throw, so the statement provides
		// the final label.
		case \throw(_) : {
			return { s@lab };
		}
		
		// In a try/catch, we look at the final statements of the body (the non-exception
		// case) and of each catch block (the exception cases). We will have separate exception
		// edges coming out of the various blocks, so we don't try to add those here (those are
		// not unique to try/catch, we could have uncaught exceptions elsewhere).
		case tryCatch(list[Stmt] body, list[Catch] catches) : {
			set[Lab] finalLabels = { *final(last(cbody), lstate) | \catch(_, _, list[Stmt] cbody) <- catches, ! isEmpty(cbody) };
			if (! isEmpty(body)) {
				finalLabels += final(last(body), lstate);
			}
			return finalLabels;
		}

		// In a try/catch/finally, the finally clause provides the final statement. If the
		// finally is empty, we treat it as a try/catch with the same logic used above.
		case tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody) : {
			if (! isEmpty(finallyBody)) {
				return final(last(finallyBody), lstate);
			} else {
				list[Stmt] finalStmts = [ final(cbody, lstate) | \catch(_, _, list[Stmt] cbody) <- catches, ! isEmpty(cbody) ];
				if (! isEmpty(body)) {
					finalStmts += final(body, lstate);
				}
				return { *final(fs, lstate) | fs <- finalStmts };
			}
		}

		// In an unset, the last expression to unset provides the final labels.
		case unset(list[Expr] unsetVars) : {
			return final(last(unsetVars), lstate);
		}

		// A use is treated as a unit
		case use(_) : {
			return { s@lab };
		}
		
		// In a while loop, the final label is always from the condition, since that will always be
		// checked after each run of the body to see if we can continue (or to see if we run the body
		// in the first place).
		case \while(Expr cond, list[Stmt] body) : {
			return final(cond, lstate);
		}

		// For a block, return the label(s) of the last thing done inside the block body (if it is not empty)	
		case block(list[Stmt] body) : {
			if (! isEmpty(body) ) return final(last(body), lstate);
		}
	}
	
	// If we get to here, we have a statement that does nothing, like an empty block, a class definition
	// (which doesn't really execute), an interface definition, etc. In those cases, we don't return any
	// labels at all.
	return {  };
}

private set[Lab] final(Expr e, LabelState lstate) {
	if (e@lab in lstate.footerNodes) return { lstate.footerNodes[e@lab] };
	
	switch(e) {
		case ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch) : {
			if (someExpr(ie) := ifBranch)
				return final(ie, lstate) + final(elseBranch, lstate);
			else
				return final(elseBranch, lstate);
		}
	}	
	
	// The default is just to return the label for the entire expression; given an
	// expression like e_1 + e_2, the final step taken is the addition itself,
	// which is the entire expression. The cases above are thus only for those
	// expressions that deviate from this.
	return { e@lab };
}

@doc{Add internal edges between subexpressions of an expression.}
private tuple[FlowEdges, LabelState] addExpEdges(FlowEdges edges, LabelState lstate, Expr e) {
	< eedges, lstate > = internalFlow(e, lstate);
	return < edges + eedges, lstate >;
}

@doc{Add internal edges between internal expressions and statements of a statement.}
private tuple[FlowEdges, LabelState] addStmtEdges(FlowEdges edges, LabelState lstate, Stmt s) {
	< sedges, lstate > = internalFlow(s, lstate);
	return < edges + sedges, lstate >;
}

@doc{Add edges between statements given as a sequence, such as in the bodies of other statements.}
private tuple[FlowEdges, LabelState] addBodyEdges(FlowEdges edges, LabelState lstate, list[Stmt] body) {
	for ([_*,b1,b2,_*] := body) edges += { flowEdge(f, i) | f <- final(b1, lstate), i <- init(b2, lstate) };
	return < edges, lstate >;
}

@doc{Add edges between expressions that are given as a sequence.}
private tuple[FlowEdges, LabelState] addExpSeqEdges(FlowEdges edges, LabelState lstate, list[Expr] exps) {
	for ([_*,e1,e2,_*] := exps) edges += { flowEdge(f, i) | f <- final(e1, lstate), i <- init(e2, lstate) };
	return < edges, lstate >;
}

// Compute all the internal flow edges in a statement. This models the possible
// flows through the statement
//
// Note: Currently, we always have the statements in the body linked one to
// the next. This will be patched elsewhere -- if we have a return, we should
// not have an edge going to the next statement, since it is no longer reachable.
public tuple[FlowEdges,LabelState] internalFlow(Stmt s, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	initLabels = init(s, lstate);
	finalLabels = final(s, lstate);
	FlowEdges edges = { };
	
	switch(s) {
		case \break(someExpr(Expr e)) : {
			// Add the internal flow edges for the break expression, plus the edge from 
			// the expression to the statement itself.
			< edges, lstate > = addExpEdges(edges, lstate, e);
			edges += { flowEdge(fe, fl) | fe <- final(e, lstate), fl <- finalLabels, fe != fl };
			
			// Link up the break. If we have no label, it is the same as "break 1". If we 
			// have a numeric label, we jump based on that. Else, we have to link up each
			// possible break target. Note: non-literal breaks are no longer valid as of
			// PHP version 5.4. Also note that we could break beyond the current nesting
			// level, in which case we will break to the exit node. This can happen if
			// the break is actually breaking to a label provided in a file that includes
			// this script.
			// 
			// NOTE: "break 0" is the same as "break 1", and is actually no longer valid as
			// of PHP 5.4. We accept it, but also print a warning.
			if (scalar(integer(int bl)) := e) {
				if (bl == 0) {
					println("WARNING: This program has a break 0, which is no longer valid as of PHP 5.4.");
					bl = 1;
				}
				if (hasBreakLabel(bl, lstate)) {
					edges += { jumpEdge(fl, getBreakLabel(bl, lstate)) | fl <- finalLabels };
				} else {
					println("WARNING: This program breaks beyond the visible break nesting: <e@at>");
					edges += { escapingBreakEdge(fl, getExitNodeLabel(lstate), someExpr(e)) | fl <- finalLabels };
				}
			} else {
				println("WARNING: This program has a break to a non-literal expression. This is no longer allowed in PHP.");
				for (blabel <- getBreakLabels(lstate)) {
					edges += { jumpEdge(fl, blabel) | fl <- finalLabels };
				}
				edges += { escapingBreakEdge(fl, getExitNodeLabel(lstate), someExpr(e)) | fl <- finalLabels };
			}
		}

		// This is the no label case (mentioned above), which uses the same logic as "break 1"
		case \break(noExpr()) : {
			if (hasBreakLabel(1, lstate)) {
				edges += { jumpEdge(fl, getBreakLabel(1, lstate)) | fl <- finalLabels };
			} else {
				println("WARNING: This program breaks beyond the visible break nesting: <s@at>");
				edges += { escapingBreakEdge(fl, getExitNodeLabel(lstate), noExpr()) | fl <- finalLabels };
			}
		}

		// For consts, we add the edges internal to each const expression, plus we link up
		// the expressions. The final labels are already the final labels for the last
		// const initializer expression, so we don't need to further link those up here.
		case const(list[Const] consts) : {
			vals = [ c.constValue | c <- consts ];
			for (v <- vals) < edges, lstate > = addExpEdges(edges, lstate, v);
			< edges, lstate > = addExpSeqEdges(edges, lstate, vals);
		}

		// See the logic above for break, continue does essentially the same thing.
		case \continue(someExpr(Expr e)) : {
			< edges, lstate > = addExpEdges(edges, lstate, e);
			edges += { flowEdge(fe, fl) | fe <- final(e, lstate), fl <- finalLabels, fe != fl };
			
			if (scalar(integer(int bl)) := e) {
				if (bl == 0) {
					println("WARNING: This program has a continue 0, which is no longer valid as of PHP 5.4.");
					bl = 1;
				}
				if (hasContinueLabel(bl, lstate)) {
					edges += { jumpEdge(fl, getContinueLabel(bl, lstate)) | fl <- finalLabels };
				} else {
					println("WARNING: This program continues beyond the visible continue nesting: <s@at>");
					edges += { escapingContinueEdge(fl, getExitNodeLabel(lstate), someExpr(e)) | fl <- finalLabels };
				}
			} else {
				println("WARNING: This program has a continue to a non-literal expression. This is no longer allowed in PHP.");
				for (blabel <- getContinueLabels(lstate)) {
					edges += { jumpEdge(fl, blabel) | fl <- finalLabels };
				}
				edges += { escapingContinueEdge(fl, getExitNodeLabel(lstate), someExpr(e)) | fl <- finalLabels };
			}
		}

		// See the logic above for break
		case \continue(noExpr()) : {
			if (hasContinueLabel(1, lstate)) {
				edges += { jumpEdge(fl, getContinueLabel(1, lstate)) | fl <- finalLabels };
			} else {
				println("WARNING: This program continues beyond the visible continue nesting: <s@at>");
				edges += { escapingContinueEdge(fl, getExitNodeLabel(lstate), noExpr()) | fl <- finalLabels };
			}
		}

		// For declarations, the flow is through the decl expressions, then into the body
		case declare(list[Declaration] decls, list[Stmt] body) : {
			for (declaration(_,v) <- decls) < edges, lstate > = addExpEdges(edges, lstate, v);
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ v | declaration(v) <- decls ]);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			        
			if (size(decls) > 0 && size(body) > 0 && declaration(_,v) := last(decls) && b := head(body))
				edges += { flowEdge(fe, i) | fe <- final(v, lstate), i <- init(b, lstate), fe != i };
		}

		// For do/while loops, the flow is through the body, then to the condition
		// then to both the statement label and the top of the body (backedge).
		case do(Expr cond, list[Stmt] body) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];
			
			// Push the break and continue labels. If we break, we go to the end
			// of the statement. If we continue, we go to the condition instead.
			// TODO: I know this works because cond only has a single init label, but this should be made clear somehow in the code itself
			lstate = pushContinueLabel(getOneFrom(init(cond, lstate)), pushBreakLabel(footernode, lstate));
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);			

			if (size(body) > 0) {
				edges += { conditionTrueFlowEdge(fe,i,cond) | fe <- final(cond, lstate), i <- init(head(body), lstate) };
				edges += { flowEdge(fe,i) | fe <- final(last(body), lstate), i <- init(cond, lstate) };			
			} else {
				edges += { conditionTrueflowEdge(fe, getOneFrom(init(cond, lstate)), cond) | fe <- final(cond, lstate) };
			}
			edges += { conditionFalseFlowEdge(fc, footernode, cond) | fc <- final(cond, lstate) };
			
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate = popBreakLabel(popContinueLabel(lstate));
		} 

		// For echo, the flow is from left to right in the echo expressions
		case echo(list[Expr] exprs) : {
			for (e <- exprs) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			edges += { flowEdge(el, fl) | el <- final(last(exprs), lstate), fl <- finalLabels }; 
		}

		// For the expression statement, we need to capture the internal flow of
		// the expression itself
		case exprstmt(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
		}

		// Comments are given inline -- flow through a for is complex...
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			// If we break, we go to the end. If we continue, we go to the first condition,
			// unless we have none, then we just re-execute the body. If we have an empty
			// body, we just assign the final label, but this is just so we have something,
			// since, if the body is empty, we won't find a continue statement in it.
			// NOTE: We will never have more than 1 init label, we return a set since we
			// may have none. If we have none, this means the body does nothing, so linking
			// to the join node is equivalent (we won't have a continue anyway).
			lstate = pushBreakLabel(footernode, lstate);
			if (size(conds) > 0)
				lstate = pushContinueLabel(getOneFrom(init(head(conds), lstate)), lstate);
			else if (size(body) > 0 && size(init(head(body), lstate)) >= 1)
				lstate = pushContinueLabel(getOneFrom(init(head(body), lstate)), lstate);
			else
				lstate = pushContinueLabel(footernode, lstate);

			// Add the edges for each expression and statement...
			for (e <- inits) < edges, lstate > = addExpEdges(edges, lstate, e);
			for (e <- conds) < edges, lstate > = addExpEdges(edges, lstate, e); 
			for (e <- exprs) < edges, lstate > = addExpEdges(edges, lstate, e);
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			
			// ...and add the edges linking them all together.
			< edges, lstate > = addExpSeqEdges(edges, lstate, inits);
			< edges, lstate > = addExpSeqEdges(edges, lstate, conds);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			
			// The forward edge from the last init
			if (size(inits) > 0 && size(conds) > 0)
				edges += { flowEdge(fi,getOneFrom(init(head(conds), lstate))) | fi <- final(last(inits), lstate) };
			else if (size(inits) > 0 && size(body) > 0 && size(init(head(body), lstate)) > 0)
				edges += { flowEdge(fi, fe) | fi <- final(last(inits), lstate), fe <- init(head(body), lstate) };
			else if (size(inits) > 0 && size(exprs) > 0)
				edges += { flowEdge(fi,ii) | fi <- final(last(inits), lstate), ii <- init(head(exprs), lstate) };
			else if (size(inits) > 0)
				// TODO: In this case, the loop never actually terminates...
				edges += { flowEdge(fi, footernode) | fi <- final(last(inits), lstate) };
				
			// The forward edge from the last condition into the loop body
			if (size(conds) > 0 && size(body) > 0)
				edges += { conditionTrueFlowEdge(fc, fi, conds) | fc <- final(last(conds), lstate), fi <- init(head(body), lstate)};
			else if (size(conds) > 0 && size(exprs) > 0)
				edges += { conditionTrueFlowEdge(fc, ii, conds) | fc <- final(last(conds), lstate), ii <- init(head(exprs), lstate)};
			else if (size(conds) > 0)
				edges += { conditionTrueFlowEdge(fc, ii, conds) | fc <- final(last(conds), lstate), ii <- init(head(conds), lstate) };
				
			// The "false" edge from the last condition
			if (size(conds) > 0)
				edges += { conditionFalseFlowEdge(fc, footernode, conds) | fc <- final(last(conds), lstate) };
				
			// The backedge from the body
			if (size(body) > 0 && size(exprs) > 0)
				edges += { flowEdge(fi, ii) | fi <- final(last(body), lstate), ii <- init(head(exprs), lstate) };
			else if (size(body) > 0 && size(conds) > 0)
				edges += { flowEdge(fi, ii) | fi <- final(last(body), lstate), ii <- init(head(conds), lstate) };
			else if (size(body) > 0)
				edges += { flowEdge(fi, fe) | fi <- final(last(body), lstate), fe <- init(head(body), lstate) };
				
			// The loop backedge
			if (size(exprs) > 0 && size(conds) > 0)
				edges += { flowEdge(fe, ii) | fe <- final(last(exprs), lstate), ii <- init(head(conds), lstate) };
			else if (size(exprs) > 0 && size(body) > 0)
				edges += { flowEdge(fe, fi) | fe <- final(last(exprs), lstate), fi <- init(head(body), lstate) };
			else if (size(exprs) > 0)
				edges += { flowEdge(fe, ii) | fe <- final(last(exprs), lstate), ii <- init(head(exprs), lstate) };
			else if (size(conds) > 0)
				edges += { flowEdge(fe, ii) | fe <- final(last(conds), lstate), ii <- init(head(conds), lstate) };
			else if (size(body) > 0)
				edges += { flowEdge(fe, fi) | fe <- final(last(body), lstate), fi <- init(head(body), lstate) };
			else
				edges += flowEdge(footernode, footernode);
				
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			// The test to see if there are still elements in the array is implicit in the
			// control flow, we add this node as an explicit "check point". We also add an
			// edge from the check to the end of the statement, representing the case where
			// the array is exhausted.
			Lab newLabel = incLabel();
			Lab varLabel = incLabel(); 
			testNode = foreachTest(arrayExpr,newLabel)[@lab=newLabel];
			varNode = foreachAssignValue(asVar,varLabel)[@lab=varLabel];
			lstate.nodes = lstate.nodes + testNode + varNode;
			edges += iteratorEmptyFlowEdge(testNode@lab, footernode, arrayExpr);
			
			// Add in the edges for break and continue. Continue will go to the test node
			// that we just added, since that is (essentially) the condition. Break, as
			// usual, just goes to the end
			lstate = pushContinueLabel(testNode@lab, pushBreakLabel(footernode, lstate));
		
			// Calculate the internal flow of the array expression and var expression.
			< edges, lstate > = addExpEdges(edges, lstate, arrayExpr);
			< edges, lstate > = addExpEdges(edges, lstate, asVar);
			
			// Link the array expression to the test, it should go:
			// array expression -> test -> key var expression or var expression.
			edges = edges + { flowEdge(fe, testNode@lab) | fe <- final(arrayExpr, lstate) };

			// Add edges for each element of the body
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			
			// If we have a body, link the value expression to the body, then link the
			// body back around to the test. Else, just link the value to the test, this
			// would model the case where we just keep assigning new key/value pairs until
			// we exhaust the array.
			edges += { flowEdge(fe, varLabel) | fe <- final(asVar, lstate) };
			if (size(body) > 0) {
				edges += { flowEdge(varLabel, fi) | fi <- init(head(body), lstate) };
				edges += { flowEdge(fe, testNode@lab) | fe <- final(last(body), lstate) };
			} else {
				edges += flowEdge(varLabel, testNode@lab);
			}
			
			// This is needed to properly link up the key and value pairs, since keys are
			// not required (but values are). If we have a key, we link the test to that,
			// and we link it to the value, else we just link the test to the value.
			if (someExpr(keyexp) := keyvar) {
				Lab keyLabel = incLabel();
				keyNode = foreachAssignKey(keyexp,keyLabel)[@lab=keyLabel];
				lstate.nodes = lstate.nodes + keyNode;
				edges = edges +
					{ iteratorNotEmptyFlowEdge(testNode@lab, ii, arrayExpr) | ii <- init(keyexp, lstate) } + 
					{flowEdge(keyLabel,ii) | ii <- init(asVar, lstate) } +
					{ flowEdge(fe,keyLabel) | fe <- final(keyexp, lstate) } ;
			} else {
				edges += { iteratorNotEmptyFlowEdge(testNode@lab, ii, arrayExpr) | ii <- init(asVar, lstate) };
			}
			
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case global(list[Expr] exprs) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];
			
			// Add edges for each expression in the list, plus add edges between
			// each adjacent expression.
			for (e <- exprs) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
		}

		case goto(str gotoLabel) : {
			if (gotoLabel in lstate.gotoNodes)
				edges += { jumpEdge(fl, lstate.gotoNodes[gotoLabel]) | fl <- finalLabels };
			else
				edges += { escapingGotoEdge(fl, getExitNodeLabel(lstate), gotoLabel) | fl <- finalLabels };		
		}
		
		case \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			// Add edges for the condition
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			
			// Add edges for the body of the true branch
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			
			// Add edges for the conditions and the bodies of each elseif 
			for (elseIf(e,ebody) <- elseIfs) {
				< edges, lstate > = addExpEdges(edges, lstate, e);
				for (b <- ebody) < edges, lstate > = addStmtEdges(edges, lstate, b);
				< edges, lstate > = addBodyEdges(edges, lstate, ebody);
			}
			
			// Add edges for the body of the else, if it exists
			for (someElse(\else(ebody)) := elseClause) {
				for (b <- ebody) < edges, lstate > = addStmtEdges(edges, lstate, b);
				< edges, lstate > = addBodyEdges(edges, lstate, ebody);
			}
				
			// Now, add the edges that model the flow through the if. First, if
			// we have a true body, flow goes through the body and out the other
			// side. If we have no body in this case, flow just goes to the end. 
			// NOTE: Reminder, with init of a stmt, we always have 1 element unless
			// it is empty, in which case we have 0 (in which case we want the else
			// behavior here anyway)
			if (size(body) > 0 && size(init(head(body), lstate)) == 1) {
				edges += { conditionTrueFlowEdge(fe, getOneFrom(init(head(body), lstate)), cond) | fe <- final(cond, lstate) };
				edges += { flowEdge(fe, footernode) | fe <- final(last(body), lstate) };
			} else {
				edges += { conditionTrueFlowEdge(fe, footernode, cond) | fe <- final(cond, lstate) };
			}

			// Next, we need the flow from condition to condition, and into
			// the bodies of each elseif.
			falseConds = [ cond ];
			for (elseIf(e,ebody) <- elseIfs) {
				// We have a false flow edge from the last condition to the current condition.
				// We can only get here if each prior condition was false.
				edges += { conditionFalseFlowEdge(fe, ii, falseConds) | fe <- final(last(falseConds), lstate), ii <- init(e, lstate) };

				// As above, we then flow from the condition (if it is true) into the body and then
				// through the body, or we just flow to the end if there is no body.
				if (size(ebody) > 0 && size(init(head(ebody), lstate)) == 1) {
					edges += { conditionTrueFlowEdge(fe, getOneFrom(init(head(ebody), lstate)), e, falseConds) | fe <- final(e, lstate) };
					edges += { flowEdge(fe, footernode) | fe <- final(last(ebody), lstate) };
				} else {
					edges += { conditionTrueFlowEdge(fe, footernode, e, falseConds) | fe <- final(e, lstate) };
				}
					
				falseConds += e;
			}
			
			// Finally, if we have an else, we model flow into and through the else. If we have
			// no else, we instead have to add edges from the last false condition directly to
			// the end.
			if (someElse(\else(ebody)) := elseClause && size(ebody) > 0 && size(init(head(ebody), lstate)) == 1) {
				if (size(ebody) > 0) {
					edges += { conditionFalseFlowEdge(fe, getOneFrom(init(head(ebody), lstate)), falseConds) | fe <- final(last(falseConds), lstate) };
					edges += { flowEdge(fe, footernode) | fe <- final(last(ebody), lstate) };
				}				
			} else {
				edges += { conditionFalseFlowEdge(fe, footernode, falseConds) | fe <- final(last(falseConds), lstate) };
			}

			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
		}

		case namespace(OptionName nsName, list[Stmt] body) : {
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
		}		

		case \return(someExpr(expr)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges = edges + 
				{ flowEdge(fe, fl) | fe <- final(expr, lstate), fl <- finalLabels } + 
				{ jumpEdge(fl, getExitNodeLabel(lstate)) | fl <- finalLabels };
		}

		case \return(noExpr()) : {
			edges = edges + { jumpEdge(fl, getExitNodeLabel(lstate)) | fl <- finalLabels };
		}
		
		case static(list[StaticVar] vars) : {
			varExps = [ e | v:staticVar(str name, someExpr(Expr e)) <- vars ];
			for (e <- varExps) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, varExps);
		}

		case \switch(Expr cond, list[Case] cases) : {
			// We synthesize a join node to give all the cases somwewhere to come back
			// together at the end.
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			// Both break and continue will go to the end of the statement, add the
			// labels here to account for any we find in the case bodies.
			lstate = pushContinueLabel(footernode,pushBreakLabel(footernode, lstate));
			
			// Add all the standard edges inside the conditions and statement bodies			
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			for (\case(e,body) <- cases) {
				if (someExpr(ccond) := e) < edges, lstate > = addExpEdges(edges, lstate, ccond);
				for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
				< edges, lstate > = addBodyEdges(edges, lstate, body);
			}
						
			// The behavior of PHP is that each case condition is executed in turn until
			// a matching condition is found. So, we link each together, one after the
			// other, representing the "false" path through all the conditions (i.e.,
			// if the condition is false, the behavior is to then try the next condition).
			set[Lab] lastLabels = final(cond, lstate);
			for (\case(someExpr(e),b) <- cases) {
				if (lastLabels == final(cond, lstate)) {
					edges += { flowEdge(fc, ii) | fc <- lastLabels, ii <- init(e, lstate) };
				} else {
					edges += { conditionFalseFlowEdge(fc, ii, binaryOperation(cond,e,equal())) | fc <- lastLabels, ii <- init(e, lstate) };
				}
				lastLabels = final(e, lstate); 
			}
			
			// If we have no defaults, the last condition will "fall through" to the join
			// node when it is false, since it has nowhere else to go. Note that we make 
			// sure we have a last case condition as well; the situation where we have no
			// defaults and no other cases is handled below.
			defaults = [ i | i <- index(cases), \case(noExpr(),_) := cases[i] ];
			if (size(defaults) == 0  && lastLabels != final(cond, lstate) && size(lastLabels) > 0 && \case(someExpr(e),_) := last(cases)) {
				edges += { conditionFalseFlowEdge(fc, footernode, binaryOperation(cond,e,equal())) | fc <- lastLabels };
			}
			
			// If we had no cases with conditions, and we have no default, the behavior
			// would be to go from the switch condition to the end, so link it to the
			// join node in this case. Note that we don't have a true or false edge, this
			// is an unconditional edge in this case.
			if (size(cases) == 0)
				edges += { flowEdge(fc, footernode) | fc <- final(cond, lstate) };

			// Link up the case conditions with the body of the case that would run. To do
			// so, we link the condition with the next case body. Note: there may not be a
			// next case body. This is handled below. Also note: we can have multiple defaults.
			// If a true case falls through to a default, it will run it, even if it is not
			// the last one.
			set[Expr] exprsToLink = { };
			for (\case(oe,b) <- cases) {
				if (someExpr(e) := oe) {
					exprsToLink += e;
				}
				if (size(b) > 0) {
					edges += { conditionTrueFlowEdge(fl,bl,binaryOperation(cond,ei,equal())) | ei <- exprsToLink, fl <- final(ei,lstate), bl <- init(head(b), lstate) };
					exprsToLink = { };
				}
			}

			// If we still have exprsToLink, this means we have no body that they will run. Link
			// the true edges for these conditions to the join node.
			for (e <- exprsToLink) {
				edges += { conditionTrueFlowEdge(fl,footernode,binaryOperation(cond,ei,equal())) | ei <- exprsToLink, fl <- final(ei,lstate) };
			}
			
			// Find the default body that would run for the default case. If multiple default
			// cases exist, we use only the last. The body is either the body of the default
			// itself or the body that it would fall through to, if no default body is provided.			
			set[Lab] defaultLabels = { };
			if (size(defaults) > 0) {
				lastDefault = last(defaults);
				if (\case(noExpr(),b) := cases[lastDefault] && size(b) > 0) {
					defaultLabels = init(head(b), lstate);
				} else {
					followingBodies = [ i | i <- index(cases), i > lastDefault, \case(someExpr(_),b) := cases[i], size(b) > 0];
					if (size(followingBodies) > 0 && \case(someExpr(_),b) := cases[head(followingBodies)]) {
						defaultLabels = init(head(b), lstate);
					}
				}
			}

			// Link to the default. This is done if the last condition is false. If there are no case conditions,
			// we link from the switch condition unconditionally.
			if (size(defaultLabels) > 0) {
				caseGuards = [ e | \case(someExpr(e),b) <- cases ];
				if (size(caseGuards) > 0) {
					edges += { conditionFalseFlowEdge(el,bl,binaryOperation(cond,last(caseGuards),equal())) | el <- final(last(caseGuards), lstate), bl <- defaultLabels };
				} else {
					edges += { flowEdge(el,bl) | el <- final(cond, lstate), bl <- defaultLabels };
				}
			}
						
			// For each case, we need to simulate fall-thru. We will use a basic check here.
			// If the case body is not empty, and the last statement is a break or continue,
			// we will not add the edge, otherwise we do. Note: we could have a break or
			// continue in the middle, with the code after being dead, but we are not checking
			// for that here; this means the CFG could have paths that are not achievable in
			// the program, but this is the case anyway. This can be cleaned up later since we
			// will have a path not reachable in a standard forward traversal.
			set[Lab] fallThruLabels = { };
			for (\case(_,b) <- cases, size(b) > 0) {
				if (size(fallThruLabels) > 0) {
					edges += { flowEdge(fl,bl) | fl <- fallThruLabels, bl <- init(head(b), lstate) }; 
				}
				if (lb := last(b), (lb is \break || lb is \continue || lb is \return || lb is goto)) {
					fallThruLabels = { };
				} else {
					fallThruLabels = final(last(b), lstate);
				}
			}
			 
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case \throw(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += { flowEdge(fe, fl) | fe <- final(expr, lstate), fl <- finalLabels };
			edges += { jumpEdge(fl, cl) | fl <- finalLabels, cl <- lstate.catchHandlers<1> };
			edges += { jumpEdge(fl, getExitNodeLabel(lstate)) | fl <- finalLabels }; 
		}

		case tryCatch(list[Stmt] body, list[Catch] catches) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			oldHandlers = lstate.catchHandlers;
			for(\catch(name(xt),_,cbody) <- catches) {
				if (size(cbody) > 0 && size(init(head(cbody), lstate)) > 0) {
					lstate.catchHandlers[xt] = getOneFrom(init(head(cbody), lstate));
				} else {
					lstate.catchHandlers[xt] = footernode;
				}	
			}			
			
			// Add all the standard internal edges for the statements in the body
			// and in the catch bodies. 
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			for (\catch(_, _, cbody) <- catches, b <- cbody) < edges, lstate > = addStmtEdges(edges, lstate, b);
			for (\catch(_, _, cbody) <- catches) < edges, lstate > = addBodyEdges(edges, lstate, cbody);

			// Link the end of the main body, and each catch body, to the final label. Note: there
			// is no flow from the standard body to the exception bodies added by default, it is added
			// for throws.
			if (size(body) > 0)
				edges += { flowEdge(fl, footernode) | fl <- final(last(body), lstate) };
			for (\catch(_, _, cbody) <- catches, size(cbody) > 0)
				edges += { flowEdge(fl, footernode) | fl <- final(last(cbody), lstate) };
				
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate.catchHandlers = oldHandlers;
		}

		case tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			oldHandlers = lstate.catchHandlers;
			for(\catch(name(xt),_,cbody) <- catches) {
				if (size(cbody) > 0 && size(init(head(cbody), lstate)) > 0) {
					lstate.catchHandlers[xt] = getOneFrom(init(head(cbody), lstate));
				} else if (size(finallyBody) > 0 && size(init(head(finallyBody), lstate)) > 0) {
					lstate.catchHandlers[xt] = getOneFrom(init(head(finallyBody), lstate));
				} else {
					lstate.catchHandlers[xt] = footernode;
				}	
			}			

			// Add all the standard internal edges for the statements in the body
			// and in the catch bodies. 
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			for (b <- finallyBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			< edges, lstate > = addBodyEdges(edges, lstate, finallyBody);
			for (\catch(_, _, cbody) <- catches, b <- cbody) < edges, lstate > = addStmtEdges(edges, lstate, b);
			for (\catch(_, _, cbody) <- catches) < edges, lstate > = addBodyEdges(edges, lstate, cbody);

			// Link the end of the main body, and each catch body, to the final label.
			if (size(body) > 0 && size(finallyBody) > 0) {
				edges += { flowEdge(fl, fi) | fl <- final(last(body), lstate), fi <- init(first(finallyBody), lstate) };
			}
			else if (size(body) > 0 && size(finallyBody) > 0) {
				edges += { flowEdge(fl, footernode) | fl <- final(last(body), lstate) };
			}
			for (\catch(_, _, cbody) <- catches, size(cbody) > 0) {
				if (size(finallyBody) > 0) {
					edges += { flowEdge(fl, fi) | fl <- final(last(cbody), lstate), fi <- init(first(finallyBody), lstate) };
				} else {
					edges += { flowEdge(fl, footernode) | fl <- final(last(cbody), lstate) };
				}
			}
				
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate.catchHandlers = oldHandlers;
		}

		case unset(list[Expr] unsetVars) : {
			for (e <- unsetVars) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, unsetVars);
		}

		case \while(Expr cond, list[Stmt] body) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(s, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(s, headernode, footernode)[@lab=footernode];

			lstate = pushContinueLabel(getOneFrom(init(cond, lstate)), pushBreakLabel(footernode, lstate));
			
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);

			edges += { conditionFalseFlowEdge(fe, footernode, cond) | fe <- final(cond, lstate) };
				    
			if (size(body) > 0) {
				edges = edges + 
					{ conditionTrueFlowEdge(fc, fi, cond) | fc <- final(cond, lstate), fi <- init(head(body), lstate) } + 
					{ flowEdge(fb, ii) | fb <- final(last(body), lstate), ii <- init(cond, lstate)  };
			} else {
				edges += { conditionTrueFlowEdge(fe, ii, cond) | fe <- final(cond, lstate), ii <- init(cond, lstate) };
			}
			
			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+s@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+s@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
			lstate = popContinueLabel(popBreakLabel(lstate));
		}
		
		case block(list[Stmt] body) : {
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
		}
	}
	
	return < edges, lstate >;
}

// Compute all the internal flow edges for an expression. We pass around the label
// state in case we need to construct new labels.
public tuple[FlowEdges,LabelState] internalFlow(Expr e, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	initLabels = init(e, lstate);
	finalLabels = final(e, lstate);
	FlowEdges edges = { };
	
	set[FlowEdge] makeEdges(set[Lab] s1, Lab v1) {
		return { flowEdge(si,v1) | si <- s1 };
	}
	
	set[FlowEdge] makeEdges(set[Lab] s1, set[Lab] s2) {
		return { flowEdge(si,sj) | si <- s1, sj <- s2 };
	}
	
	set[FlowEdge] makeEdges(Lab v1, set[Lab] s2) {
		return { flowEdge(v1,sj) | sj <- s2 };
	}
	
	switch(e) {
		case array(list[ArrayElement] items) : {
			for (arrayElement(OptionExpr okey, Expr val, bool byRef) <- items) {
				< edges, lstate > = addExpEdges(edges, lstate, val);
				if (someExpr(Expr key) := okey)
					< edges, lstate > = addExpEdges(edges, lstate, key);
			}

			for (arrayElement(someExpr(kv),v1,_) <- items)
					edges += makeEdges(final(kv, lstate), init(v1, lstate));

			for ([_*,arrayElement(k1,v1,_),arrayElement(k2,v2,_),_*] := items) {
				if (someExpr(kv) := k2)
					edges += makeEdges(final(v1, lstate), init(kv, lstate));
				else
					edges += makeEdges(final(v1, lstate), init(v2, lstate));
			}

			if (size(items) > 0, arrayElement(_,val,_) := last(items))
				edges += makeEdges(final(val, lstate), finalLabels);
		}
		
		case fetchArrayDim(Expr var, someExpr(Expr dim)) : {
			< edges, lstate > = addExpEdges(edges, lstate, var);
			< edges, lstate > = addExpEdges(edges, lstate, dim);
			edges = edges + makeEdges(final(var, lstate), init(dim, lstate)) + makeEdges(final(dim, lstate),finalLabels);
		}
		
		case fetchArrayDim(Expr var, noExpr()) : {
			< edges, lstate > = addExpEdges(edges, lstate, var);
			edges += makeEdges(final(var, lstate), finalLabels);
		}
		
		case fetchClassConst(expr(Expr className), str constName) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			edges += makeEdges(final(className, lstate), finalLabels);
		}
		
		case assign(Expr assignTo, Expr assignExpr) : { 
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			edges = edges + makeEdges(final(assignExpr, lstate), init(assignTo, lstate)) + makeEdges(final(assignTo, lstate), finalLabels);
		}
		
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			edges = edges + makeEdges(final(assignExpr, lstate), init(assignTo, lstate)) + makeEdges(final(assignTo, lstate), finalLabels);
		}
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr);

			listExps = reverse([le|someExpr(le) <- assignsTo]);
			for (le <- listExps) < edges, lstate > = addExpEdges(edges, lstate, le);
			< edges, lstate > = addExpSeqEdges(edges, lstate, listExps);
			
			if (size(listExps) > 0)
				edges += makeEdges(final(last(listExps), lstate), finalLabels);
			else
				edges += makeEdges(final(assignExpr, lstate), finalLabels);
		}
		
		case refAssign(Expr assignTo, Expr assignExpr) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			edges = edges + makeEdges(final(assignExpr, lstate), init(assignTo, lstate)) + makeEdges(final(assignTo, lstate), finalLabels);
		}
		
		case binaryOperation(Expr left, Expr right, Op operation) : { 
			< edges, lstate > = addExpEdges(edges, lstate, left);
			< edges, lstate > = addExpEdges(edges, lstate, right);
			edges = edges + makeEdges(final(left, lstate), init(right, lstate)) + makeEdges(final(right, lstate), finalLabels);
		}
		
		case unaryOperation(Expr operand, Op operation) : {
			< edges, lstate > = addExpEdges(edges, lstate, operand); 
			edges = edges + makeEdges(final(operand, lstate), finalLabels);
		}
		
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);

			if (expr(Expr cn) := className) {
				< edges, lstate > = addExpEdges(edges, lstate, cn);
				if (size(parameters) > 0) {
					edges += makeEdges(final(cn, lstate), init(head(parameters).expr, lstate));
					edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
				} else {
					edges += makeEdges(final(cn, lstate), finalLabels);
				}
			} else if (size(parameters) > 0) {
				edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
			}
		}
		
		case cast(CastType castType, Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case clone(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		// TODO: Add support for closures -- we should probably give them
		// anonymous names and create independent CFGs for them as well
		
		// NOTE: fetchConst has no internal flow edges
		
		case empty(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case suppress(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case eval(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case exit(someExpr(Expr exitExpr)) : {
			< edges, lstate > = addExpEdges(edges, lstate, exitExpr);
			edges += makeEdges(final(exitExpr, lstate), finalLabels);
		}
		
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);
		
			if (expr(Expr fn) := funName) {
				< edges, lstate > = addExpEdges(edges, lstate, fn);
				if (size(parameters) > 0) {
					edges += makeEdges(final(fn, lstate), init(head(parameters).expr, lstate));
					edges += makeEdges(final(last(parameters).expr, lstate),finalLabels);
				} else {
					edges += makeEdges(final(fn, lstate),finalLabels);
				}
			} else {
				if (size(parameters) > 0)
					edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
			}
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);

			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);
			
			if (expr(Expr mn) := methodName) {
				< edges, lstate > = addExpEdges(edges, lstate, mn);
				edges += makeEdges(final(target, lstate),init(mn, lstate));
				if (size(parameters) > 0) {
					edges += makeEdges(final(mn, lstate),init(head(parameters).expr, lstate));
					edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
				} else {
					edges += makeEdges(final(mn, lstate), finalLabels);
				}
			} else {
				if (size(parameters) > 0) {
					edges += makeEdges(final(target, lstate), init(head(parameters).expr, lstate));
					edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
				} else {
					edges += makeEdges(final(target, lstate), finalLabels);
				}
			}
		}

		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);

			if (expr(Expr tn) := staticTarget) {
				< edges, lstate > = addExpEdges(edges, lstate, tn);
				if (expr(Expr mn) := methodName)
					edges += makeEdges(final(tn, lstate),init(mn, lstate));
				else if (size(parameters) > 0)
					edges += makeEdges(final(tn, lstate),init(head(parameters).expr, lstate));
				else
					edges += makeEdges(final(tn, lstate),finalLabels);
			}

			if (expr(Expr mn) := methodName) {
				< edges, lstate > = addExpEdges(edges, lstate, mn);
				if (size(parameters) > 0)
					edges += makeEdges(final(mn, lstate),init(head(parameters).expr, lstate));
				else
					edges += makeEdges(final(mn, lstate),finalLabels);
			}

			if (size(parameters) > 0) {
				edges += makeEdges(final(last(parameters).expr, lstate), finalLabels);
			}

		}

		
		case include(Expr expr, IncludeType includeType) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case instanceOf(Expr expr, expr(Expr toCompare)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			< edges, lstate > = addExpEdges(edges, lstate, toCompare);
			edges = edges + makeEdges(final(expr, lstate),init(toCompare, lstate)) + makeEdges(final(toCompare, lstate),finalLabels);
		}
		
		case instanceOf(Expr expr, name(Name toCompare)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}

		case isSet(list[Expr] exprs) : {
			for (ex <- exprs) < edges, lstate > = addExpEdges(edges, lstate, ex);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			if (size(exprs) > 0)
				edges += makeEdges(final(last(exprs), lstate), finalLabels);
		}
		
		case print(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += makeEdges(final(expr, lstate), finalLabels);
		}
		
		case propertyFetch(Expr target, expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges = edges + makeEdges(final(target, lstate),init(propertyName, lstate)) + makeEdges(final(propertyName, lstate),finalLabels);
		}
		
		case propertyFetch(Expr target, name(Name propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);
			edges += makeEdges(final(target, lstate), finalLabels);
		}

		case shellExec(list[Expr] parts) : {
			for (ex <- parts) < edges, lstate > = addExpEdges(edges, lstate, ex);
			< edges, lstate > = addExpSeqEdges(edges, lstate, parts);
			if (size(parts) > 0)
				edges += makeEdges(final(last(parts), lstate), finalLabels);
		}

		case ternary(Expr cond, someExpr(Expr ifBranch), Expr elseBranch) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(e, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(e, headernode, footernode)[@lab=footernode];

			< edges, lstate > = addExpEdges(edges, lstate, cond);
			< edges, lstate > = addExpEdges(edges, lstate, ifBranch);
			< edges, lstate > = addExpEdges(edges, lstate, elseBranch);

			edges = edges +  
				   { conditionTrueFlowEdge(fe,ii,cond) | fe <- final(cond, lstate), ii <- init(ifBranch, lstate) } +  
				   { conditionFalseFlowEdge(fe,ii,cond) | fe <- final(cond, lstate), ii <- init(elseBranch, lstate) } +
				   { flowEdge(fe, footernode) | fe <- final(ifBranch, lstate) } +
				   { flowEdge(fe, footernode) | fe <- final(elseBranch, lstate) };

			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+e@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+e@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
		}
		
		case ternary(Expr cond, noExpr(), Expr elseBranch) : {
			headernode = incLabel();
			footernode = incLabel();
			lstate.nodes = lstate.nodes + headerNode(e, footernode, headernode)[@lab=headernode];
			lstate.nodes = lstate.nodes + footerNode(e, headernode, footernode)[@lab=footernode];

			< edges, lstate > = addExpEdges(edges, lstate, cond);
			< edges, lstate > = addExpEdges(edges, lstate, elseBranch);

			edges = edges + 
				   { conditionFalseFlowEdge(fe,ii,cond) | fe <- final(cond, lstate), ii <- init(elseBranch, lstate) } +
				   { conditionTrueFlowEdge(fe, footernode, cond) | fe <- final(cond, lstate) } +
				   { flowEdge(fe, footernode) | fe <- final(elseBranch, lstate) };

			for (il <- initLabels) edges += flowEdge(headernode, il);
			for (il <- (initLabels+e@lab), il notin lstate.headerNodes) lstate.headerNodes[il] = headernode;
			for (fl <- (finalLabels+e@lab), fl notin lstate.footerNodes) lstate.footerNodes[fl] = footernode;
		}

		case staticPropertyFetch(expr(Expr className), expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges = edges + makeEdges(final(className, lstate),init(propertyName, lstate)) + makeEdges(final(propertyName, lstate), finalLabels);
		}

		case staticPropertyFetch(name(Name className), expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges += makeEdges(final(propertyName, lstate), finalLabels);
		}

		case staticPropertyFetch(expr(Expr className), name(Name propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			edges += makeEdges(final(className, lstate), finalLabels);
		}
		
		case scalar(encapsed(parts)) : {
			for (part <- parts) {
				< edges, lstate> = addExpEdges(edges, lstate, part);
			}
			< edges, lstate > = addExpSeqEdges(edges, lstate, parts);
			edges += makeEdges(final(last(parts), lstate), finalLabels);
		}
		
		case var(expr(Expr varName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, varName);
			edges += makeEdges(final(varName, lstate), finalLabels);
		}
		
		case yield(someExpr(k), noExpr()) : {
			< edges, lstate > = addExpEdges(edges, lstate, k);
			edges += makeEdges(final(k, lstate), finalLabels);
		}

		case yield(noExpr(), someExpr(v)) : {
			< edges, lstate > = addExpEdges(edges, lstate, v);
			edges += makeEdges(final(v, lstate), finalLabels);
		}

		case yield(someExpr(k), someExpr(v)) : {
			< edges, lstate > = addExpEdges(edges, lstate, k);
			< edges, lstate > = addExpEdges(edges, lstate, v);
			edges += makeEdges(final(k, lstate), init(v, lstate));
			edges += makeEdges(final(v, lstate), finalLabels);
		}
		
		case listExpr(exprs) : {
			actualExprs = [ ei | someExpr(ei) <- exprs ];
			if (size(actualExprs) > 0) {
				< edges, lstate > = addExpSeqEdges(edges, lstate, actualExprs);
				edges += makeEdges(final(last(actualExprs), lstate), finalLabels);
			}
		}
		
	}

	return < edges, lstate >;			
}

@doc{Collapse expressions, which are unrolled into chains of individual nodes, back into single expression nodes.}
public CFG collapseExpressions(CFG g) {
	entryNode = getEntryNode(g);
	exitNode = getExitNode(g);
	forwards = cfgAsGraph(g);
	backwards = invert(forwards);
	
	// Find all the expressions that are the start of a chain of expressions. This is done by, for each expression node,
	// checking the preceding nodes. We must either have more than 1 (in which case this is a join point, and we shouldn't
	// merge it with the prior node), or no preceding expressions (we could have a preceding statement).
	startingExps = { n | n <- g.nodes, 
						 n is exprNode, 
						 bn := backwards[n], 
						 bnfilt := { bni | bni <- bn, bni is exprNode, size(forwards[bni]) == 1 }, 
						 size(bn) > 1 || (size(bn) == 1 && size(bnfilt) == 0) };
	
	// A function to chase through the node graph; given a node, keep going forward as long as we only have one following
	// expression node. This is similar to the logic used to form basic blocks, but we ensure we only have "runs" of
	// expressions here, not of arbitrary types.
	list[CFGNode] chaseNodes(CFGNode n) {
		forwardFromN = forwards[n];
		if (size(forwardFromN) == 1 && getOneFrom(forwardFromN) is exprNode) {
			return getOneFrom(forwardFromN) + chaseNodes(getOneFrom(forwardFromN));
		}
		return [ ];
	}
	
	// Given a node list, this will "split" the list so the first part contains the original
	// first node and any children of this node, while the second part contains the remainder
	// of the list.
	tuple[list[CFGNode],list[CFGNode]] splitNodeList(list[CFGNode] nl) {
		nLabels = { n@lab | /Expr n := nl[0], (n@lab)? }; // The labels of all subnodes, including the label of nl itself
		return < [ n | n <- nl, n@lab in nLabels ], [ n | n <- nl, n@lab notin nLabels ] >; 
	}
	
	// Get the top nodes from the node list. We do this by splitting it, as above, and taking
	// the first node from the first part of each split, which is the parent of the rest of
	// the nodes in the first part. We do this until the second part is empty, which means
	// we have no nodes yet to process.
	set[CFGNode] getTopNodes(list[CFGNode] nl) {
		set[CFGNode] res = { };
		while(size(nl) > 0) {
			< bl, nl > = splitNodeList(nl);
			res += bl[0];
		}
		return res;
	}
	
	// For each starting expression, figure out which other nodes will be collapsed into it
	map[CFGNode,list[CFGNode]] collapseNodes = ( );
	for (e <- startingExps) {
		collapseNodes[e] = e + chaseNodes(e);
	}

	// Get the top nodes -- e.g., for (a+b)*c, we would actually have nodes for a, b, a+b, c, and
	// (a+b)*c, and we only want to keep the last one of these.	
	topNodes = { *getTopNodes(reverse(collapseNodes[e])) | e <- collapseNodes };
	topNodeLabels = { e@lab | e <- topNodes, (e@lab)? };
		
	// For each of these nodes, we remove any child nodes from the graph and move any edges that
	// point to children of this node to instead point to the top node.
	redirectMap = ( n@lab : tn@lab | tn <- topNodes, /Expr n := tn, (n@lab)?, n@lab != tn@lab, n@lab notin topNodeLabels );
	newNodes = { n | n <- g.nodes, n@lab notin redirectMap };
	newEdges = { e | e <- g.edges, e.from notin redirectMap, e.to notin redirectMap } +
			   { e[to=redirectMap[e.to]] | e <- g.edges, e.from notin redirectMap, e.to in redirectMap };
			   
	return g[nodes=newNodes][edges=newEdges];	 
}

@doc{Remove expression nodes that are children of statement nodes}
public CFG removeChildExpressions(CFG g) {
	g = collapseExpressions(g);
	backwards = invert(cfgAsGraph(g));
	
	stmtLabels = ( s@lab : { e@lab | /Expr e := s } | s <- g.nodes, s is stmtNode );
	
	solve(backwards) {
		redirectMap = ( e@lab : s@lab | < s, e > <- backwards, s@lab in stmtLabels, e@lab in stmtLabels[s@lab] );
		newNodes = { n | n <- g.nodes, n@lab notin redirectMap };
		newEdges = { e | e <- g.edges, e.from notin redirectMap, e.to notin redirectMap } +
				   { e[to=redirectMap[e.to]] | e <- g.edges, e.from notin redirectMap, e.to in redirectMap };
		g = g[nodes=newNodes][edges=newEdges];
		backwards = invert(cfgAsGraph(g));
	}
	
	return g;
}
