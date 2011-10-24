@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::DataFlow

import lang::php::ast::AbstractSyntax;
import List;

// Label an AST. Note that, as compared to Nielson et al in Principles of Program Analysis, 
// this "over-labels" the tree, since we add labels to all expressions, not just top-level
// expressions inside of statements (e.g., in "if a < b + 10 ...", Nielson just labels
// "a < b + 10", while we label a, b, 10, b + 10, and a < b + 10. We also label all ids
// separately. In some cases, it may make sense to collapse the labels, for instance when
// we have Var(None(),NameId(Id("x")),None()), this will get labeled both at the var level
// and at the Id, but they are essentially the same since there is no target and there are
// no array indices.
data Lab = Lab(int id, str context);

// All nodes are annotated with lab, although we are not currently actually labeling all
// of these nodes. This gives us the option to later, though.
public anno Lab ClassDef@lab;
public anno Lab InterfaceDef@lab;
public anno Lab Member@lab;
public anno Lab Method@lab;
public anno Lab FormalParameter@lab;
public anno Lab NameWithDefault@lab;
public anno Lab Attribute@lab;
public anno Lab Stmt@lab;
public anno Lab Directive@lab;
public anno Lab SwitchCase@lab;
public anno Lab Catch@lab;
public anno Lab Expr@lab;
public anno Lab ListElement@lab;
public anno Lab ArrayElement@lab;
public anno Lab Lit@lab;
public anno Lab Var@lab;
public anno Lab NameExprOrId@lab;
public anno Lab ActualParameter@lab;
public anno Lab Id@lab;

// The LabelMap allows a quick way to go from labels to nodes in the tree, which is useful 
// especially when hand-checking various parts of the analysis construction.
alias LabelMap = map[Lab,node];

// Actually perform the labeling operation.
public tuple[Script,LabelMap] labelScript(Script script, str context) {
	int labCounter = 0;
	LabelMap lm = ( );
	
	Lab addLabel(node n) { labCounter += 1; lm = lm + ( Lab(labCounter,context) : n ); return Lab(labCounter,context); }
	 
	labeledScript = bottom-up visit(script) {
		case s:ClassDefStmt(_) => s[@lab = addLabel(s)]
		case s:InterfaceDefStmt(_) => s[@lab = addLabel(s)]
		case s:MethodStmt(_) => s[@lab = addLabel(s)]
		case s:ReturnStmt(None()) => s[@lab = addLabel(s)]
		case s:StaticDeclarationStmt(_) => s[@lab = addLabel(s)]
		case s:GlobalStmt(_) => s[@lab = addLabel(s)]
		case s:BreakStmt(_) => s[@lab = addLabel(s)]
		case s:ContinueStmt(_) => s[@lab = addLabel(s)]
		case s:NopStmt(_) => s[@lab = addLabel(s)]
		case Expr e => e[@lab = addLabel(e)]
		case Id i => i[@lab = addLabel(i)]
	};
	
	return < labeledScript, lm >;
}

// Find the initial labels for each statement
public Lab init(Stmt s) {
	switch(s) {
		case ClassDefStmt(_) : return s@lab;
		case InterfaceDefStmt(_) : return s@lab;
		case MethodStmt(_) : return s@lab;
		case ReturnStmt(None()) : return s@lab;
		case ReturnStmt(Some(e)) : return init(e);
		case StaticDeclarationStmt(_) : return s@lab;
		case GlobalStmt(_) : return s@lab;
		case TryStmt(tb,_) : return init(head(tb));
		case ThrowStmt(e) : return init(e);
		case EvalExprStmt(e) : return init(e);
		case IfStmt(ic,_,_) : return init(ic);
		case WhileStmt(wc,_) : return init(wc);
		case DoStmt(db,_) : return init(head(db));
		case ForStmt(Some(ie),_,_,_) : return init(ie);
		case ForStmt(None(),Some(ic),_,_) : return init(ic);
		case ForStmt(None(),None(),_,fb) : return init(head(fb));
		case ForEachStmt(e,_,_,_,_) : return init(e);
		case SwitchStmt(se,cs) : return init(se);
		case BreakStmt(_) : return s@lab;
		case ContinueStmt(_) : return s@lab;
		case DeclareStmt(_,db) : return init(head(db)); // ignore the directives for now, they should be ints or strings
		case NopStmt() : return s@lab;
		default : throw "Unmatched statement: <s>";
	}
}

// Find the initial label for each expression -- since all expressions are labeled,
// this is just the label of the expression itself
public Lab init(Expr e) {
	return e@lab;
}

