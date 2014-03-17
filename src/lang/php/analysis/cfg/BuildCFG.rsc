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
import Exception;

// TODOs:
// 2. Gotos need to be handled by keeping track of which nodes are
//    related to which labels, and then linking these up appropriately.
//    For now, gotos just fall through to the next statement.
//
// 3. Throw statements should be linked to surrounding catch clauses.
//
// 4. Initializations of properties in classes, and of parameters with
//    defaults, both need to be accounted for in the control flow graph.
//    For the first, this should be done by moving the initializations
//    into the constructor (if it exists) or adding a constructor (if
//    needed). For the second, this should be done by adding these as
//    possible assignments coming out of the entry node for the method.

@doc{Build the CFGs for a single PHP file, given as a location}
public map[NamePath,CFG] buildCFGs(loc l) {
	return buildCFGs(loadPHPFile(l));
}

@doc{Build the CFGs for a PHP script, returning both the CFGs and the labeled script.}
public tuple[Script scr, map[NamePath,CFG] cfgs] buildCFGsAndScript(Script scr) {
	lstate = newLabelState();
	< scrLabeled, lstate > = labelScript(scr, lstate);
	
	map[NamePath,CFG] res = ( );

	println("Creating CFG for top-level script");
	< scriptCFG, lstate > = createScriptCFG(scrLabeled, lstate);
	res[[global()]] = scriptCFG;
		
	for (/class(cname,_,_,_,mbrs) := scrLabeled, m:method(mname,_,_,params,body) <- mbrs) {
		methodNamePath = [class(cname),method(mname)];
		println("Creating CFG for <cname>::<mname>");
		< methodCFG, lstate > = createMethodCFG(methodNamePath, m, lstate);
		res[methodNamePath] = methodCFG;
	}

	for (/f:function(fname,_,params,body) := scrLabeled) {
		functionNamePath = [global(),function(fname)];
		println("Creating CFG for <fname>");
		< functionCFG, lstate > = createFunctionCFG(functionNamePath, f, lstate);
		res[functionNamePath] = functionCFG;
	}
	 
	return < scrLabeled, res >;
}

@doc{Build just the CFGs for a PHP script}
public map[NamePath,CFG] buildCFGs(Script scr) = buildCFGsAndScript(scr).cfgs;

@doc{Strip the label annotations off of the nodes in the script.}
public Script stripLabels(Script scr) {
	str labAnno = "lab";
	return visit(scr) {
		case Expr e => delAnnotation(e, labAnno) when (e@lab)?
		case Stmt s => delAnnotation(s, labAnno) when (s@lab)?
	}
}

@doc{This is similar to buildCFGs, but also collapses nodes into basic blocks. Note: we may start doing this by default.}
public map[NamePath,CFG] buildCFGsAndBlocks(loc l) {
	return buildCFGsAndBlocks(loadPHPFile(l));
}

@doc{This is similar to buildCFGs, but also collapses nodes into basic blocks. Note: we may start doing this by default.}
public map[NamePath,CFG] buildCFGsAndBlocks(Script scr) {
	map[NamePath,CFG] res = buildCFGs(scr);
	for (np <- res) res[np] = createBasicBlocks(res[np]);
	return res;
}

@doc{Retrieve all method declarations from a script.}
public map[NamePath, ClassItem] getScriptMethods(Script scr) =
	( [class(cname),method(mname)] : m | /class(cname,_,_,_,mbrs) := scr, m:method(mname,_,_,params,body) <- mbrs );

// TODO: It is possible in PHP to have non-unique or conditional declarations. We may need a way to represent
// that here, assuming we ever run across it.

@doc{Retrieve all function declarations from a script. Note: this assumes that definitions are unique.}
public map[NamePath, Stmt] getScriptFunctions(Script scr) =
	( [global(),function(fname)] : f | /f:function(fname,_,_,_) := scr );

public tuple[CFG scriptCFG, LabelState lstate] createScriptCFG(Script scr, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	cfgEntryNode = scriptEntry()[@lab=incLabel()];
	cfgExitNode = scriptExit()[@lab=incLabel()];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

	if (script(list[Stmt] b) !:= scr)
		return < cfg([global()], lstate.nodes, { }, cfgEntryNode, cfgExitNode), lstate >;
	
	scriptBody = scr.body;
	
	// Add all the statements and expressions as CFG nodes
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := scriptBody };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := scriptBody };
	
	set[FlowEdge] edges = { };
	for (b <- scriptBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, scriptBody);
	if (size(scriptBody) > 0) {
		edges += flowEdge(cfgEntryNode@lab, init(head(scriptBody)));
		edges += flowEdge(final(last(scriptBody)), cfgExitNode@lab);
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}
	nodes = lstate.nodes;
	lstate = shrink(lstate);

	//< nodes, edges, lstate > = addJoinNodes(nodes, edges, lstate);
	
	// Adding CFG nodes for the expressions and statements above added in all
	// the nested nodes from inside functions and methods as well. Here, we
	// discard these.
	labels = { e.from, e.to | e <- edges };
	nodes = { n | n <- nodes, n@lab in labels };
	
 	return < cfg([global()], nodes, edges, cfgEntryNode, cfgExitNode), lstate >;   
}

public tuple[CFG methodCFG, LabelState lstate] createMethodCFG(NamePath np, ClassItem m, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	cfgEntryNode = methodEntry(np[0].className, np[1].methodName)[@lab=incLabel()];
	cfgExitNode = methodExit(np[0].className, np[1].methodName)[@lab=incLabel()];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

    methodBody = m.body;
	
	// Add all the statements and expressions as CFG nodes
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := methodBody };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := methodBody };
	
	// Add any initializer expressions from the parameters as CFG nodes
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := m.params };
	
	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	notProvided = [ actualNotProvided(pn, e, br)[@lab=incLabel()] | param(pn,someExpr(e),_,br) <- m.params ];
	lstate.nodes += toSet(notProvided);

	set[FlowEdge] edges = { };
	for (b <- methodBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, methodBody);

	for (npi <- notProvided) edges += flowEdge(npi@lab, init(npi.expr));
	for ([_*,np1,np2,_*] := notProvided) edges += flowEdge(final(np1.expr), np2@lab);

	// Wire up the entry, exit, default init, and body nodes.
	if (size(notProvided) > 0) {
		edges += flowEdge(cfgEntryNode@lab, head(notProvided)@lab);
		if (size(methodBody) > 0) {
			edges += flowEdge(final(last(notProvided).expr), init(head(methodBody)));
			edges += flowEdge(final(last(methodBody)), cfgExitNode@lab);
		} else {
			edges += flowEdge(final(last(notProvided).expr), cfgExitNode@lab);
		}
	} else if (size(methodBody) > 0) {
		edges += flowEdge(cfgEntryNode@lab, init(head(methodBody)));
		edges += flowEdge(final(last(methodBody)), cfgExitNode@lab);
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}

	nodes = lstate.nodes;
	lstate = shrink(lstate);

 	return < cfg(np, nodes, edges, cfgEntryNode, cfgExitNode), lstate >;   
}

