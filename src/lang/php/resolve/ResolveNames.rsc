@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
@doc{
  ResolveNames handles name resolution for PHP files. We make one huge assumption
  here, which is that we are working with PHP code that is, at least, structurally
  correct. For instance, we are not given code where a class is defined as being
  nested inside another class, which appears to be invalid PHP regardless of
  the intervening constructs (e.g., putting the nested class declaration inside
  a function declaration inside a method declaration doesn't work).
}
module lang::php::resolve::ResolveNames

import lang::php::ast::AbstractSyntax;
import lang::php::util::Option;
import lang::php::resolve::SymbolTable;

public &T threadit(&T t, list[&U] us, &T(&T,&U) f) { for (usi <- us) t = f(t,usi); return t; }
public &T ifSome(&T t, Option[&U] u, &T(&T,&U) f) { if (Some(s) := u) return f(t,s); return t; }
 
//
// Add a script. This triggers creation of the builder and a module representing this
// script. Things at the module level are not always at the global level -- the level
// they are at will be decided based on the context in which the script is used. For
// instance, if this script is included into a class definition, functions at the 
// module level will be treated as class-level methods.
// 
public STBuilder resolve(str scriptName, list[Stmt] script) {
	STBuilder st = createNewSTBuilder();
	Item item = Module(Id(scriptName));
	< st, mid > = addItemIntoGlobalScope(st, item);
	st = pushScope(st, mid);
	st = threadit(st,script,resolve);
	st = popScope(st);
}

//
// Resolve class names. We first add the class, making it the current scope. We then try to link in
// any other classes or interfaces referenced through extends and implements. Note that these may
// not have been created yet, in which case we just hook up a placeholder which should be filled
// in later. Then we process the class body, which is made up of a number of members (attributes 
// and methods). All class and interface names are created at the global scope.
//
// TODO: This currently assumes that defaults for attributes only reference earlier attributes. This is
// sensible, but may not be correct.
//
public STBuilder resolve(STBuilder st, ClassDef cdef:ClassDef(bool isAbstract, bool isFinal, Id className, Option[Id] extends, list[Id] implements, list[Member] members)) {
	Item item = Class(className, None(), [], [], isAbstract, isFinal, last(st.scopeStack), cdef@at);
	
	// Check the extends class, if it exists. TODO: Should we just throw in Object, or the PHP
	// equivalent, if no explicit extends is given?
	if (Some(ename) := extends) {
		if (Some(eid) := lookupGlobalTypeName(st,ename)) {
			item.extendsClass = Some(eid); // TODO: Check that this is a class?
			st.itemUses = st.itemUses + < ename@at, eid >;
		} else {
			eitem = ClassPlaceholder(ename, last(st.scopeStack), cdef@at);
			< st, eid > = addItemIntoGlobalScope(st,eitem);
			item.extendsClass = Some(eid);
			st.itemUses = st.itemUses + < ename@at, eid >;
		}
	}

	// Check the implements interfaces, adding placeholders if needed.
	for (iname <- implements) {
		if (Some(iid) := lookupGlobalTypeName(st,iname)) {
			item.implements = item.implements + iid; // TODO: Check that this is an interface?
			st.itemUses = st.itemUses + < iname@at, iid >;
		} else {
			iitem = InterfacePlaceholder(iname, last(st.scopeStack), cdef@at);
			< st, iid > = addItemIntoGlobalScope(st,iitem);
			item.implements = item.implements + iid;
			st.itemUses = st.itemUses + < iname@at, iid >;
		}
	}
	
	// If a placeholder already exists, just replace the existing placeholder item with 
	// this item. Else, add the new one.
	if (Some(cid) := lookupGlobalTypeName(st, className), getName(st.scopeItemMap[cid]) notin { "ClassPlaceholder", "TypePlaceholder" }) {
		throw "Attempting to add class <className>, but this class already exists!";
	} else if (Some(cid) := lookupGlobalTypeName(st, className)) {
		st.scopeItemMap[cid] = item;
		st = threadit(pushScope(st,cid), [mbr | mbr <- members, getName(mbr) == "AttributeMember" ], resolve);
		st = popScope(threadit(st, [mbr | mbr <- members, getName(mbr) == "MethodMember" ], resolve));
		st.itemUses = st.itemUses + < className@at, cid >;
	} else {
		< st, cid > = addItemIntoGlobalScope(st,item);
		st = threadit(pushScope(st,cid), [mbr | mbr <- members, getName(mbr) == "AttributeMember" ], resolve);
		st = popScope(threadit(st, [mbr | mbr <- members, getName(mbr) == "MethodMember" ], resolve));
		st.itemUses = st.itemUses + < className@at, cid >;
	}	
	
	return st;
}

//
// Resolve interface names. This is similar to the code given above for class names. All class and interface
// names are created at the global scope.
//
// TODO: This currently assumes that defaults for attributes only reference earlier attributes. This is
// sensible, but may not be correct.
//
public STBuilder resolve(STBuilder st, InterfaceDef idef:InterfaceDef(Id interfaceName, list[Id] extends, list[Member] members)) {
	Item item = Interface(interfaceName, [], [], last(st.scopeStack), idef@at);

	// Check the extends interfaces, adding placeholders if needed.
	for (ename <- extends) {
		if (Some(eid) := lookupGlobalTypeName(st,ename)) {
			item.extends = item.extends + eid; // TODO: Check that this is an interface?
			st.itemUses = st.itemUses + < ename@at, eid >;
		} else {
			eitem = InterfacePlaceholder(ename, last(st.scopeStack), cdef@at);
			< st, eid > = addItemIntoGlobalScope(st,eitem);
			item.extends = item.extends + eid;
			st.itemUses = st.itemUses + < ename@at, eid >;
		}
	}

	// If a placeholder already exists, just replace the existing placeholder item with 
	// this item. Else, add the new one.
	if (Some(iid) := lookupGlobalTypeName(st, interfaceName), getName(st.scopeItemMap[iid]) notin { "InterfacePlaceholder", "TypePlaceholder" }) {
		throw "Attempting to add interface <interfaceName>, but this interface already exists!";
	} else if (Some(iid) := lookupGlobalTypeName(st, interfaceName)) {
		st.scopeItemMap[iid] = item;
		st = threadit(pushScope(st,iid), [mbr | mbr <- members, getName(mbr) == "AttributeMember" ], resolve);
		st = popScope(threadit(st, [mbr | mbr <- members, getName(mbr) == "MethodMember" ], resolve));
		st.itemUses = st.itemUses + < interfaceName@at, iid >;
	} else {
		< st, iid > = addItemIntoGlobalScope(st,item);
		st = threadit(pushScope(st,iid), [mbr | mbr <- members, getName(mbr) == "AttributeMember" ], resolve);
		st = popScope(threadit(st, [mbr | mbr <- members, getName(mbr) == "MethodMember" ], resolve));
		st.itemUses = st.itemUses + < className@at, cid >;
	}	
	
	return st;
}

//
// Resolve names in members. This just branches off to the appropriate logic, based
// on whether the member is a method or attribute.
//
public STBuilder resolve(STBuilder st, MethodMember(Method method)) = resolve(st,method);
public STBuilder resolve(STBuilder st, AttributeMember(Attribute attribute)) = resolve(st,attribute);

//
// Resolve names in methods. We add the method item and make it the current scope before processing
// any formal parameters and statements in the body. We also add this into the parent, assuming the
// parent is a class. The frontend converts all functions to methods, so this logic has to work for
// functions that are not associated with any class.
//
public STBuilder resolve(STBuilder st, Method mdef) {
	if (Method(bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isAbstract, bool isFinal, bool isRef, Id methodName, list[FormalParameter] parameters, Option[list[Stmt]] methodBody) := mdef) {
		// Set the correct parent. Unfortunately, this isn't obvious because of PHP-weirdness. If the
		// current scope is a class, this is definitely part of the class, so the class is the parent.
		// If the current scope is not a class, but is instead the top level of the module, the module
		// is the parent, and we will decide later what the parent really is. If the current scope is
		// neither, this must be global (for instance, if this is a function defined inside another
		// function, it must be global).
		ItemId parentScopeId = head(st.scopeStack);
		if (getName(st.scopeItemMap[parentScopeID]) notin {"Class","Interface"}) {
			if (getName(st.scopeItemMap[parentScopeId]) == "Module")
				parentScopeId = last(prefix(st.scopeStack));
			else
				parentScopeId = last(st.scopeStack);
		}
	
		// Now, add the item into the correct scope, as determined above.
		Item item = Method(methodName, None(), [], isPublic, isProtected, isPrivate, isStatic, isAbstract, isFinal, isRef, parentScopeId, mdef@at);
		
		// See if a method of this name has already been added. If so, we had a call to it before it was defined. Replace
		// the placeholder with the actual information.
		mId = 0;
		if (Some(pid) := lookupName(st, methodName), getName(st.scopeItemMap[pid]) in { "MethodPlaceholder"}) {
			mId = pid; st.scopeItemMap[pid] = item;
		} else {
			< st, mId > = addItemIntoScope(st,item,parentScopeId);
		}
		st.itemUses = st.itemUses + < methodName@at, mId >;
		
		// If this is a method, add it to the member list for the class 
		if (getName(st.scopeItemMap[parentScopeId]) in {"Class","Interface"}) 
			st.scopeItemMap[parentScopeId].members = st.scopeItemMap[parentScopeId].members + mId;
			
		// Now, make the method the current scope; then, add the formals and process the body.
		st = pushItem(st,mId);
		st = threadit(st,parameters,resolve);
		if (Some(mb) := methodBody) st = threadit(st, mb, resolve);
		
		// Leave the method scope, returning to the prior scope (whatever it was).
		st = popItem(st);
	}
	return st;
}

//
// Resolve formal parameter names. Essentially, we just want to add the parameter, linking it to its
// parent context, which should be a function or method (Method item). One subtlety is that we
// process the default expression before adding the parameter name, since the default should not
// depend on this name.
//
public STBuilder resolve(STBuilder st, FormalParameter fp) {
	if (FormalParameter(Option[Id] paramType, bool isRef, NameWithDefault param) := fp) {
		if (NameWithDefault(_,Some(e)) := param) st = resolve(st, e);
		< st, fId > = addItemIntoCurrentScope(st,FormalParameter(param.variableName, paramType, isRef, head(st.scopeStack), fp@at));
		st.itemUses = st.itemUses + < param.variableName@at, fId >;
		st.scopeItemMap[head(st.scopeStack)].params = st.scopeItemMap[head(st.scopeStack)].params + fId;
	}
	return st;
}
	
//	
// Resolve attribute (i.e., field) names. Much like with methods, we add these into scope and link them
// to the parent. Much like with formal parameters, we resolve names in default expressions first.
// 	 	
public STBuilder resolve(STBuilder st, Attribute adef) {
	if (Attribute(bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isConst, list[NameWithDefault] vars) := adef) {
		for (NameWithDefault(_,Some(e)) <- vars) st = resolve(st, e);
		
		for (nwd:NameWithDefault(x,_) <- vars) {
			Item item = Attribute(x, None(), isPublic, isProtected, isPrivate, isStatic, isConst, head(st.scopeStack), nwd@at);
			< st, fId > = addItemIntoCurrentScope(st,item);
			st.itemUses = st.itemUses + < x@at, fId >;
			if (getName(st.scopeItemMap[head(st.scopeStack)]) in {"Class","Interface"}) 
				st.scopeItemMap[head(st.scopeStack)].members = st.scopeItemMap[head(st.scopeStack)].members + fId;
		}
	}
	return st;
}

//
// Resolve names in statements. makeVarsStatic and makeVarsGlobal are helpers that properly handle either
// declaring a static variable (the first) or declaring a global variable (the second).
//
public STBuilder makeVarsStatic(STBuilder st, list[NameWithDefault] vars) {
	for (NameWithDefault(_,Some(e)) <- vars) st = resolve(st, e); // These should all be literals
	
	for (nwd:NameWithDefault(x,_) <- vars) {
		Item item = Variable(x, None(), true, false, head(st.scopeStack), nwd@at);
		< st, dId > = addItemIntoCurrentScope(st,item);
		st.itemUses = st.itemUses + < x@at, dId >;		
	}
	
	return st;
}

public STBuilder makeVarsGlobal(STBuilder st, list[NameExprOrId] vars) {
	for (ne:NameExpr(_) <- vars) throw "Warning, we do not currently handle variable variables: <ne>";
	 
	for (ne:NameId(x) <- vars) {
		// First, do we have a local definition of this name? If so, throw, so we know about it. If we
		// find these, TODO: we will need to handle them during data flow analysis.
		if (Some(_) := lookupName(st,x)) throw "Warning, we do not currently handle hiding locals in global declarations: <ne>";

		if (None() := lookupGlobalName(st,x)) {
			Item item = Variable(x, None(), false, true, last(st.scopeStack), ne@at);
			< st, vId > = addItemIntoGlobalScope(st,item);
			st.itemUses = st.itemUses + < x@at, vId >;
		}
	}
	
	return st; 
}

public STBuilder resolve(STBuilder st, ClassDefStmt(ClassDef classDef)) = resolve(st,classDef);
public STBuilder resolve(STBuilder st, InterfaceDefStmt(InterfaceDef interfaceDef)) = resolve(st,interfaceDef);
public STBuilder resolve(STBuilder st, MethodStmt(Method method)) = resolve(st, method);
public STBuilder resolve(STBuilder st, ReturnStmt(Option[Expr] returnExpr)) = ifSome(st,returnExpr,resolve);
public STBuilder resolve(STBuilder st, StaticDeclarationStmt(list[NameWithDefault] vars)) = makeVarsStatic(st,vars);
public STBuilder resolve(STBuilder st, GlobalStmt(list[NameExprOrId] varNames)) = makeVarsGlobal(st,varNames);
public STBuilder resolve(STBuilder st, TryStmt(list[Stmt] tryBlock, list[Catch] catches)) = threadit(threadit(st,tryBlock,resolve),catches,resolve);
public STBuilder resolve(STBuilder st, ThrowStmt(Expr throwExpr)) = resolve(st,throwExpr);
public STBuilder resolve(STBuilder st, EvalExprStmt(Expr evalExpr)) = resolve(st,evalExpr);
public STBuilder resolve(STBuilder st, IfStmt(Expr ifCond, list[Stmt] trueBody, list[Stmt] falseBody)) = threadit(threadit(resolve(st,ifCond),trueBody,resolve),falseBody,resolve);
public STBuilder resolve(STBuilder st, WhileStmt(Expr whileCond, list[Stmt] whileBody)) = threadit(resolve(st,whileCond),whileBody,resolve);
public STBuilder resolve(STBuilder st, DoStmt(list[Stmt] doBody, Expr doCond)) = resolve(threadit(st,doBody,resolve),doCond);
public STBuilder resolve(STBuilder st, ForStmt(Option[Expr] initExpr, Option[Expr] condExpr, Option[Expr] incrExpr, list[Stmt] forBody)) = ifSome(threadit(ifSome(ifSome(st,ininExpr,resolve), condExpr, resolve), forBody, resolve), incrExpr, resolve);
public STBuilder resolve(STBuilder st, ForEachStmt(Expr expr, Option[Var] key, bool isRef, Var val, list[Stmt] forEachBody)) = threadit(resolve(ifSome(resolve(st,expr),key,resolve),val),forEachBody,resolve);
public STBuilder resolve(STBuilder st, SwitchStmt(Expr switchExpr, list[SwitchCase] cases)) = threadit(resolve(st,switchExpr),cases,resolve);
public STBuilder resolve(STBuilder st, BreakStmt(Option[Expr] breakExpr)) = ifSome(st,breakExpr,resolve);
public STBuilder resolve(STBuilder st, ContinueStmt(Option[Expr] continueExpr)) = ifSome(st,continueExpr,resolve);
public STBuilder resolve(STBuilder st, DeclareStmt(list[Directive] directives, list[Stmt] declareBody)) = threadit(threadit(st,directives,resolve),declareBody,resolve);
public STBuilder resolve(STBuilder st, NopStmt()) = st;

//
// Resolve names in directives. We resolve the expression, even though they shouldn't contain
// names (they should be literals of some sort). We don't both to resolve the directive names,
// since there are currently only two, and we don't care about them right now.
//
public STBuilder resolve(STBuilder st, Directive(Id directiveName, Expr expr)) = resolve(st,expr);
		
//
// Resolve names in switch cases.
//
public STBuilder resolve(STBuilder st, SwitchCase(Option[Expr] expr, list[Stmt] caseBody)) = threadit(ifSome(st,expr,resolve),caseBody,resolve);

//
// Resolve names in catch clauses.
//
public STBuilder resolve(STBuilder st, c:Catch(Id className, Id varName, list[Stmt] catchBlock)) {
	// First, get back the type name. This is the type of the exception being caught. If this type
	// has not yet been defined, add it as a generic type placeholder -- we don't know yet if this
	// will be an interface or a class
	if (Some(tid) := lookupGlobalTypeName(st, className)) {
		st.itemUses = st.itemUses + < className@at, tid >;
	} else {
		Item item = TypePlaceholder(className, last(st.scopeStack), c@at);
		< st, tid > = addItemIntoGlobalScope(st, item);
		st.itemUses = st.itemUses + < className@at, tid >;
	}
	
	// Second, either link up or add in the variable named by varName.
	if (Some(vid) := lookupName(st, varName)) {
		st.itemUses = st.itemUses + < varName@at, vid >;
	} else {
		Item item = Variable(varName, Some(className), false, false, head(st.scopeStack), c@at);
		< st, vid > = addItemIntoCurrentScope(st, item);
		st.itemUses = st.itemUses + < varName@at, vid >;
	}
	
	st = threadit(st, catchBlock, resolve);
	
	return st;
}

//
// Resolve names in expressions.
//		
public STBuilder resolve(STBuilder st, AssignmentExpr(Var assignTo, bool isRef, Expr assignExpr)) = resolve(resolve(st,assignExpr),assignTo);
public STBuilder resolve(STBuilder st, Expr ce:CastExpr(Id cast, Expr castExpr)) {
	// First, get back the type name. If this type has not yet been defined, add it as a 
	// generic type placeholder -- we don't know yet if this will be an interface or a class
	if (Some(tid) := lookupGlobalTypeName(st, cast)) {
		st.itemUses = st.itemUses + < cast@at, tid >;
	} else {
		Item item = TypePlaceholder(cast, last(st.scopeStack), ce@at);
		< st, tid > = addItemIntoGlobalScope(st, item);
		st.itemUses = st.itemUses + < cast@at, tid >;
	}
	return resolve(st, castExpr);
}
public STBuilder resolve(STBuilder st, UnaryOpExpr(Op op, Expr expr)) = resolve(st,expr);
public STBuilder resolve(STBuilder st, BinOpExpr(Expr left, Op op, Expr right)) = resolve(resolve(st,left),right);
// TODO: Check this, the AST name and type of the first projection are not consistent
public STBuilder resolve(STBuilder st, Expr ce:ConstantExpr(Option[Id] constantNameExprOrId, Id constantName)) {
	// TODO: Need to add support for class references for class constants
	if (Some(_) := constantNameExprOrId) throw "We do not yet support class constants: <ce>";
	
	// Second, either link up or add in the constant named by constantName.
	if (Some(cid) := lookupName(st, constantName)) {
		st.itemUses = st.itemUses + < constantName@at, cid >;
	} else {
		Item item = Constant(constantName, head(st.scopeStack), ce@at);
		< st, cid > = addItemIntoCurrentScope(st, item);
		st.itemUses = st.itemUses + < constantName@at, cid >;
	}

	return st;
}
public STBuilder resolve(STBuilder st, ie:InstanceofExpr(Expr instanceExpr, NameExprOrId instanceNameExprOrId)) {
	if (NameExpr(_) := instanceNameExprOrId) throw "We do not yet handle variable variables: <instanceNameExprOrId>";
	if (NameId(x) := instanceNameExprOrId) {
		if (Some(tid) := lookupGlobalTypeName(st, x)) {
			st.itemUses = st.itemUses + < x@at, tid >;
		} else {
			Item item = TypePlaceholder(x, last(st.scopeStack), ie@at);
			< st, tid > = addItemIntoGlobalScope(st, item);
			st.itemUses = st.itemUses + < x@at, tid >;
		}
	}
	return resolve(st, instanceExpr);
}
public STBuilder resolve(STBuilder st, VariableExpr(Var var)) = resolve(st,var);
public STBuilder resolve(STBuilder st, PreOpExpr(Op op, Var var)) = resolve(st,var);
public STBuilder resolve(STBuilder st, me:MethodInvocationExpr(Option[NameExprOrId] target, NameExprOrId methodName, list[ActualParameter] parameters)) {
	if (Some(NameExpr(_)) := target) throw "We do not yet handle computed targets: <target>";
	if (NameExpr(_) := methodName) throw "We do not yet handle variable variables: <methodName>";

	if (Some(NameId(tx)) := target) {
		// TODO: Here we have a target. We need to do type inference to figure out the target type
		// before we can link the method to possible implementations. So, link up the target, but
		// ignore the method name for now. We could link in a placeholder, but this would not work
		// if we had calls to two different methods that happen to have the same name -- we don't
		// want them to be inadvertently linked, which would assume that they were related.
		if (Some(tid) := lookupName(st, tx)) {
			st.itemUses = st.itemUses + < tx@at, tid >;
		} else {
			Item item = Variable(tx, None(), false, false, head(st.scopeStack), me@at);
			< st, vid > = addItemIntoCurrentScope(st,item);
			st.itemUses = st.itemUses + < tx@at, vid >;		
		}
	} else {
		// We do not have a target. So, this has to be a function at the global level.
		if (NameId(mx) := methodName, Some(mid) := lookupGlobalName(st, mx)) {
			st.itemUses = st.itemUses + < mx@at, mid >;
		} else {
			Item item = MethodPlaceholder(mx, last(st.scopeStack), me@at);
			< st, mid > = addItemIntoCurrentScope(st,item);
			st.itemUses = st.itemUses + < mx@at, mid >;		
		}
	}
	return threadit(st, parameters, resolve);
}
public STBuilder resolve(STBuilder st, ne:NewExpr(NameExprOrId className, list[ActualParameter] parameters)) {
	if (NameExpr(_) := className) throw "We do not yet handle variable variables: <className>";
	if (NameId(x) := className) {
		if (Some(tid) := lookupGlobalTypeName(st, x)) {
			st.itemUses = st.itemUses + < x@at, tid >;
		} else {
			Item item = ClassPlaceholder(x, last(st.scopeStack), ne@at);
			< st, tid > = addItemIntoGlobalScope(st, item);
			st.itemUses = st.itemUses + < x@at, tid >;
		}
	}
	return threadit(st, parameters, resolve);
}
public STBuilder resolve(STBuilder st, LiteralExpr(Lit literal)) = resolve(st,literal);
public STBuilder resolve(STBuilder st, OpAssignmentExpr(Var var, Op op, Expr expr)) = resolve(resolve(st,expr),var);
public STBuilder resolve(STBuilder st, ListAssignmentExpr(None(), Expr expr)) = resolve(st,expr);
public STBuilder resolve(STBuilder st, ListAssignmentExpr(Some(list[ListElement] listElements), Expr expr)) = resolve(threadit(st,listElements,resolve),expr);
public STBuilder resolve(STBuilder st, PostOpExpr(Var var, Op op)) = resolve(st,var);
public STBuilder resolve(STBuilder st, ArrayExpr(list[ArrayElement] arrayElements)) = threadit(st,arrayElements,resolve);
public STBuilder resolve(STBuilder st, ConditionalExpr(Expr cond, Expr ifTrue, Expr ifFalse)) = resolve(resolve(resolve(st,cond),ifTrue),ifFalse);
public STBuilder resolve(STBuilder st, IgnoreErrorsExpr(Expr expr)) = resolve(st,expr);
	
// List Elements
public STBuilder resolve(STBuilder st, VarListElement(Var var)) = resolve(st,var);
public STBuilder resolve(STBuilder st, NestedListElements(None())) = st;
public STBuilder resolve(STBuilder st, NestedListElements(Some(list[ListElement] elements))) = threadit(st,elements,resolve);
	
// Array Elements
public STBuilder resolve(STBuilder st, ArrayElement(Option[Expr] key, bool isRef, Expr val)) = resolve(ifSome(st,key,resolve),val);
	 
// Literals 
public STBuilder resolve(STBuilder st, IntLit(int intVal)) = st;
public STBuilder resolve(STBuilder st, RealLit(real realVal)) = st;
public STBuilder resolve(STBuilder st, StringLit(str strVal)) = st;
public STBuilder resolve(STBuilder st, BoolLit(bool boolVal)) = st;
public STBuilder resolve(STBuilder st, NilLit()) = st;
	
// Vars
public STBuilder resolve(STBuilder st, v:Var(Option[NameExprOrId] target, NameExprOrId varName, Option[list[Expr]] arrayIndices)) {
	if (Some(NameExpr(_)) := target) throw "We do not yet handle computed targets: <target>";
	if (NameExpr(_) := varName) throw "We do not yet handle variable variables: <varName>";

	if (Some(NameId(tx)) := target) {
		// TODO: Here we have a target. We need to do type inference to figure out the target type
		// before we can link the var to possible implementations. So, link up the target, but
		// ignore the var name for now. We could link in a placeholder, but this would not work
		// if we had references to two different vars that happen to have the same name -- we don't
		// want them to be inadvertently linked, which would assume that they were related.
		if (Some(tid) := lookupName(st, tx)) {
			st.itemUses = st.itemUses + < tx@at, tid >;
		} else {
			Item item = Variable(tx, None(), false, false, head(st.scopeStack), v@at);
			< st, vid > = addItemIntoCurrentScope(st,item);
			st.itemUses = st.itemUses + < tx@at, vid >;		
		}
	} else {
		// We do not have a target. So, this has to be a local variable (or a global, but
		// that is being handled later, during alias analysis).
		if (NameId(vx) := varName, Some(vid) := lookupName(st, vx)) {
			st.itemUses = st.itemUses + < vx@at, vid >;
		} else {
			Item item = Variable(vx, None(), false, false, head(st.scopeStack), v@at);
			< st, vid > = addItemIntoCurrentScope(st,item);
			st.itemUses = st.itemUses + < vx@at, vid >;		
		}
	}
	
	if (Some(lexpr) := arrayIndices)
		return threadit(st, lexpr, resolve);
	else
		return st;
}

// Actual Parameter values
public STBuilder resolve(STBuilder st, ActualParameter(bool isRef, Expr expr)) = resolve(st,expr);
