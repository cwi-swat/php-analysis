module lang::php::abstractions::templates::TemplateModel

import lang::php::ast::AbstractSyntax;
import lang::php::ast::NormalizeAST;
import List;

data TemplateItem
	= htmlText(str text)
	| hole(Expr holeExpr)
	| branch(list[TemplateItem] trueBranch, list[TemplateItem] falseBranch, Expr ifExpr)
	| concat(TemplateItem left, TemplateItem right)
	;

alias Fragments = list[TemplateItem];

data Template = template(Fragments);

public Fragments fragments(OptionExpr optExpr) {
	switch(optExpr) {
		case noExpr() :
			return [ ];
		case someExpr(Expr expr) :
			return fragments(expr);
	}
}

public Fragments fragments(NameOrExpr nOrExp) {
	switch(nOrExp) {
		case name(Name n) :
			return [ ];
		case expr(Expr expr) :
			return fragments(expr);
	}
}

public Fragments fragments(Expr expr) {
	switch(expr) {
		case array(list[ArrayElement] items) :
			for (arrayElement(OptionExpr key, Expr val, bool byRef) <- items) {
				valFragments = fragments(val);
				if (someExpr(keyExpr) := key)
					return fragments(keyExpr) + valFragments;
				else
					return valFragments;
			}
			
		case fetchArrayDim(Expr var, OptionExpr dim) :
			return fragments(var) + fragments(dim);
			
		case fetchClassConst(NameOrExpr className, str constName) :
			return fragments(className);
			
		case assign(Expr assignTo, Expr assignExpr) :
			return fragments(assignTo) + fragments(assignExpr);
			
		case assignWOp(Expr assignTo, Expr assignExpr, Op operation) :
			return fragments(assignTo) + fragments(assignExpr);
		
		case listAssign(list[OptionExpr] assignsTo, Expr assignExpr) :
			return [ *fragments(oe) | someExpr(oe) <- assignsTo ] + fragments(assignExpr);
			
		case refAssign(Expr assignTo, Expr assignExpr) :
			return fragments(assignTo) + fragments(assignExpr);
			
		case binaryOperation(Expr left, Expr right, Op operation) :
			return fragments(left) + fragments(right);
			
		case unaryOperation(Expr operand, Op operation) :
			return fragments(operand);
			
		case new(NameOrExpr className, list[ActualParameter] parameters) : {
			Fragments nameFragments = [ ];
			if (expr(cne) := className) nameFragments = fragments(cne);
			return nameFragments +  [ *fragments(apExp) | actualParameter(apExp, _) <- parameters ];
		}
		
		case cast(CastType castType, Expr expr) :
			return fragments(expr);
			
		case clone(Expr expr) :
			return fragments(expr);

		case closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static) :
			return [ ]; // We don't currently support closures, we need a way to approximate their template output when they appear
			
		case fetchConst(Name name) :
			return [ ];			
			
		case empty(Expr expr) :
			return fragments(expr);
			 
		case suppress(Expr expr) :
			return fragments(expr);
			
		case eval(Expr expr) :
			return fragments(expr);
			
		case exit(OptionExpr exitExpr) :
			return fragments(exitExpr);
			
		case call(NameOrExpr funName, list[ActualParameter] parameters) : {
			Fragments nameFragments = [ ];
			if (expr(fne) := funName) nameFragments = fragments(fne);
			return nameFragments +  [ *fragments(apExp) | actualParameter(apExp, _) <- parameters ];
		}
			
		case methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters) : {
			Fragments targetFragments = fragments(target);
			Fragments nameFragments = [ ];
			if (expr(mne) := methodName) nameFragments = fragments(mne);
			return targetFragments + nameFragments +  [ *fragments(apExp) | actualParameter(apExp, _) <- parameters ];
		}
			
		case staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters) : {
			Fragments targetFragments = [ ];
			if (expr(sne) := staticTarget) targetFragments = fragments(sne);
			
			Fragments nameFragments = [ ];
			if (expr(mne) := methodName) nameFragments = fragments(mne);
			
			return targetFragments + nameFragments +  [ *fragments(apExp) | actualParameter(apExp, _) <- parameters ];
		}
			
		case include(Expr expr, IncludeType includeType) :
			return fragments(expr);
			
		case instanceOf(Expr expr, NameOrExpr toCompare) :
			return fragments(expr) + fragments(toCompare);
			
		case isSet(list[Expr] exprs) :
			return [ *fragments(e) | e <- exprs ];
			
		case print(Expr expr) :
			if (scalar(string(s)) := expr)
				return [ htmlText(s) ];
			else if (scalar(encapsed(el)) := expr)
				return [ (scalar(string(s)) := ei) ? htmlText(s) : hole(ei) | ei <- el ];
			else
				return [ hole(expr) ];
			
		case propertyFetch(Expr target, NameOrExpr propertyName) :
			return fragments(target) + fragments(propertyName);
			
		case shellExec(list[Expr] parts) :
			return [ *fragments(e) | e <- parts ];
			
		case ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch) : {
			Fragments elseFragments = fragments(elseBranch);
			Fragments ifFragments = [ ];
			if (someExpr(ie) := ifBranch) ifFragments = fragments(ie);
			return fragments(cond) + branch(ifFragments, elseFragments, cond);
		}
			
		case staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName) :
			return fragments(className) + fragments(propertyName);
			
		case scalar(Scalar scalarVal) :
			return [ ];
			
		case var(NameOrExpr varName) :
			return fragments(varName);
			
		case yield(OptionExpr keyExpr, OptionExpr valueExpr) :
			return fragments(keyExpr) + fragments(valueExpr);
			
		case listExpr(list[OptionExpr] listExprs) :
			return [ *fragments(le) | someExpr(le) <- listExprs ];
	}
}
	