public tuple[CFG functionCFG, LabelState lstate] createFunctionCFG(NamePath np, Stmt f, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	cfgEntryNode = functionEntry(np[1].functionName)[@lab=incLabel()];
	cfgExitNode = functionExit(np[1].functionName)[@lab=incLabel()];
	lstate = addEntryAndExit(lstate, cfgEntryNode, cfgExitNode);

    functionBody = f.body;
	
	// Add all the statements and expressions as CFG nodes
	lstate.nodes += { stmtNode(s, s@lab)[@lab=s@lab] | /Stmt s := functionBody };
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := functionBody };
	
	// Add any initializer expressions from the parameters as CFG nodes
	lstate.nodes += { exprNode(e, e@lab)[@lab=e@lab] | /Expr e := f.params };
	
	// Add initial nodes to represent initializing parameters with default values,
	// plus add flow edges between these default initializers
	notProvided = [ actualNotProvided(pn, e, br)[@lab=incLabel()] | param(pn,someExpr(e),_,br) <- f.params ];
	lstate.nodes += toSet(notProvided);

	set[FlowEdge] edges = { };
	for (b <- functionBody) < edges, lstate > = addStmtEdges(edges, lstate, b);
	< edges, lstate > = addBodyEdges(edges, lstate, functionBody);

	for (npi <- notProvided) edges += flowEdge(npi@lab, init(npi.expr));
	for ([_*,np1,np2,_*] := notProvided) edges += flowEdge(final(np1.expr), np2@lab);
	
	// Wire up the entry, exit, default init, and body nodes.
	if (size(notProvided) > 0) {
		edges += flowEdge(cfgEntryNode@lab, head(notProvided)@lab);
		if (size(functionBody) > 0) {
			edges += flowEdge(final(last(notProvided).expr), init(head(functionBody)));
			edges += flowEdge(final(last(functionBody)), cfgExitNode@lab);
		} else {
			edges += flowEdge(final(last(notProvided).expr), cfgExitNode@lab);
		}
	} else if (size(functionBody) > 0) {
		edges += flowEdge(cfgEntryNode@lab, init(head(functionBody)));
		edges += flowEdge(final(last(functionBody)), cfgExitNode@lab);
	} else {
		edges += flowEdge(cfgEntryNode@lab, cfgExitNode@lab);
	}

	nodes = lstate.nodes;
	lstate = shrink(lstate);

 	return < cfg(np, nodes, edges, cfgEntryNode, cfgExitNode), lstate >;   
}

// Find the initial label for each statement. In the case of a statement with
// children, this is the label of the first child that is executed. If the 
// statement is instead viewed as a whole (e.g., a break with no children, or
// a class definition, which is treated as an unevaluated unit), the initial
// label is the label of the statement itself.
public Lab init(Stmt s) {
	switch(s) {
		// If the break statement has an expression, that is the first thing that occurs in
		// the statement. If not, the break itself is the first thing that occurs.
		case \break(someExpr(Expr e)) : return init(e);
		case \break(noExpr()) : return s@lab;

		// A class def is treated as a unit. Individual methods contained inside have their
		// own control flow graphs.
		case classDef(_) : return s@lab;

		// Given a list of constants, the first thing that occurs is the expression that is
		// assigned to the first constant in the list.
		case const(list[Const] consts) : {
			if (!isEmpty(consts)) 
				return init(head(consts).constValue);
			throw "Unexpected AST node: the list of consts should not be empty";
		}

		// If the continue statement has an expression, that is the first thing that occurs in
		// the statement. If not, the continue itself is the first thing that occurs.
		case \continue(someExpr(Expr e)) : return init(e);
		case \continue(noExpr()) : return s@lab;

		// Given a declaration list, the first thing that occurs is the expression in the first declaration.
		case declare(list[Declaration] decls, _) : {
			if (!isEmpty(decls))
				return init(head(decls).val);
			throw "Unexpected AST node: the list of declarations should not be empty";
		}

		// For a do/while loop, the first body statement is the first thing to occur. If the body
		// is empty, the condition is the first thing that happens.
		case do(Expr cond, list[Stmt] body) : return isEmpty(body) ? init(cond) : init(head(body));

		// Given an echo statement, the first expression in the list is the first thing that occurs.
		// If this list is empty (this may be an error, TODO: Check to see if this can happen), the
		// statement itself is the first thing.
		case echo(list[Expr] exprs) : return isEmpty(exprs) ? s@lab : init(head(exprs));

		// An expression statement is just an expression treated as a statement; just check the
		// expression.
		case exprstmt(Expr expr) : return init(expr);

		// The various parts of the for are optional, so we check in the following order to find
		// the first item: first inits, than conds, than body, than exprs (which fire after the
		// body is evaluated).
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			if (!isEmpty(inits)) {
				return init(head(inits));
			} else if (!isEmpty(conds)) {
				return init(head(conds));
			} else if (!isEmpty(body)) {
				return init(head(body));
			} else if (!isEmpty(exprs)) {
				return init(head(exprs));
			}
			return s@lab;
		}

		// In a foreach loop, the array expression is required and is the first thing that is evaluated.
		case foreach(Expr arrayExpr, _, _, _, _) : return init(arrayExpr);

		// A function declaration is treated as a unit.
		case function(_, _, _, _) : return s@lab;

		// In a global statement, the first expression to be made global is the first item.
		case global(list[Expr] exprs) : {
			if (!isEmpty(exprs))
				return init(head(exprs));
			throw "Unexpected AST node: the list of globals should not be empty";
		}

		// A goto is a unit.
		case goto(_) : return s@lab;

		// Halt compiler is a unit.
		case haltCompiler(_) : return s@lab;

		// In a conditional, the condition is the first thing that occurs.
		case \if(Expr cond, _, _, _) : return init(cond);

		// Inline HTML is a unit.
		case inlineHTML(_) : return s@lab;

		// An interface definition is a unit.
		case interfaceDef(_) : return s@lab;

		// A trait definition is a unit.
		case traitDef(_) : return s@lab;

		// A label is a unit.
		case label(_) : return s@lab;

		// If the namespace has a body, the first thing that occurs is the first item in the
		// body; if not, the namespace declaration itself provides the first label.
		case namespace(_, list[Stmt] body) : return isEmpty(body) ? s@lab : init(head(body));

		// A namespace without a body is a unit
		case namespaceHeader(_) : return s@lab;
		
		// In a return, if we have an expression it provides the first label; if not, the
		// statement itself does.
		case \return(someExpr(Expr returnExpr)) : return init(returnExpr);
		case \return(noExpr()) : return s@lab;

		// In a static declaration, the first initializer provides the first label. If we
		// have no initializers, than the statement itself provides the label.
		case static(list[StaticVar] vars) : {
			initializers = [ e | staticVar(str name, someExpr(Expr e)) <- vars ];
			if (isEmpty(initializers))
				return s@lab;
			else
				return init(head(initializers));
		}

		// In a switch statement, the condition provides the first label.
		case \switch(Expr cond, _) : return init(cond);

		// In a throw statement, the expression to throw provides the first label.
		case \throw(Expr expr) : return init(expr);

		// In a try/catch, the body provides the first label. If the body is empty, we
		// just use the label from the statement (the catch clauses would never fire, since
		// nothing could trigger them in an empty body).
		case tryCatch(list[Stmt] body, _) : return isEmpty(body) ? s@lab : init(head(body));

		// In a try/catch, the body provides the first label. If the body is empty, we
		// check the finally clause. If that is empty as well, we use the statement.
		case tryCatchFinally(list[Stmt] body, _, list[Stmt] finallyBody) : {
			if (isEmpty(body)) {
				if (isEmpty(finallyBody)) {
					return s@lab;
				} else {
					return init(head(finallyBody));
				}	
			} else {
				return init(head(body));
			}
		}

		// In an unset, the first expression to unset provides the first label. If the list is
		// empty, the statement itself provides the label.
		case unset(list[Expr] unsetVars) : return isEmpty(unsetVars) ? s@lab : init(head(unsetVars));

		// A use statement is atomic.
		case use(_) : return s@lab;

		// In a while loop, the while condition is executed first and thus provides the first label.
		case \while(Expr cond, _) : return init(cond);	
		
		// An empty statement is atomic
		case emptyStmt() : return s@lab;
		
		// In a block, the first statement provides the first label. If there is no body,
		// the statement itself provides the label.
		case block(list[Stmt] body) : return isEmpty(body) ? s@alb : init(head(body));
	}
}

