module lang::php::analysis::types::Infer

import lang::php::ast::AbstractSyntax;

data Type 
	= scalar() 
	| array() 
	| array(Type elementType) 
	| class() 
	| class(str className) 
	| interface(str interfaceName) 
	| tv(int n) 
	| null() 
	| anything()
	| elementOf(Type arrayType)
	| resource()
	;

//public data Stmt 
//	= \break(OptionExpr breakExpr)
//	| classDef(ClassDef classDef)
//	| const(list[Const] consts)
//	| \continue(OptionExpr continueExpr)
//	| declare(list[Declaration] decls, list[Stmt] body)
//	| do(Expr cond, list[Stmt] body)
//	| echo(list[Expr] exprs)
//	| exprstmt(Expr expr)
//	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
//	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
//	| function(str name, bool byRef, list[Param] params, list[Stmt] body)
//	| global(list[Expr] exprs)
//	| goto(Name label)
//	| haltCompiler(str remainingText)
//	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
//	| inlineHTML(str htmlText)
//	| interfaceDef(InterfaceDef interfaceDef)
//	| traitDef(TraitDef traitDef)
//	| label(str labelName)
//	| namespace(OptionName nsName, list[Stmt] body)
//	| \return(OptionExpr returnExpr)
//	| static(list[StaticVar] vars)
//	| \switch(Expr cond, list[Case] cases)
//	| \throw(Expr expr)
//	| tryCatch(list[Stmt] body, list[Catch] catches)
//	| unset(list[Expr] unsetVars)
//	| use(list[Use] uses)
//	| \while(Expr cond, list[Stmt] body)	
//	;
