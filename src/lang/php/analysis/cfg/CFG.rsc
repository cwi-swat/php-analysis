module lang::php::analysis::cfg::CFG

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::DataFlow;
import lang::php::pp::PrettyPrinter;
import analysis::graphs::Graph;
import lang::php::analysis::NamePaths;

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

data CFGNode
	= functionEntry(str functionName)
	| functionExit(str functionName)
	| methodEntry(str className, str methodName)
	| methodExit(str className, str methodName)
	| scriptEntry()
	| scriptExit()
	| stmtNode(Stmt stmt)
	| exprNode(Expr expr)
	;

	
public rel[NamePath,CFG] createCFG(Script scr) {
	// CFGs are created for the script and for each function and method
	// in the script. 
	rel[str,str,ClassItem] methods = { };
	for (/class(cname,_,_,_,mbrs) := scr, m:method(mname,_,_,params,body) <- mbrs)
		methods += < cname, mname, m >;

	rel[str,Stmt] functions = { };
	for (/f:function(fname,_,params,body) := scr) {
		functions += < fname, f >;
	}
	 
	< scrLabeled, edges > = generateFlowEdges(scr);	
}

public tuple[Script, FlowEdges] generateFlowEdges(Script scr) {
	< labeled, lstate > = labelScript(scr); 
	return < labeled, { *internalFlow(b) | b <- labeled.body } + { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := labeled.body } >;
}

// TODOs:
// 1. Break and continue statements currently do not account for the
//    break/continue jump. To do this, we need to carry around a stack
//    of possible jump targets. For now, a break or continue will just
//    point to the next statement.
//
// 2. Gotos need to be handled by keeping track of which nodes are
//    related to which labels, and then linking these up appropriately.
//    For now, gotos just fall through to the next statement.
//
// 3. Throw statements should be linked to surrounding catch clauses.
//

// Labels are added to expressions and statements to give us a
// shorthand to refer to the various statements, expressions, and
// sub-statements/sub-expressions in the code.
data Lab = lab(int id);
public anno Lab Expr@lab;
public anno Lab Stmt@lab;

// A flow edge records the flow from one label to the next.
data FlowEdge = flowEdge(Lab from, Lab to);
alias FlowEdges = set[FlowEdge];

// The labeling state keeps track of information needed during
// the labeling and edge computation operations.
data LabelState = ls(int counter);
public LabelState newLabelState() = ls(0);
 