// Find the initial label for each expression. In the case of an expression with
// children, this is the label of the first child that is executed. If the 
// expression is instead viewed as a whole (e.g., a scalar, or a variable
// lookup), the initial label is the label of the expression itself.
public Lab init(Expr e) {
	switch(e) {
		case array(list[ArrayElement] items) : {
			if (size(items) == 0) {
				return e@lab;
			} else if (arrayElement(someExpr(Expr key), Expr val, bool byRef) := head(items)) {
				return init(key);
			} else if (arrayElement(noExpr(), Expr val, bool byRef) := head(items)) {
				return init(val);
			}
		}
		
		case fetchArrayDim(Expr var, OptionExpr dim) : return init(var);
		
		case fetchClassConst(name(Name className), str constName) : return e@lab;
		case fetchClassConst(expr(Expr className), str constName) : return init(className);
		
		case assign(Expr assignTo, Expr assignExpr) : return init(assignExpr);
		
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) : return init(assignExpr);
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) : return init(assignExpr);
		
		case refAssign(Expr assignTo, Expr assignExpr) : return init(assignExpr);
		
		case binaryOperation(Expr left, Expr right, Op operation) : return init(left);
		
		case unaryOperation(Expr operand, Op operation) : return init(operand);
		
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			if (expr(Expr cname) := className)
				return init(cname);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			return e@lab;
		}
		
		case cast(CastType castType, Expr expr) : return init(expr);
		
		case clone(Expr expr) : return init(expr);
		
		case closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static) : return e@lab;
		
		case fetchConst(Name name) : return e@lab;
		
		case empty(Expr expr) : return init(expr);
		
		case suppress(Expr expr) : return init(expr);
		
		case eval(Expr expr) : return init(expr);
		
		case exit(someExpr(Expr exitExpr)) : return init(exitExpr);
		case exit(noExpr()) : return e@lab;
		
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			if (expr(Expr fname) := funName)
				return init(fname);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			return e@lab;
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			return init(target);
		}
		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			if (expr(Expr sname) := staticTarget)
				return init(sname);
			else if (expr(Expr mname) := methodName)
				return init(mname);
			else if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			return e@lab;
		}
		
		case include(Expr expr, IncludeType includeType) : return init(expr);
		
		case instanceOf(Expr expr, NameOrExpr toCompare) : return init(expr);
		
		case isSet(list[Expr] exprs) : {
			if (size(exprs) > 0)
				return init(head(exprs));
			return e@lab;
		}
		
		case print(Expr expr) : return init(expr);
		
		case propertyFetch(Expr target, NameOrExpr propertyName) : return init(target);
		
		case shellExec(list[Expr] parts) : {
			if (size(parts) > 0)
				return init(head(parts));
			return e@lab;
		}
		
		case ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch) : return init(cond);
		
		case staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName) : {
			if (expr(Expr cname) := className)
				return init(cname);
			else if (expr(Expr pname) := propertyName)
				return init(pname);
			return e@lab;
		}
		
		case scalar(encapsed(parts)) : return init(head(parts));
		case scalar(Scalar scalarVal) : return e@lab;
		
		case var(expr(Expr varName)) : return init(varName);
		case var(name(Name varName)) : return e@lab;
		
		case yield(someExpr(key), _) : return init(key);
		case yield(noExpr(), someExpr(val)) : return init(val);
		case yield(noExpr(), noExpr()) : return e@lab;
		
		case listExpr(exprs) : {
			actualExprs = [ ei | someExpr(ei) <- exprs ];
			return isEmpty(actualExprs) ? e@lab : init(head(actualExprs));
		}
	}
}

// Compute the final label in a statement or expression -- i.e., the final
// "thing" done in that statement or expression.
//
// For now, we make a simplifying assumption to compute the final label of
// a statement or expression -- the final thing done is actually to evaluate,
// as a whole, the entire statement or expression. So, the final label is always
// the label of the entire expression or statement.
//
// For instance, given expression
//
//	a + b
//
// we would evaluate a, then b, then a + b, so a + b is the final label. This is
// also done with statements currently.
//
// Is this always correct? Technically, if we know we have a jump in an expression
// that will always fire, isn't truly the final reachable label. We handle this
// when we wire up nodes below in the statementJumps check.
public Lab final(Stmt s) = s@lab;
public Lab final(Expr e) = e@lab;

@doc{Add internal edges between subexpressions of an expression.}
public tuple[FlowEdges, LabelState] addExpEdges(FlowEdges edges, LabelState lstate, Expr e) {
	< eedges, lstate > = internalFlow(e, lstate);
	return < edges + eedges, lstate >;
}

@doc{Add internal edges between internal expressions and statements of a statement.}
public tuple[FlowEdges, LabelState] addStmtEdges(FlowEdges edges, LabelState lstate, Stmt s) {
	< sedges, lstate > = internalFlow(s, lstate);
	return < edges + sedges, lstate >;
}