public Fragments fragments(Stmt stmt) {
	switch(stmt) {
		case \break(OptionExpr breakExpr) :
			if (someExpr(be) := breakExpr)
				return fragments(be);
			else
				return [ ];
			
		case classDef(ClassDef classDef) :
			return [ ]; // We don't descend into classes, each should be processed separately
			
		case const(list[Const] consts) :
			return [ ]; // TODO
			
		case \continue(OptionExpr continueExpr) :
			if (someExpr(ce) := continueExpr)
				return fragments(ce);
			else
				return [ ];
			
		case declare(list[Declaration] decls, list[Stmt] body) :
			return [ ]; // TODO
			
		case do(Expr cond, list[Stmt] body) :
			return [ ]; // TODO
			
		case echo(list[Expr] exprs) :
			return [ *fragments(e) | e <- exprs ]; // TODO: Tune this for scalars, this is not complete 
			
		case exprstmt(Expr expr) :
			return fragments(expr);
			
		case \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body) :
			return [ ]; // TODO
			
		case foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body) :
			return [ ]; // TODO
			
		case function(str name, bool byRef, list[Param] params, list[Stmt] body) :
			return [ ]; // We don't descend into functions, each should be processed separately
			
		case global(list[Expr] exprs) :
			return [ *fragments(e) | e <- exprs ];
			
		case goto(str label) :
			return [ ];
			
		case haltCompiler(str remainingText) :
			return [ ];
			
		case \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause) : {
			// TODO: Need to account properly for cases where print appears in the condition
			condFragments = fragments(cond);
			ifFragments = [ *fragments(b) | b <- body ];
			elseFragments = [ ];

			if(someElse(\else(elseBody)) := elseClause)
				elseFragments = [ *fragments(eb) | eb <- elseBody ];

			eiPairs = reverse([ < eiCond, [ *fragments(ei) | ei <- eiBody ] > | elseIf(eiCond, eiBody) <- elseIfs ]);

			if (size(eiPairs) > 0, < firstCond, firstFragments > := head(eiPairs)) {
				Fragments workingFragments = fragments(firstCond) + branch(firstFragments, elseFragments, firstCond);
				nestedFragments = ( workingFragments | fragments(nextCond) + branch(nextFragments, it, nextCond) | < nextCond, nextFragments > <- tail(eiPairs) );
				return condFragments + branch(ifFragments, nestedFragments, cond); 
			} else {
				return condFragments + branch(ifFragments, elseFragments, cond);
			}
		}
			
		case inlineHTML(str htext) :
			return [ htmlText(htext) ];
			
		case interfaceDef(InterfaceDef interfaceDef) :
			return [ ]; // We don't descend into interfaces, each should be processed separately
			
		case traitDef(TraitDef traitDef) :
			return [ ]; // We don't descend into traits, each should be processed separately
			
		case label(str labelName) :
			return [ ];
			
		case namespace(OptionName nsName, list[Stmt] body) :
			return [ *fragments(b) | b <- body ];
			
		case namespaceHeader(Name namespaceName) :
			return [ ];
			
		case \return(OptionExpr returnExpr) :
			if (someExpr(re) := returnExpr)
				return fragments(re);
			else
				return [ ];
			
		case static(list[StaticVar] vars) :
			return [ *fragments(defaultValue) | staticVar(str name, someExpr(defaultValue)) <- vars ];
			
		case \switch(Expr cond, list[Case] cases) :
			return [ ]; // TODO
			
		case \throw(Expr expr) :
			return [ *fragments(expr) ];
			
		case tryCatch(list[Stmt] body, list[Catch] catches) :
			return [ ]; // TODO
			
		case tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody) :
			return [ ]; // TODO
			
		case unset(list[Expr] unsetVars) :
			return [ *fragments(uv) | uv <- unsetVars ];
			
		case use(list[Use] uses) :
			return [ ];
			
		case \while(Expr cond, list[Stmt] body) :
			return [ ]; // TODO
			
		case emptyStmt() :
			return [ ];
			
		case block(list[Stmt] body) :
			return [ *fragments(b) | b <- body ];
	}
}

public Template createTemplate(Script s) {
	if (script(sbody) := s)
		return template([ *fragments(b) | b <- sbody ]);
	else
		return template([]);
}