// Calculate exits from each statement; note that this does not account for either abrupt
// exits (throw, return, break, continue) or exceptions occuring inside expressions. We
// add support for the first category in a later stage, while the second are currently
// ignored.
public set[Lab] final(Stmt s) {
	switch(s) {
		case ClassDefStmt(_) : return { s@lab };
		case InterfaceDefStmt(_) : return { s@lab };
		case MethodStmt(_) : return { s@lab };
		case ReturnStmt(None()) : return { s@lab };
		case ReturnStmt(Some(e)) : return final(e);
		case StaticDeclarationStmt(_) : return { s@lab };
		case GlobalStmt(_) : return { s@lab };
		// TODO: This can also exit the scope, either the surrounding function or the
		// block (if this is a top-level file designed to be included elsewhere). We
		// don't know the possible destinations in a modular way, but could potentially
		// figure them out in a whole program analysis.
		case TryStmt(tb,cb) : return final(last(tb)) + { final(last(sb)) | Catch(_,_,sb) <- cb };
		// TODO: For the same reasons as the try, this can exit the current scope. 
		case ThrowStmt(e) : return final(e);
		case EvalExprStmt(e) : return final(e);
		case IfStmt(ic,tb,fb) : return final(last(tb)) + final(last(fb));
		case WhileStmt(wc,wb) : return final(wc) + final(last(wb));
		case DoStmt(db,dc) : return final(dc);
		case ForStmt(_,Some(ic),_,fb) : return final(ic) + final(last(fb));
		case ForStmt(_,None(),_,fb) : return final(last(fb));
		case ForEachStmt(e,_,_,_,fb) : return final(e) + final(last(fb));
		// TODO: This does not properly account for fall-through. This needs to be rewritten to do
		// so. For instance, in a case statement block, if the block does not contain break, then it
		// will fall through, so the final label is actually in the following block (assuming one
		// exists).
		case SwitchStmt(se,cs) : return { final(last(cb)) | SwitchCase(_,cb) <- cs } + ( SwitchCase(Some(e),_) := last(cs) ? final(e) : { } );
		// TODO: For break and continue, need to indicate that this is a final label in the block. For
		// now, it will only be so if it is last.
		case BreakStmt(_) : return { s@lab };
		case ContinueStmt(_) : return { s@lab };
		case DeclareStmt(_,db) : return final(last(db));
		case NopStmt() : return { s@lab };
		default : throw "Unmatched statement: <s>";
	}
}

// Find the final label(s) for an expression. This may need to be expanded later, if we account
// for exceptional paths, since currently we just return the label of the entire expression instead
// of the labels of any of the subexpressions (this implies that the expression evaluates from left
// to right and evaluation always reaches the end).
public set[Lab] final(Expr e) {
	return { e@lab };
}

		//case s:BreakStmt(_) => s[@lab = addLabel(s)]
		//case s:ContinueStmt(_) => s[@lab = addLabel(s)]
		//case s:NopStmt(_) => s[@lab = addLabel(s)]
		//case Expr e => e[@lab = addLabel(e)]
		//case Id i => i[@lab = addLabel(i)]

public set[node] blocks(Stmt s) {
	switch(s) {
		case ClassDefStmt(_) : return { s };
		case InterfaceDefStmt(_) : return { s };
		case MethodStmt(_) : return { s };
		case ReturnStmt(None()) : return { s };
		case ReturnStmt(Some(e)) : return { s + e };
		case StaticDeclarationStmt(_) : return { s };
		case GlobalStmt(_) : return { s };
		case TryStmt(tb,cb) : return { blocks(tbi) | tbi <- tb } + { blocks(sbi) | Catch(_,_,sb) <- cb, sbi <- sb }; 
		case ThrowStmt(e) : return { e };
		case EvalExprStmt(e) : return { e };
		case IfStmt(ic,tb,fb) : return { ic } + { blocks(tbi) | tbi <- tb } + { blocks(fbi) | fbi <- fb };
		case WhileStmt(wc,wb) : return { wc } + { blocks(wbi) | wbi <- wb };
		case DoStmt(db,dc) : return { blocks(dbi) | dbi <- db } +  { dc };
		case ForStmt(_,Some(ic),_,fb) : return final(ic) + final(last(fb));
		case ForStmt(_,None(),_,fb) : return final(last(fb));
		case ForEachStmt(e,_,_,_,fb) : return final(e) + final(last(fb));
		// TODO: This does not properly account for fall-through. This needs to be rewritten to do
		// so. For instance, in a case statement block, if the block does not contain break, then it
		// will fall through, so the final label is actually in the following block (assuming one
		// exists).
		case SwitchStmt(se,cs) : return { final(last(cb)) | SwitchCase(_,cb) <- cs } + ( SwitchCase(Some(e),_) := last(cs) ? final(e) : { } );
		// TODO: For break and continue, need to indicate that this is a final label in the block. For
		// now, it will only be so if it is last.
		case BreakStmt(_) : return { s@lab };
		case ContinueStmt(_) : return { s@lab };
		case DeclareStmt(_,db) : return final(last(db));
		case NopStmt() : return { s@lab };
		default : throw "Unmatched statement: <s>";
	}
}