public tuple[FlowEdges, LabelState] addBodyEdges(FlowEdges edges, LabelState lstate, list[Stmt] body) {
	// Connect the adjacent statements in a statement body. We take care of exceptional control flow
	// when we handle a specific statement in internalFlow, so here we just are deciding whether to
	// link a statement to the statement that follows it. For instance, a return statement will not
	// be linked to its successor, since it will always go to the current exit node. We add that label
	// in internalFlow, so all we do here is just not add a link from the return statement to the
	// statement that follows it.
	for ([_*,b1,b2,_*] := body, !statementJumps(b1)) edges += flowEdge(final(b1),init(b2));
	return < edges, lstate >;
}

public tuple[FlowEdges, LabelState] addExpSeqEdges(FlowEdges edges, LabelState lstate, list[Expr] exps) {
	for ([_*,e1,e2,_*] := exps) edges += flowEdge(final(e1),init(e2));
	return < edges, lstate >;
}

// Determine if a statement will flow to the following statement or will jump somewhere else.
// Note: this doesn't account for exceptional jumps, TODO: extra support is needed for that.
// Also, a yield does not count as a jump, since execution will pick up where it left off when
// the generator gets control back.
public bool statementJumps(Stmt s) = (s is \return) || (s is \break) || (s is \continue);