// Label the statements and expressions in a script.
public tuple[Script,LabelState] labelScript(Script script, LabelState lstate) {
	Lab incLabel() { 
		lstate[counter] += 1; 
		return lab(lstate[counter]); 
	}
	
	labeledScript = bottom-up visit(script) {
		case Stmt s => s[@lab = incLabel()]
		case Expr e => e[@lab = incLabel()]
	};
	
	return < labeledScript, lstate >;
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

		// A class def is treated as a unit.
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

		// In an unset, the first expression to unset provides the first label. If the list is
		// empty, the statement itself provides the label.
		case unset(list[Expr] unsetVars) : return isEmpty(unsetVars) ? s@lab : init(head(unsetVars));

		// A use statement is atomic.
		case use(_) : return s@lab;

		// In a while loop, the while condition is executed first and thus provides the first label.
		case \while(Expr cond, _) : return init(cond);	
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
			if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			else if (expr(Expr cname) := className)
				return init(cname);
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
			if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			else if (expr(Expr fname) := funName)
				return init(fname);
			return e@lab;
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			else 
				return init(target);
		}
		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			if (size(parameters) > 0 && actualParameter(Expr expr, bool byRef) := head(parameters))
				return init(expr);
			else if (expr(Expr sname) := staticTarget)
				return init(sname);
			else if (expr(Expr mname) := methodName)
				return init(mname);
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
		
		case scalar(Scalar scalarVal) : return e@lab;
		
		case var(expr(Expr varName)) : return init(varName);
		case var(name(Name varName)) : return e@lab;
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
public Lab final(Stmt s) = s@lab;
public Lab final(Expr e) = e@lab;

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
public FlowEdges internalFlow(Stmt s) {
	initLabel = init(s);
	finalLabel = final(s);
	
	if (initLabel == finalLabel) return { };
	
	// The switch just handles cases where the init label is not the same as the
	// final label, meaning there is some internal flow in the construct.
	switch(s) {
		// For break, the internal flow is from the break expression to the break
		// statement label.
		case \break(someExpr(Expr e)) : return internalFlow(e) + flowEdge(final(e),finalLabel);

		// For consts, if we only have one const def, the flow is from that def to the final
		// statement label. If we have more than one, we have to construct edges between the
		// final label of each const and the first label of the next, plus from the final
		// constant to the statement label.
		case const(list[Const] consts) : {
			if (firstConst:const(_, Expr firstValue) := head(consts), lastConst:const(_, Expr lastValue) := last(consts)) {
				if (firstConst == lastConst) {
					return internalFlow(firstValue) + flowEdge(final(firstValue),finalLabel);
				} else {
					return { *internalFlow(c) | const(_,c) <- consts } + 
					 	   { flowEdge(final(c1),init(c2)) | [_*,const(_,c1),const(_,c2),_*] := consts } +
					 	   flowEdge(final(lastValue), finalLabel);
				}
			}
		}

		// For continue, the internal flow is from the continue expression to the
		// continue statement label.
		case \continue(someExpr(Expr e)) : return internalFlow(e) + flowEdge(final(e),finalLabel);

		// For declarations, the flow is through the decl expressions, then through
		// the body, then to the label for this statement.
		case declare(list[Declaration] decls, list[Stmt] body) : {
			edges = { *internalFlow(v) | declaration(_,v) <- decls } +
			        { flowEdge(final(v1),init(v2)) | [_*,declaration(_,v1),declaration(_,v2),_*] := decls } +
			        { *internalFlow(b) | b <- body } +
			        { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body };
			if (size(decls) > 0 && size(body) > 0 && declaration(_,v) := last(decls) && b := head(body))
				edges += flowEdge(final(v),init(b));
			if (size(body) > 0 && b := last(body))
				edges += flowEdge(final(b),finalLabel);
			else if (size(decls) > 0 && declaration(_,v) := last(decls))
				edges += flowEdge(final(v),finalLabel);
				
			return edges;
		}


		// For do/while loops, the flow is through the body, then through the condition,
		// then to both the statement label and the top of the body (backedge).		
		case do(Expr cond, list[Stmt] body) : {
			edges = { *internalFlow(b) | b <- body } +
				    { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body };
			if (size(body) > 0)
				edges += { flowEdge(final(last(body)),init(cond)), flowEdge(final(cond),init(head(body))) };
			edges += flowEdge(final(cond),finalLabel);
			
			return edges;
		} 

		// For echo, the flow is from left to right in the echo expressions, then to the
		// statement label.
		case echo(list[Expr] exprs) : {
			edges = { *internalFlow(e) | e <- exprs } +
				    { flowEdge(final(e1), init(e2)) | [_*,e1,e2,_*] := exprs };
			if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
			
			return edges;
		}

		// For the expression statement, the flow is from the expression to the statement label.
		case exprstmt(Expr expr) : return internalFlow(expr) + flowEdge(final(expr), finalLabel);

		// Comments are given inline -- flow through a for is complex...
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) : {
			// Edges between different parts of the same loop
			edges = { *internalFlow(e) | e <- inits } +
			        { *internalFlow(e) | e <- conds } +
			        { *internalFlow(e) | e <- exprs } +
			        { *internalFlow(b) | b <- body } +
			        { flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := inits } +
			        { flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := conds } +
			        { flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := exprs } +
			        { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body };

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
				edges += flowEdge(final(last(conds)), init(head(body)));
			else if (size(conds) > 0 && size(exprs) > 0)
				edges += flowEdge(final(last(conds)), init(head(exprs)));
			else if (size(conds) > 0)
				edges += flowEdge(final(last(conds)), finalLabel);
				
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
				
			return edges;
		}

		case foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body) : {
			edges = { *internalFlow(b) | b <- body } +
			        { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body };
			         
			if (size(body) > 0) {
				edges += flowEdge(final(asVar), init(head(body)));
				edges += flowEdge(final(last(body)), finalLabel);
			} else {
				edges += flowEdge(final(asVar), finalLabel);
			}
				
			if (someExpr(keyexp) := keyvar) {
				edges += { flowEdge(final(arrayExpr), init(keyexp)), flowEdge(final(keyexp),init(asVar)) };
				if (size(body) > 0)
					edges += flowEdge(final(last(body)), init(keyexp));
				else
					edges += flowEdge(final(asVar), init(keyexp));
			} else {
				edges += flowEdge(final(arrayExpr), init(asVar));
				if (size(body) > 0)
					edges += flowEdge(final(last(body)), init(asVar));
				else
					edges += flowEdge(final(asVar), init(asVar));
			}
			
			return edges;
		}

		case global(list[Expr] exprs) : {
			edges = { *internalFlow(e) | e <- exprs } +
					{ flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := exprs };

			if (size(edges) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
				
			return edges;
		}

		case \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause) : {
			// This just brings in the flow inside each expression and statement and links
			// sequential body statements.
			edges = { *internalFlow(b) | b <- body } +
				    { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body } +
				    { *internalFlow(e) | elseIf(e,ebody) <- elseIfs } +
				    { *internalFlow(b) | elseIf(e,ebody) <- elseIfs, b <- ebody } +
				    { flowEdge(final(b1),init(b2)) | elseIf(e,ebody) <- elseIfs, [_*,b1,b2,_*] := ebody } +
				    { *internalFlow(b) | someElse(\else(ebody)) := elseClause, b <- ebody } +
				    { flowEdge(final(b1),init(b2)) | someElse(\else(ebody)) := elseClause, [_*,b1,b2,_*] := ebody };
				    
			// Link the condition to either the true branch body or, if this is empty, to the statement itself
			if (size(body) > 0) {
				edges += { flowEdge(final(cond), init(head(body))), flowEdge(final(last(body)), finalLabel) };
			} else {
				edges += flowEdge(final(cond), finalLabel);
			}
			
			// Link the condition with the else branch
			// TODO: It should never be the case that size(ebody) == 0
			if (someElse(\else(ebody)) := elseClause, size(ebody) > 0) {
				edges += { flowEdge(final(cond), init(head(ebody))), flowEdge(final(last(ebody)), finalLabel) };
			}
			
			// Link the condition with the first elseIf and the last elseIf with either the else (if present)
			// or the final label (representing the case where the else would be used but is not present).
			if (size(elseIfs) > 0, elseIf(e1,ebody1) := head(elseIfs), elseIf(e2,ebody2) := last(elseIfs)) {
				edges += flowEdge(final(cond), init(e1));
				if (someElse(\else(ebody)) := elseClause, size(ebody) > 0) {
					if (size(ebody2) > 0) {
						edges += flowEdge(final(last(ebody2)), init(head(ebody)));
					} else {
						edges += flowEdge(final(e2), init(head(ebody2)));
					}
				} else {
					if (size(ebody2) > 0) {
						edges += flowEdge(final(last(ebody2)), finalLabel);
					} else {
						edges += flowEdge(final(e2), finalLabel);
					}
				}
			}
			
			// Link together adjacent elseIf conditions
			for ([_*,elseIf(e1,_),elseIf(e2,_),_*] := elseIfs) edges += flowEdge(final(e1),init(e2));
			
			// Link the elseIfs with the statement label
			for (elseIf(e,ebody) <- elseIfs) {
				if (size(ebody) > 0)
					edges += flowEdge(final(last(ebody)), finalLabel);
				else
					edges += flowEdge(final(e), finalLabel);
			}
			
			return edges;
		}

		case namespace(OptionName nsName, list[Stmt] body) : {
			edges = { *internalFlow(b) | b <- body } +
			        { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body };

			if (size(body) > 0)
				edges += flowEdge(final(last(body)), finalLabel); 
			        
			return edges;			         
		}		

		case \return(someExpr(expr)) : return internalFlow(expr) + flowEdge(final(expr), finalLabel);

		case static(list[StaticVar] vars) : {
			varExps = [ e | v:staticVar(str name, someExpr(Expr e)) <- vars ];
			edges = { *internalFlow(e) | e <- varExps } +
					{ flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := varExps };

			if (size(varExps) > 0)
				edges += flowEdge(final(last(varExps)), finalLabel); 
				
			return edges;
		}

		case \switch(Expr cond, list[Case] cases) : {
			// Add the edges between statements, plus the internal flow edges for the cond and
			// all expressions and statements in the switch.
			edges = internalFlow(cond) +
					{ *internalFlow(b) | \case(_,body) <- cases, b <- body } +
					{ flowEdge(final(b1),init(b2)) | \case(_,body) <- cases, [_*,b1,b2,_*] := body } +
					{ *internalFlow(ccond) | \case(someExpr(ccond), _) <- cases };

			// Link the switch expression to the first case
			if (size(cases) > 0 && \case(someExpr(e),b) := head(cases)) {
				edges += flowEdge(final(cond), init(e));
			} else if (size(cases) > 0 && \case(noExpr(),b) := head(cases) && size(b) > 0) {
				edges += flowEdge(final(cond), init(head(b)));
			} else {
				edges += flowEdge(final(cond), finalLabel);
			}
			
			// For each case, link together the case condition with the body (in cases where there is
			// a case condition, i.e., anything but default)
			for (\case(someExpr(e),b) <- cases, size(b) > 0) edges += flowEdge(final(e),init(head(b)));
			
			// For each case, link together the case condition with the next case condition, representing
			// the situation where the case condition is tried but fails
			edges += { flowEdge(final(e1),init(e2)) | [_*,\case(someExpr(e1),b1),\case(someExpr(e2),b2),_*] := cases};

			// For each case, link together the last body element with the final label or, if the
			// body is empty, link together the case condition with the final label
			for (\case(e,b) <- cases, size(b) > 0) edges += flowEdge(final(last(b)), finalLabel);
			for (\case(someExpr(e),b) <- cases, size(b) == 0) edges += flowEdge(final(e), finalLabel);

			// Fallthrough: link together the last element of a case body with the first element of the next case
			// that has a body. To do this, for a) every case, that b) has a body, and c) does not include a normal
			// break (continue is usable here as well, but we don't check at this time, TODO add this), we
			// check in the list of cases following this for the first case with a non-empty body and, assuming
			// there is at least one, match the head of the list of all following cases with non-empty bodies to get it
			for ([_*,\case(_,b1),cl+], size(b1) > 0, [_*,\break(noExpr()),_*] !:= b1, cwb := [c | c:\case(_,b) <- cl, size(b) > 0], size(cwb) > 0, \case(_,b2) := head(cwb)) {
				edges += flowEdge(final(last(b1)), init(head(b2)));
			}

			return edges;						
		}

		case \throw(Expr expr) : return internalFlow(expr) + flowEdge(final(expr), finalLabel);

		case tryCatch(list[Stmt] body, list[Catch] catches) : {
			edges = { *internalFlow(b) | b <- body } +
					{ flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body } +
					{ *internalFlow(b) | \catch(_, _, cbody) <- catches, b <- cbody } +
					{ flowEdge(final(b1),init(b2)) | \catch(_, _, cbody) <- catches, [_*,b1,b2,_*] := cbody };
					{ flowEdge(final(last(body)),init(init(head(cbody)))) | \catch(_, _, cbody) <- catches, size(body) > 0, size(cbody) > 0 };
			
			return edges;
		}

		case unset(list[Expr] unsetVars) : {
			return { *internalFlow(e) | e <- unsetVars } + { flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := unsetVars };
		}

		case \while(Expr cond, list[Stmt] body) : {
			edges = internalFlow(cond) + 
				    { *internalFlow(b) | b <- body } + 
				    { flowEdge(final(b1),init(b2)) | [_*,b1,b2,_*] := body } +
				    flowEdge(final(cond), finalLabel);
				    
			if (size(body) > 0) {
				edges += { flowEdge(final(cond), init(head(body))), flowEdge(final(last(body)), init(cond)) };
			} else {
				edges += flowEdge(final(cond), init(cond));
			}
			
			return edges;
		}
		
		default: throw "internalFlow(Stmt s): A case that was not expected: <s>";
	}
	
	println("Missed a return for statement <s>");
}

