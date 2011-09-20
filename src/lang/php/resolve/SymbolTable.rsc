@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::resolve::SymbolTable

import lang::php::ast::AbstractSyntax;
import lang::php::util::Option;
import lang::php::types::Types;

import Node;
import Relation;
import Set;

//
// Namespaces in PHP.
// TODO: Add the proper namespaces.
//
// Types is the namespace for class and interface names.
// Names is the namespace for variables.
//
data Namespace = Types() | Names() ;

//
// Each item in the symbol table is given a unique ID. This also allows
// for recursive definitions then, since we don't need to include the item
// itself, just its id.
//
alias ItemId = int;

//
// Items in the symbol table. These represent methods, variable names, etc,
// as well as the actual kinds of scopes -- functions, blocks, etc.
//
data Item
    = GlobalScope()
    | ModuleScope(Id moduleName)
	| Class(Id className, Option[ItemId] extendsClass, list[ItemId] implements, list[ItemId] members, bool isAbstract, bool isFinal, ItemId parentId, loc definedAt)
	| ClassPlaceholder(Id className, ItemId parentId, loc definedAt)
	| Interface(Id interfaceName, list[ItemId] extends, list[ItemId] members, ItemId parentId, loc definedAt)
	| InterfacePlaceholder(Id interfaceName, ItemId parentId, loc definedAt)
	| TypePlaceholder(Id typeName, ItemId parentId, loc definedAt)
	| Attribute(Id attrName, Option[Type] attrType, bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isConst, ItemId parentId, loc definedAt)
	| Method(Id methodName, Option[Type] methodType, list[ItemId] params, bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isAbstract, bool isFinal, bool isRef, ItemId parentId, loc definedAt)
	| MethodPlaceholder(Id methodName, ItemId parentId, loc definedAt)
    | FormalParameter(Id parameterName, Option[Type] parameterType, bool isRef, ItemId parentId, loc definedAT)
	| Variable(Id variableName, Option[Type] variableType, bool isStatic, bool isGlobal, ItemId parentId, loc definedAt)
	| Constant(Id constantName, ItemId parentId, loc definedAt)
;

public bool hasName(Item item) {
	return getName(item) in { "ModuleScope", "FormalParameter", "Variable", "Class", "Interface", "Attribute",
							  "Method", "ClassPlaceholder", "InterfacePlaceholder", "TypePlaceholder",
							  "Constant", "MethodPlaceholder" };
}

test bool t_hasName_01() = hasName(GlobalScope()) == false;
test bool t_hasName_02() = hasName(ModuleScope(Id("M1"))) == true;

public Id getName(Item item) {
	switch(item) {
		case ModuleScope(mn) : return mn;
		case FormalParameter(fp,_,_,_,_) : return fp;
		case Variable(vid,_,_,_,_,_) : return vid;
		case Class(cn,_,_,_,_,_,_,_) : return cn;
		case ClassPlaceholder(cn,_,_) : return cn;
		case Interface(ifn,_,_,_,_) : return ifn;
		case InterfacePlaceholder(ifn,_,_) : return ifn;
		case Attribute(fn,_,_,_,_,_,_,_,_) : return fn;
		case Method(mn,_,_,_,_,_,_,_,_,_,_,_) : return mn;
		case TypePlaceholder(tn,_,_) : return tn;
		case Constant(cn,_,_) : return cn;
		case MethodPlaceholder(mn,_,_) : return mn;
	}
}

test bool t_getName_01() = getName(ModuleScope(Id("M1"))) == Id("M1");

data STBuilder = STBuilder(
    rel[ItemId scopeId, ItemId itemId] scopeRel,
    rel[ItemId scopeId, Id itemName, ItemId itemId] scopeNames,
    rel[loc useLoc, ItemId usedItem] itemUses, // relates locations in the tree to the items that are used at those locations
    list[ItemId] scopeStack, 
    map[ItemId,Item] scopeItemMap, 
    ItemId nextScopeId
);

//
// Create an empty STBuilder. Each builder will start with a global scope at the top, but nothing
// else. If we want a module scope, etc, we need to add that in the invoker.
//
public STBuilder createNewSTBuilder() {
	return STBuilder( { }, { }, { }, [ 0 ], ( 0 : GlobalScope() ), 1 );
}         

public tuple[STBuilder,ItemId] addItemIntoCurrentScope(STBuilder st, Item item) {
	return addItemIntoScope(st, item, head(st.scopeStack));
}

public tuple[STBuilder,ItemId] addItemIntoGlobalScope(STBuilder st, Item item) {
	return addItemIntoScope(st, item, last(st.scopeStack));
}

public tuple[STBuilder,ItemId] addItemIntoScope(STBuilder st, Item item, ItemId parentScopeId) {
	ItemId nextId = st.nextScopeId;
	st.nextScopeId = st.nextScopeId + 1;
	st.scopeItemMap = st.scopeItemMap + ( nextId : item );
	st.scopeRel = st.scopeRel + < parentScopeId, nextId >;
	if (hasName(item)) st.scopeNames = st.scopeNames + < parentScopeId, getName(item), item >;
	return < st, nextId >;
}

public STBuilder pushScope(STBuilder st, ItemId itemId) {
	st.scopeStack = [ itemId ] + st.scopeStack;
	return st;
}

public STBuilder popScope(STBuilder st) {
	st.scopeStack = tail(st.scopeStack);
	return st;
}

public Option[ItemId] lookupName(STBuilder st, Id x) {
	return lookup(st, head(st.scopeStack), x, Names());
}

public Option[ItemId] lookupGlobalName(STBuilder st, Id x) {
	return lookup(st, last(st.scopeStack), x, Names());
}

public Option[ItemId] lookupTypeName(STBuilder st, Id x) {
	return lookup(st, head(st.scopeStack), x, Types());
}

public Option[ItemId] lookupGlobalTypeName(STBuilder st, Id x) {
	return lookup(st, last(st.scopeStack), x, Types());
}

private rel[Namespace,str] namespaceItems = { < Types(), "Class" >, < Types(), "ClassPlaceholder" >, 
	< Types(), "Interface" > , < Types(), "InterfacePlaceholder" >,
	< Names(), "FormalParameter" >, < Names(), "Variable" >, < Names(), "Attribute" >, 
	< Names(), "Method" >, < Types(), "TypePlaceholder" >, < Names(), "Constant" >,
	< Names(), "MethodPlaceholder" > };
	
private Option[ItemId] lookup(STBuilder st, ItemId scope, Id x, Namespace ns) {
	set[ItemId] items = st.scopeNames[scope,x];
	items = { item | item <- items, getName(item) in namespaceItems[ns] };
	if (size(items) == 0) return None();
	if (size(items) == 1) return Some(getOneFrom(items));
	throw "Found too many items, scope <scope>, name <x.idValue>, items <items>";
}