// Compute all the internal flow edges in a statement. This models the possible
// flows through the statement, for instance, from the conditional guard to the
// true and false bodies of the conditional and then (at the end) joining control
// flow back together. Currently, this is modelled by having the final label of
// each statement be the label of the entire statement itself, with all flow
// edges exiting to this final label for the given statement.
//
// Note: Currently, we always have the statements in the body linked one to
// the next. This will be patched elsewhere -- if we have a return, we should
// not have an edge going to the next statement, since it is no longer reachable.
public tuple[FlowEdges,LabelState] internalFlow(Stmt s, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	initLabel = init(s);
	finalLabel = final(s);
	FlowEdges edges = { };
	
	switch(s) {
		// TODO: For both break cases, what do we do if there is no surrounding
		// context to break to? The manual page for break mentions that this exits
		// the script, at least in the case where this occurs at the top level.
		case \break(someExpr(Expr e)) : {
			// Add the internal flow edges for the break expression, plus the
			// edge from the expression to the statement itself.
			< edges, lstate > = addExpEdges(edges, lstate, e);
			edges += flowEdge(final(e), finalLabel);
			
			// Link up the break. If we have no label, it is the same as
			// "break 1". If we have a numeric label, we jump based on
			// that. Else, we have to link up each possible break target.
			// NOTE: "break 0" is the same as "break 1", and is actually
			// no longer valid as of PHP 5.4.
			if (scalar(integer(int bl)) := e) {
				if (bl == 0) {
					println("WARNING: This program has a break 0, which is no longer valid as of PHP 5.4.");
					bl = 1;
				}
				if (hasBreakLabel(bl, lstate)) {
					edges += flowEdge(finalLabel, getBreakLabel(bl, lstate));
				} else {
					println("WARNING: This program breaks beyond the visible break nesting.");
					edges += flowEdge(finalLabel, getExitNodeLabel(lstate));
				}
			} else {
				println("WARNING: This program has a break to a non-literal expression. This is no longer allowed in PHP.");
				for (blabel <- getBreakLabels(lstate))
					edges += flowEdge(finalLabel, blabel);
			}
		}

		// This is the no label case (mentioned above), which is the same as
		// using "break 1".
		case \break(noExpr()) : {
			if (hasBreakLabel(1, lstate)) {
				try {
					edges += flowEdge(finalLabel, getBreakLabel(1, lstate));
				} catch EmptyList() : {
					println("WARNING: Even though we checked the list length it is empty!");
					edges += flowEdge(finalLabel, getExitNodeLabel(lstate));
				}
			} else {
				println("WARNING: This program breaks beyond the visible break nesting.");
				edges += flowEdge(finalLabel, getExitNodeLabel(lstate));
			}
		}

		// For consts, if we only have one const def, the flow is from that def to the final
		// statement label. If we have more than one, we have to construct edges between the
		// final label of each const and the first label of the next, plus from the final
		// constant to the statement label.
		case const(list[Const] consts) : {
			if (firstConst:const(_, firstValue) := head(consts), lastConst:const(_,lastValue) := last(consts)) {
				if (firstConst == lastConst) {
					< edges, lstate > = addExpEdges(edges, lstate, firstValue);
					edges += flowEdge(final(firstValue),finalLabel);
				} else {
					for (const(_,c) <- consts) < edges, lstate > = addExpEdges(edges, lstate, c);
					< edges, lstate > = addExpSeqEdges(edges, lstate, [ c | const(_,c) <- consts ]);
					edges += flowEdge(final(lastValue), finalLabel);
				}
			}
		}

		// TODO: For both continue cases, what do we do if there is no surrounding
		// context to continue to? The manual page for continue mentions that this exits
		// the script, at least in the case where this occurs at the top level.
		case \continue(someExpr(Expr e)) : {
			// Add the internal flow edges for the continue expression, plus the
			// edge from the expression to the statement itself.
			< edges, lstate > = addExpEdges(edges, lstate, e);
			edges += flowEdge(final(e), finalLabel);
			
			// Link up the continue. If we have no label, it is the same as
			// "continue 1". If we have a numeric label, we jump based on
			// that. Else, we have to link up each possible continue target.
			// NOTE: "continue 0" is the same as "continue 1", and is actually
			// no longer valid as of PHP 5.4.
			if (scalar(integer(int bl)) := e) {
				if (bl == 0) {
					println("WARNING: This program has a continue 0, which is no longer valid as of PHP 5.4.");
					bl = 1;
				}
				if (hasContinueLabel(bl, lstate)) {
					edges += flowEdge(finalLabel, getContinueLabel(bl, lstate));
				} else {
					println("WARNING: This program continues beyond the visible continue nesting.");
					edges += flowEdge(finalLabel, getExitNodeLabel(lstate));
				}
			} else {
				println("WARNING: This program has a continue to a non-literal expression. This is no longer allowed in PHP.");
				for (blabel <- getContinueLabels(lstate))
					edges += flowEdge(finalLabel, blabel);
			}
		}

		// This is the no label case (mentioned above), which is the same as
		// using "continue 1".
		case \continue(noExpr()) : {
			if (hasContinueLabel(1, lstate)) {
				edges += flowEdge(finalLabel, getContinueLabel(1, lstate));
			} else {
				println("WARNING: This program continues beyond the visible continue nesting.");
				edges += flowEdge(finalLabel, getExitNodeLabel(lstate));
			}
		}

		// For declarations, the flow is through the decl expressions, then through
		// the body, then to the label for this statement.
		case declare(list[Declaration] decls, list[Stmt] body) : {
			for (declaration(_,v) <- decls) < edges, lstate > = addExpEdges(edges, lstate, v);
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ v | declaration(v) <- decls ]);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			        
			if (size(decls) > 0 && size(body) > 0 && declaration(_,v) := last(decls) && b := head(body))
				edges += flowEdge(final(v),init(b));
			if (size(body) > 0 && b := last(body) && !statementJumps(b))
				edges += flowEdge(final(b),finalLabel);
			else if (size(decls) > 0 && declaration(_,v) := last(decls) && size(body) == 0)
				edges += flowEdge(final(v),finalLabel);
		}


		// For do/while loops, the flow is through the body, then through the condition,
		// then to both the statement label and the top of the body (backedge).		
		case do(Expr cond, list[Stmt] body) : {
			// Push the break and continue labels. If we break, we go to the end
			// of the statement. If we continue, we go to the condition instead.
			lstate = pushContinueLabel(init(cond), pushBreakLabel(finalLabel, lstate));
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);			

			if (size(body) > 0) {
				edges += conditionTrueFlowEdge(final(cond),init(head(body)),cond);
				if (!statementJumps(last(body)))
					edges += flowEdge(final(last(body)),init(cond));			
			} else {
				edges += conditionTrueflowEdge(final(cond), init(cond), cond);
			}
			edges += conditionFalseFlowEdge(final(cond),finalLabel,cond);
			
			lstate = popBreakLabel(popContinueLabel(lstate));
		} 

		// For echo, the flow is from left to right in the echo expressions, then to the
		// statement label.
		case echo(list[Expr] exprs) : {
			for (e <- exprs) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
		}

		// For the expression statement, the flow is from the expression to the statement label.
		case exprstmt(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}

		// Comments are given inline -- flow through a for is complex...
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			// If we break, we go to the end. If we continue, we go to the first condition,
			// unless we have none, then we just re-execute the body. If we have an empty
			// body, we just assign the final label, but this is just so we have something,
			// since, if the body is empty, we won't find a continue statement in it.
			lstate = pushBreakLabel(finalLabel, lstate);
			if (size(conds) > 0)
				lstate = pushContinueLabel(init(head(conds)), lstate);
			else if (size(body) > 0)
				lstate = pushContinueLabel(init(head(body)), lstate);
			else
				lstate = pushContinueLabel(finalLabel, lstate);

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
				edges += flowEdge(final(last(inits)),init(head(conds)));
			else if (size(inits) > 0 && size(body) > 0)
				edges += flowEdge(final(last(inits)),init(head(body)));
			else if (size(inits) > 0 && size(exprs) > 0)
				edges += flowEdge(final(last(inits)),init(head(exprs)));
			else if (size(inits) > 0)
				edges += flowEdge(final(last(inits)), finalLabel);
				
			// The forward edge from the last condition
			if (size(conds) > 0 && size(body) > 0)
				edges += conditionTrueFlowEdge(final(last(conds)), init(head(body)), conds);
			else if (size(conds) > 0 && size(exprs) > 0)
				edges += conditionTrueFlowEdge(final(last(conds)), init(head(exprs)), conds);
			else if (size(conds) > 0)
				edges += conditionTrueFlowEdge(final(last(conds)), finalLabel, conds);
				
			// The forward edge from the body
			if (size(body) > 0 && size(exprs) > 0)
				edges += flowEdge(final(last(body)), init(head(exprs)));
			else if (size(body) > 0 && size(conds) > 0)
				edges += flowEdge(final(last(body)), init(head(conds)));
			else if (size(body) > 0)
				edges += flowEdge(final(last(body)), finalLabel);
				
			// The loop backedge
			if (size(exprs) > 0 && size(conds) > 0)
				edges += flowEdge(final(last(exprs)), init(head(conds)));
			else if (size(exprs) > 0 && size(body) > 0)
				edges += flowEdge(final(last(exprs)), init(head(body)));
			else if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), init(head(exprs)));
			else if (size(conds) > 0)
				edges += flowEdge(final(last(conds)), init(head(conds)));
			else if (size(body) > 0)
				edges += flowEdge(final(last(body)), init(head(body)));
			else
				edges += flowEdge(finalLabel, finalLabel);
				
			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body) : {
			// The test to see if there are still elements in the array is implicit in the
			// control flow, we add this node as an explicit "check point". We also add an
			// edge from the check to the end of the statement, representing the case where
			// the array is exhausted.
			Lab newLabel = incLabel();
			Lab varLabel = incLabel(); 
			testNode = foreachTest(arrayExpr,newLabel)[@lab=newLabel];
			varNode = foreachAssignValue(asVar,varLabel)[@lab=varLabel];
			lstate.nodes = lstate.nodes + testNode + varNode;
			edges += iteratorEmptyFlowEdge(testNode@lab, finalLabel, arrayExpr);
			
			// Add in the edges for break and continue. Continue will go to the test node
			// that we just added, since that is (essentially) the condition. Break, as
			// usual, just goes to the end
			lstate = pushContinueLabel(testNode@lab, pushBreakLabel(finalLabel, lstate));
		
			// Calculate the internal flow of the array expression and var expression.
			< edges, lstate > = addExpEdges(edges, lstate, arrayExpr);
			< edges, lstate > = addExpEdges(edges, lstate, asVar);
			
			// Link the array expression to the test, it should go:
			// array expression -> test -> key var expression or var expression.
			edges = edges + flowEdge(final(arrayExpr), testNode@lab);

			// Add edges for each element of the body
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			
			// If we have a body, link the value expression to the body, then link the
			// body back around to the test. Else, just link the value to the test, this
			// would model the case where we just keep assigning new key/value pairs until
			// we exhaust the array.
			edges += flowEdge(final(asVar), varLabel);
			if (size(body) > 0) {
				edges += flowEdge(varLabel, init(head(body)));
				edges += flowEdge(final(last(body)), testNode@lab);
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
				edges += { iteratorNotEmptyFlowEdge(testNode@lab, init(keyexp), arrayExpr), flowEdge(final(keyexp),keyLabel), flowEdge(keyLabel,init(asVar)) };
			} else {
				edges += iteratorNotEmptyFlowEdge(testNode@lab, init(asVar), arrayExpr);
			}
			
			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case global(list[Expr] exprs) : {
			// Add edges for each expression in the list, plus add edges between
			// each adjacent expression.
			for (e <- exprs) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);

			// If we have at least one expression, add an edge from the last expression
			// to the end of the statement. If we have no expressions, this would add a
			// self-loop, so in that case we add no edge (the construct does not loop).
			if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
		}

		case \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause) : {
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
			if (size(body) > 0) {
				edges += conditionTrueFlowEdge(final(cond), init(head(body)), cond);
				if (!statementJumps(last(body))) edges += flowEdge(final(last(body)), finalLabel);
			} else {
				edges += conditionTrueFlowEdge(final(cond), finalLabel, cond);
			}

			// Next, we need the flow from condition to condition, and into
			// the bodies of each elseif.
			falseConds = [ cond ];
			for (elseIf(e,ebody) <- elseIfs) {
				// We have a false flow edge from the last condition to the current condition.
				// We can only get here if each prior condition was false.
				edges += conditionFalseFlowEdge(final(last(falseConds)), init(e), falseConds);

				// As above, we then flow from the condition (if it is true) into the body and then
				// through the body, or we just flow to the end if there is no body.
				if (size(ebody) > 0) {
					edges += conditionTrueFlowEdge(final(e), init(head(ebody)), e, falseConds);
					if (!statementJumps(last(ebody))) edges += flowEdge(final(last(ebody)), finalLabel);
				} else {
					edges += conditionTrueFlowEdge(final(e), finalLabel, e, falseConds);
				}
					
				falseConds += e;
			}
			
			// Finally, if we have an else, we model flow into and through the else. If we have
			// no else, we instead have to add edges from the last false condition directly to
			// the end.
			if (someElse(\else(ebody)) := elseClause) {
				if (size(ebody) > 0) {
					edges += conditionFalseFlowEdge(final(last(falseConds)), init(head(ebody)), falseConds);
					if (!statementJumps(last(ebody))) edges += flowEdge(final(last(ebody)), finalLabel);
				}				
			} else {
				edges += conditionFalseFlowEdge(final(last(falseConds)), finalLabel, falseConds);
			}
		}

		case namespace(OptionName nsName, list[Stmt] body) : {
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);

			if (size(body) > 0)
				edges += flowEdge(final(last(body)), finalLabel); 
		}		

		case \return(someExpr(expr)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += { flowEdge(final(expr), finalLabel), flowEdge(finalLabel, getExitNodeLabel(lstate)) };
		}

		case \return(noExpr()) : {
			edges = edges + flowEdge(finalLabel, getExitNodeLabel(lstate));
		}
		
		case static(list[StaticVar] vars) : {
			varExps = [ e | v:staticVar(str name, someExpr(Expr e)) <- vars ];
			for (e <- varExps) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, varExps);
			if (size(varExps) > 0)
				edges += flowEdge(final(last(varExps)), finalLabel); 
		}

		case \switch(Expr cond, list[Case] cases) : {
			// Both break and continue will go to the end of the statement, add the
			// labels here to account for any we find in the case bodies.
			lstate = pushContinueLabel(finalLabel,pushBreakLabel(finalLabel, lstate));
			
			// Add all the standard edges for the conditions and statement bodies			
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			for (\case(e,body) <- cases) {
				if (someExpr(ccond) := e) < edges, lstate > = addExpEdges(edges, lstate, ccond);
				for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
				< edges, lstate > = addBodyEdges(edges, lstate, body);
			}
						
			// Reorder the cases to make sure default cases are at the end
			nonDefaultCases = [ c | c:\case(someExpr(_),_) <- cases ];
			defaultCases = [ c | c:\case(noExpr(),_) <- cases ];
			
			if (size(defaultCases) > 1)
				println("WARNING: We should only have 1 default case, the others will not be tried (cases at lines <intercalate(",",["<c@at.begin.line>" | c <- defaultCases])>)");
			cases = nonDefaultCases + defaultCases;
			
			// Link the switch condition expression to the first case. For a non-default case, this
			// links to the condition. For a default case, this links to the body. If there is no
			// default body, this links directly to the end. Note: the only way the default case
			// will be first is if there are no non-default cases.
			if (size(cases) > 0 && \case(someExpr(e),b) := head(cases)) {
				edges += flowEdge(final(cond), init(e));
			} else if (size(cases) > 0 && \case(noExpr(),b) := head(cases) && size(b) > 0) {
				edges += flowEdge(final(cond), init(head(b)));
			} else {
				edges += flowEdge(final(cond), finalLabel);
			}
			
			// Link each case condition with the body of the case
			for (\case(someExpr(e),b) <- cases, size(b) > 0) edges += conditionTrueFlowEdge(final(e),init(head(b)),binaryOperation(cond,e,equal()));
			
			// If there is no body, instead link the case condition with the next case condition
			for ([_*,\case(someExpr(e),b),\case(someExpr(e2),b2),_*] := cases, size(b) == 0)
				edges += conditionTrueFlowEdge(final(e),init(e2),binaryOperation(cond,e,equal()));
			
			// Corner case, if the last non-default condition has no body, link it to the default body
			// (if there is one) or the final label
			if ([_*,\case(someExpr(e),b),\case(noExpr(),b2),_*] := cases, size(b) == 0) {
				if (size(b2) == 0)
					edges += conditionTrueFlowEdge(final(e),finalLabel,binaryOperation(cond,e,equal()));
				else
					edges += conditionTrueFlowEdge(final(e),init(head(b2)),binaryOperation(cond,e,equal()));
			}
			
			// For each case, link together the case condition with the next case condition, representing
			// the situation where the case condition is tried but fails.  This also has the same corner
			// case as above, for transferring control to the default, plus a case where there is no default.
			edges += { conditionFalseFlowEdge(final(e1),init(e2),binaryOperation(cond,e1,equal())) | [_*,\case(someExpr(e1),b1),\case(someExpr(e2),b2),_*] := cases};
			if ([_*,\case(someExpr(e1),b1),\case(noExpr(),b2),_*] := cases) {
				if (size(b2) > 0)
					edges += conditionFalseFlowEdge(final(e1),init(head(b2)),binaryOperation(cond,e1,equal()));
				else
					edges += conditionFalseFlowEdge(final(e1),finalLabel,binaryOperation(cond,e1,equal()));
			}
			if ([_*,\case(someExpr(e1),b1)] := cases)
				edges += conditionFalseFlowEdge(final(e1), finalLabel, binaryOperation(cond,e1,equal()));
			
			// For each case, link together the last body element with the final label or, if the
			// body is empty, link together the case condition with the final label
			for (\case(e,b) <- cases, size(b) > 0, !statementJumps(last(b))) edges += flowEdge(final(last(b)), finalLabel);
			for (\case(someExpr(e),b) <- cases, size(b) == 0) edges += flowEdge(final(e), finalLabel);

			lstate = popBreakLabel(popContinueLabel(lstate));
		}

		case \throw(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			// TODO: This actually needs to instead transfer control to surrounding catches
			edges += flowEdge(final(expr), finalLabel);
		}

		case tryCatch(list[Stmt] body, list[Catch] catches) : {
			// Add all the standard internal edges for the statements in the body
			// and in the catch bodies. 
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			for (\catch(_, _, cbody) <- catches, b <- cbody) < edges, lstate > = addStmtEdges(edges, lstate, b);
			for (\catch(_, _, cbody) <- catches) < edges, lstate > = addBodyEdges(edges, lstate, cbody);

			// Link the end of the main body, and each catch body, to the final label. Note: there
			// is no flow from the standard body to the exception bodies added by default, it is added
			// for throws.
			// TODO: Add the links that would be triggered by expressions -- e.g., a method call could
			// trigger an exception that is caught here. We need to look at the best way to do this without
			// degrading to just having exception edges from each expression.
			if (size(body) > 0 && !statementJumps(last(body)))
				edges += flowEdge(final(last(body)), finalLabel);
			for (\catch(_, _, cbody) <- catches, size(cbody) > 0, !statementJumps(last(cbody)))
				edges += flowEdge(final(last(cbody)), finalLabel);
				
			// TODO: Anything else here?
		}

		case unset(list[Expr] unsetVars) : {
			for (e <- unsetVars) < edges, lstate > = addExpEdges(edges, lstate, e);
			< edges, lstate > = addExpSeqEdges(edges, lstate, unsetVars);
		}

		case \while(Expr cond, list[Stmt] body) : {
			lstate = pushContinueLabel(init(cond), pushBreakLabel(finalLabel, lstate));
			
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);

			edges += conditionFalseFlowEdge(final(cond), finalLabel, cond);
				    
			if (size(body) > 0) {
				edges += { conditionTrueFlowEdge(final(cond), init(head(body)), cond), flowEdge(final(last(body)), init(cond)) };
			} else {
				edges += conditionTrueFlowEdge(final(cond), init(cond), cond);
			}
			
			lstate = popContinueLabel(popBreakLabel(lstate));
		}
		
		case block(list[Stmt] body) : {
			for (b <- body) < edges, lstate > = addStmtEdges(edges, lstate, b);
			< edges, lstate > = addBodyEdges(edges, lstate, body);
			if (size(body) > 0) {
				edges += flowEdge(final(last(body)), finalLabel);
			}		
		}
	}
	
	return < edges, lstate >;
}