// Compute all the internal flow edges for an expression.
public tuple[FlowEdges,LabelState] internalFlow(Expr e, LabelState lstate) {
	Lab incLabel() { 
		lstate[counter] += 1; 
		return lab(lstate[counter]); 
	}

	initLabel = init(e);
	finalLabel = final(e);
	
	if (initLabel == finalLabel) return { };

	switch(e) {
		case array(list[ArrayElement] items) : {
			edges = { };
			for (arrayElement(OptionExpr key, Expr val, bool byRef) <- items) {
				< aeEdges, lstate > = internalFlow(val);
				edges += aeEdges;
			}
			for (arrayElement(someExpr(Expr key), Expr val, bool byRef) <- items) {
				< aeEdges, lstate > = internalFlow(val);
				edges += aeEdges;
			}

			for ([_*,arrayElement(k1,v1,_),arrayElement(k2,v2,_),_*] := items) {
				if (someExpr(kv) := k2)
					edges += flowEdge(final(v1), init(kv));
				else
					edges += flowEdge(final(v1), init(v2));
			}

			if (size(items) > 0, arrayElement(_,val,_) := last(items))
				edges += flowEdge(final(val), finalLabel);

			return edges;			
		}
		
		case fetchArrayDim(Expr var, someExpr(Expr dim)) :
			return { flowEdge(final(var), init(dim)), flowEdge(final(dim),finalLabel), *internalFlow(var), *internalFlow(dim) };
		case fetchArrayDim(Expr var, noExpr()) :
			return { flowEdge(final(var), finalLabel), *internalFlow(var) };
		
		case fetchClassConst(expr(Expr className), str constName) : 
			return { flowEdge(final(className), finalLabel), *internalFlow(className) };
		
		case assign(Expr assignTo, Expr assignExpr) : 
			return { flowEdge(final(assignExpr), init(assignTo)), flowEdge(final(assignTo), finalLabel), *internalFlow(assignTo), *internalFlow(assignExpr) };
		
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) : 
			return { flowEdge(final(assignExpr), init(assignTo)), flowEdge(final(assignTo), finalLabel), *internalFlow(assignTo), *internalFlow(assignExpr) };
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) : {
			listExps = reverse([le|someExpr(le) <- assignsTo]);
			edges = internalFlow(assignExpr) + { *internalFlow(le) | le <- listExps } +
				    { flowEdge(final(le1),init(le2)) | [_*,le1,le2,_*] := listExps };
			
			if (size(listExps) > 0)
				edges += flowEdge(final(last(listExps)), finalLabel);
			else
				edges += flowEdge(final(assignExpr), finalLabel);
				
			return edges;
		}
		
		case refAssign(Expr assignTo, Expr assignExpr) : 
			return { flowEdge(final(assignExpr), init(assignTo)), flowEdge(final(assignTo), finalLabel), *internalFlow(assignTo), *internalFlow(assignExpr) };
		
		case binaryOperation(Expr left, Expr right, Op operation) : 
			return { flowEdge(final(left), init(right)), flowEdge(final(right), finalLabel), *internalFlow(left), *internalFlow(right) };
		
		case unaryOperation(Expr operand, Op operation) : 
			return { flowEdge(final(operand), finalLabel), *internalFlow(operand) };
		
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			edges = { *internalFlow(aexp) | actualParameter(aexp,_) <- parameters } +
					{ flowEdge(final(ae1), init(ae2)) | [_*,actualParameter(ae1,_),actualParameter(ae2,_),_*] := parameters };

			if (expr(Expr cn) := className) {
				edges += { *internalFlow(cn), flowEdge(final(cn),finalLabel) };
				if (size(parameters) > 0)
					edges += flowEdge(final(last(parameters).expr), init(cn));
			} else {
				if (size(parameters) > 0)
					edges += flowEdge(final(last(parameters).expr), finalLabel);
			}
			
			return edges;
		}
		
		case cast(CastType castType, Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case clone(Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case empty(Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case suppress(Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case eval(Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case exit(someExpr(Expr exitExpr)) :
			return internalFlow(exitExpr) + flowEdge(final(exitExpr), finalLabel);
		
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			edges = { *internalFlow(aexp) | actualParameter(aexp,_) <- parameters } +
					{ flowEdge(final(ae1), init(ae2)) | [_*,actualParameter(ae1,_),actualParameter(ae2,_),_*] := parameters };

			if (expr(Expr fn) := funName) {
				edges += { *internalFlow(fn), flowEdge(final(fn),finalLabel) };
				if (size(parameters) > 0)
					edges += flowEdge(final(last(parameters).expr), init(fn));
			} else {
				if (size(parameters) > 0)
					edges += flowEdge(final(last(parameters).expr), finalLabel);
			}
			
			return edges;
		}
		
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			edges = { *internalFlow(aexp) | actualParameter(aexp,_) <- parameters } +
					{ flowEdge(final(ae1), init(ae2)) | [_*,actualParameter(ae1,_),actualParameter(ae2,_),_*] := parameters } +
					internalFlow(target);

			if (size(parameters) > 0) {
				edges += flowEdge(final(last(parameters).expr), init(target));
			}

			if (expr(Expr mn) := methodName) {
				edges += { *internalFlow(mn), flowEdge(final(target),init(mn)), flowEdge(final(mn),finalLabel) };
			} else {
				edges += flowEdge(final(target), finalLabel);
			}
			
			return edges;
		}

		
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			edges = { *internalFlow(aexp) | actualParameter(aexp,_) <- parameters } +
					{ flowEdge(final(ae1), init(ae2)) | [_*,actualParameter(ae1,_),actualParameter(ae2,_),_*] := parameters } +
					internalFlow(staticTarget);

			if (size(parameters) > 0) {
				edges += flowEdge(final(last(parameters.expr)), init(staticTarget));
			}

			if (expr(Expr mn) := methodName) {
				edges += { *internalFlow(mn), flowEdge(final(staticTarget),init(mn)), flowEdge(final(mn),finalLabel) };
			} else {
				edges += flowEdge(final(staticTarget), finalLabel);
			}
			
			return edges;
		}

		
		case include(Expr expr, IncludeType includeType) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case instanceOf(Expr expr, expr(Expr toCompare)) :
			return internalFlow(expr) + internalFlow(toCompare) + flowEdge(final(expr),init(toCompare)) + flowEdge(final(toCompare),finalLabel);
		
		case instanceOf(Expr expr, name(Name toCompare)) :
			return internalFlow(expr) + flowEdge(final(expr),finalLabel);

		case isSet(list[Expr] exprs) : {
			edges = { *internalFlow(ex) | ex <- exprs } +
					{ flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := exprs };

			if (size(exprs) > 0)
				edges += flowEdge(final(last(exprs)), finalLabel);
				
			return edges; 
		}
		
		case print(Expr expr) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
		
		case propertyFetch(Expr target, expr(Expr propertyName)) :
			return internalFlow(target) + internalFlow(propertyName) + flowEdge(final(target),init(propertyName)) + flowEdge(final(propertyName),finalLabel);
		
		case propertyFetch(Expr target, name(Name propertyName)) :
			return internalFlow(target) + flowEdge(final(target), finalLabel);

		case shellExec(list[Expr] parts) : {
			edges = { *internalFlow(ex) | ex <- parts } +
					{ flowEdge(final(e1),init(e2)) | [_*,e1,e2,_*] := parts };

			if (size(parts) > 0)
				edges += flowEdge(final(last(parts)), finalLabel);
				
			return edges; 
		}

		case ternary(Expr cond, someExpr(Expr ifBranch), Expr elseBranch) :
			return internalFlow(cond) + internalFlow(ifBranch) + internalFlow(elseBranch) +
				   flowEdge(final(cond),init(ifBranch)) + flowEdge(final(cond),init(elseBranch)) +
				   flowEdge(final(ifBranch), finalLabel) + flowEdge(final(elseBranch), finalLabel);
		
		case ternary(Expr cond, noExpr(), Expr elseBranch) :
			return internalFlow(cond) + internalFlow(elseBranch) + flowEdge(final(cond), init(elseBranch)) +
				   flowEdge(final(cond), finalLabel) + flowEdge(final(elseBranch), finalLabel);

		case staticPropertyFetch(expr(Expr className), expr(Expr propertyName)) :
			return internalFlow(className) + internalFlow(propertyName) + flowEdge(final(className),init(propertyName)) + flowEdge(final(propertyName),finalLabel);

		case staticPropertyFetch(name(Name className), expr(Expr propertyName)) :
			return internalFlow(propertyName) + flowEdge(final(propertyName), finalLabel);

		case staticPropertyFetch(expr(Expr className), name(Name propertyName)) :
			return internalFlow(className) + flowEdge(final(className), finalLabel);
		
		case var(expr(Expr varName)) :
			return internalFlow(expr) + flowEdge(final(expr), finalLabel);
	}
}