// Compute all the internal flow edges for an expression. We pass around the label
// state in case we need to construct new labels.
public tuple[FlowEdges,LabelState] internalFlow(Expr e, LabelState lstate) {
	initLabel = init(e);
	finalLabel = final(e);
	FlowEdges edges = { };
	
	switch(e) {
		case array(list[ArrayElement] items) : {
			for (arrayElement(OptionExpr okey, Expr val, bool byRef) <- items) {
				< edges, lstate > = addExpEdges(edges, lstate, val);
				if (someExpr(Expr key) := okey)
					< edges, lstate > = addExpEdges(edges, lstate, key);
			}

			for (arrayElement(someExpr(kv),v1,_) <- items)
					edges += flowEdge(final(kv), init(v1));

			for ([_*,arrayElement(k1,v1,_),arrayElement(k2,v2,_),_*] := items) {
				if (someExpr(kv) := k2)
					edges += flowEdge(final(v1), init(kv));
				else
					edges += flowEdge(final(v1), init(v2));
			}

			if (size(items) > 0, arrayElement(_,val,_) := last(items))
				edges += flowEdge(final(val), finalLabel);
		}
		
		case fetchArrayDim(Expr var, someExpr(Expr dim)) : {
			< edges, lstate > = addExpEdges(edges, lstate, var);
			< edges, lstate > = addExpEdges(edges, lstate, dim);
			edges = edges + flowEdge(final(var), init(dim)) + flowEdge(final(dim),finalLabel);
		}
		
		case fetchArrayDim(Expr var, noExpr()) : {
			< edges, lstate > = addExpEdges(edges, lstate, var);
			edges += flowEdge(final(var), finalLabel);
		}
		
		case fetchClassConst(expr(Expr className), str constName) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			edges += flowEdge(final(className), finalLabel);
		}
		
		case assign(Expr assignTo, Expr assignExpr) : { 
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			edges = edges + flowEdge(final(assignExpr), init(assignTo)) + flowEdge(final(assignTo), finalLabel);
		}
		
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			edges = edges + flowEdge(final(assignExpr), init(assignTo)) + flowEdge(final(assignTo), finalLabel);
		}
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr);

			listExps = reverse([le|someExpr(le) <- assignsTo]);
			for (le <- listExps) < edges, lstate > = addExpEdges(edges, lstate, le);
			< edges, lstate > = addExpSeqEdges(edges, lstate, listExps);
			
			if (size(listExps) > 0)
				edges += flowEdge(final(last(listExps)), finalLabel);
			else
				edges += flowEdge(final(assignExpr), finalLabel);
		}
		
		case refAssign(Expr assignTo, Expr assignExpr) : {
			< edges, lstate > = addExpEdges(edges, lstate, assignTo);
			< edges, lstate > = addExpEdges(edges, lstate, assignExpr); 
			edges = edges + flowEdge(final(assignExpr), init(assignTo)) + flowEdge(final(assignTo), finalLabel);
		}
		
		case binaryOperation(Expr left, Expr right, Op operation) : { 
			< edges, lstate > = addExpEdges(edges, lstate, left);
			< edges, lstate > = addExpEdges(edges, lstate, right);
			edges = edges + flowEdge(final(left), init(right)) + flowEdge(final(right), finalLabel);
		}
		
		case unaryOperation(Expr operand, Op operation) : {
			< edges, lstate > = addExpEdges(edges, lstate, operand); 
			edges = edges + flowEdge(final(operand), finalLabel);
		}
		
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);

			if (expr(Expr cn) := className) {
				< edges, lstate > = addExpEdges(edges, lstate, cn);
				if (size(parameters) > 0) {
					edges += flowEdge(final(cn), init(head(parameters).expr));
					edges += flowEdge(final(last(parameters).expr), finalLabel);
				} else {
					edges += flowEdge(final(cn), finalLabel);
				}
			} else if (size(parameters) > 0) {
				edges += flowEdge(final(last(parameters).expr), finalLabel);
			}
		}
		
		case cast(CastType castType, Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case clone(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case empty(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case suppress(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case eval(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case exit(someExpr(Expr exitExpr)) : {
			< edges, lstate > = addExpEdges(edges, lstate, exitExpr);
			edges += flowEdge(final(exitExpr), finalLabel);
		}
		
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);
		
			if (expr(Expr fn) := funName) {
				< edges, lstate > = addExpEdges(edges, lstate, fn);
				if (size(parameters) > 0) {
					edges += flowEdge(final(fn), init(head(parameters).expr));
					edges += flowEdge(final(last(parameters).expr),finalLabel);
				} else {
					edges += flowEdge(final(fn),finalLabel);
				}
			} else {
				if (size(parameters) > 0)
					edges += flowEdge(final(last(parameters).expr), finalLabel);
			}
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);

			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);
			
			if (expr(Expr mn) := methodName) {
				< edges, lstate > = addExpEdges(edges, lstate, mn);
				edges += flowEdge(final(target),init(mn));
				if (size(parameters) > 0) {
					edges += flowEdge(final(mn),init(head(parameters).expr));
				} else {
					edges += flowEdge(final(mn), finalLabel);
				}
			} else {
				if (size(parameters) > 0) {
					edges += flowEdge(final(target), init(head(parameters).expr));
				} else {
					edges += flowEdge(final(target), finalLabel);
				}
			}
		}

		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			for (actualParameter(aexp,_) <- parameters) < edges, lstate > = addExpEdges(edges, lstate, aexp);
			< edges, lstate > = addExpSeqEdges(edges, lstate, [ae|actualParameter(ae,_) <- parameters]);

			if (expr(Expr tn) := staticTarget) {
				< edges, lstate > = addExpEdges(edges, lstate, tn);
				if (expr(Expr mn) := methodName)
					edges += flowEdge(final(tn),init(mn));
				else if (size(parameters) > 0)
					edges += flowEdge(final(tn),init(head(parameters).expr));
				else
					edges += flowEdge(final(tn),finalLabel);
			}

			if (expr(Expr mn) := methodName) {
				< edges, lstate > = addExpEdges(edges, lstate, mn);
				if (size(parameters) > 0)
					edges += flowEdge(final(mn),init(head(parameters).expr));
				else
					edges += flowEdge(final(mn),finalLabel);
			}

			if (size(parameters) > 0) {
				edges += flowEdge(final(last(parameters).expr), finalLabel);
			}

		}

		
		case include(Expr expr, IncludeType includeType) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case instanceOf(Expr expr, expr(Expr toCompare)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			< edges, lstate > = addExpEdges(edges, lstate, toCompare);
			edges = edges + flowEdge(final(expr),init(toCompare)) + flowEdge(final(toCompare),finalLabel);
		}
		
		case instanceOf(Expr expr, name(Name toCompare)) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}

		case isSet(list[Expr] exprs) : {
			for (ex <- exprs) < edges, lstate > = addExpEdges(edges, lstate, ex);
			< edges, lstate > = addExpSeqEdges(edges, lstate, exprs);
			if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
		}
		
		case print(Expr expr) : {
			< edges, lstate > = addExpEdges(edges, lstate, expr);
			edges += flowEdge(final(expr), finalLabel);
		}
		
		case propertyFetch(Expr target, expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges = edges + flowEdge(final(target),init(propertyName)) + flowEdge(final(propertyName),finalLabel);
		}
		
		case propertyFetch(Expr target, name(Name propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, target);
			edges += flowEdge(final(target), finalLabel);
		}

		case shellExec(list[Expr] parts) : {
			for (ex <- parts) < edges, lstate > = addExpEdges(edges, lstate, ex);
			< edges, lstate > = addExpSeqEdges(edges, lstate, parts);
			if (size(parts) > 0)
				edges += flowEdge(final(last(parts)), finalLabel);
		}

		case ternary(Expr cond, someExpr(Expr ifBranch), Expr elseBranch) : {
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			< edges, lstate > = addExpEdges(edges, lstate, ifBranch);
			< edges, lstate > = addExpEdges(edges, lstate, elseBranch);

			edges = edges +  
				   conditionTrueFlowEdge(final(cond),init(ifBranch),cond) + 
				   conditionFalseFlowEdge(final(cond),init(elseBranch),cond) +
				   flowEdge(final(ifBranch), finalLabel) + flowEdge(final(elseBranch), finalLabel);
		}
		
		case ternary(Expr cond, noExpr(), Expr elseBranch) : {
			< edges, lstate > = addExpEdges(edges, lstate, cond);
			< edges, lstate > = addExpEdges(edges, lstate, elseBranch);

			edges = edges + 
				   conditionFalseFlowEdge(final(cond), init(elseBranch),cond) +
				   conditionTrueFlowEdge(final(cond), finalLabel,cond) + 
				   flowEdge(final(elseBranch), finalLabel);
		}

		case scalar(encapsed(parts)) : {
			< edges, lstate > = addExpSeqEdges(edges, lstate, parts);
			edges += flowEdge(final(last(parts)), finalLabel);
		}
		
		case staticPropertyFetch(expr(Expr className), expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges = edges + flowEdge(final(className),init(propertyName)) + flowEdge(final(propertyName), finalLabel);
		}

		case staticPropertyFetch(name(Name className), expr(Expr propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, propertyName);
			edges += flowEdge(final(propertyName), finalLabel);
		}

		case staticPropertyFetch(expr(Expr className), name(Name propertyName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, className);
			edges += flowEdge(final(className), finalLabel);
		}
		
		case var(expr(Expr varName)) : {
			< edges, lstate > = addExpEdges(edges, lstate, varName);
			edges += flowEdge(final(varName), finalLabel);
		}
		
		case yield(someExpr(k), noExpr()) : {
			< edges, lstate > = addExpEdges(edges, lstate, k);
			edges += flowEdge(final(k), finalLabel);
		}

		case yield(noExpr(), someExpr(v)) : {
			< edges, lstate > = addExpEdges(edges, lstate, v);
			edges += flowEdge(final(v), finalLabel);
		}

		case yield(someExpr(k), someExpr(v)) : {
			< edges, lstate > = addExpEdges(edges, lstate, k);
			< edges, lstate > = addExpEdges(edges, lstate, v);
			edges += flowEdge(final(k), init(v));
			edges += flowEdge(final(v), finalLabel);
		}
		
		case listExpr(exprs) : {
			actualExprs = [ ei | someExpr(ei) <- exprs ];
			if (size(actualExprs) > 0) {
				< edges, lstate > = addExpSeqEdges(edges, lstate, actualExprs);
				edges += flowEdge(final(last(actualExprs)), finalLabel);
			}
		}
		
	}

	return < edges, lstate >;			
}

public tuple[CFGNodes, FlowEdges, LabelState] addJoinNodes(CFGNodes nodes, FlowEdges edges, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}

	bool splitter(CFGNode n) {
		if (stmtNode(s,l) := n, init(s) != final(s)) {
			switch(s) {
				case declare(_,_) : return true;
				case do(_,_) : return true;
				case \for(_,_,_,_) : return true;
				case foreach(_,_,_,_,_) : return true;
				case \if(_,_,_,_) : return true;
				case namespace(_,_) : return true;
				case \switch(_,_) : return true;
				case tryCatch(_,_) : return true;
				case \while(_,_) : return true;
			}
		}
		return false;
	}
	
	// Find all the CFG nodes that represent control flow splits. In
	// these cases, control currently flows back in to the statement
	// itself at the end. Instead, we want to point the control to
	// a join node. To do this, we will insert the node, and then we
	// will insert it so all edges to the statement go to this node,
	// and all edges from this statement go from this node.
	for (CFGNode n <- nodes, splitter(n)) {
		Lab newLabel = incLabel();
		joiner = joinNode(n.stmt,newLabel)[@lab=newLabel];
		nodes += joiner;
		oldLabel = n@lab;
		edges = visit(edges) {
			case oldLabel => newLabel
		}
	}
	
	return < nodes, edges, lstate >;
}