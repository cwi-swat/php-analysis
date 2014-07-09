@doc{
Synopsis: extends the M3 [$analysis/m3/Core] with Php specific concepts 

Description: 

}
module lang::php::m3::Core
extend analysis::m3::Core;

import lang::php::m3::AST;

import analysis::graphs::Graph;
import analysis::m3::Registry;

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::\syntax::Names;
import lang::php::util::Config;
import lang::php::util::Utils;

import Prelude;

alias M3Collection = map[loc fileloc, M3 model];

anno rel[loc from, loc to] M3@extends;      // classes extending classes and interfaces extending interfaces
anno rel[loc from, loc to] M3@implements;   // classes implementing interfaces
anno rel[loc from, loc to] M3@traitUses;    // classes using traits and traits using traits
anno rel[loc from, loc to] M3@aliases;      // class name aliases (new name -> old name)
anno rel[loc pos, str phpDoc] M3@phpDoc;    // Multiline php comments /** ... */

public loc globalNamespace = |php+namespace:///|;
public loc unknownLocation = |php+unknown:///|;

public data Language(str version="")
	= php();

public M3 createEmptyM3(loc file)
{
	m = emptyM3(file);
	
	m@extends = {};
	m@implements = {};
	m@traitUses = {};
	m@aliases = {};
	m@phpDoc = {};

	return m;
}

public bool isNamespace(loc entity) = entity.scheme == "php+namespace";
public bool isClass(loc entity) = entity.scheme == "php+class";
public bool isInterface(loc entity) = entity.scheme == "php+interface";
public bool isTrait(loc entity) = entity.scheme == "php+trait";
public bool isMethod(loc entity) = entity.scheme == "php+method";
public bool isFunction(loc entity) = entity.scheme == "php+function";
public bool isFunctionParam(loc entity) = entity.scheme == "php+functionParam";
public bool isMethodParam(loc entity) = entity.scheme == "php+methodParam"; 
public bool isParameter(loc entity) = isFunctionParam(entity) || isMethodParam(entity);
public bool isGlobalVar(loc entity) = entity.scheme == "php+globalVar";
public bool isFunctionVar(loc entity) = entity.scheme == "php+functionVar";
public bool isMethodVar(loc entity) = entity.scheme == "php+methodVar";
public bool isVariable(loc entity) = isGlobalVar(entity) || isFunctionVar(entity) || isMethodVar(entity);
public bool isField(loc entity) = entity.scheme == "php+field";
public bool isConstant(loc entity) = entity.scheme == "php+constant";
public bool isClassConstant(loc entity) = entity.scheme == "php+classConstant";

public bool isUnresolved(loc entity) = "unresolved" in entity.scheme;

@memo public set[loc] namespaces(M3 m) = {e | e <- m@declarations<name>, isNamespace(e)};
@memo public set[loc] classes(M3 m) =  {e | e <- m@declarations<name>, isClass(e)};
@memo public set[loc] interfaces(M3 m) =  {e | e <- m@declarations<name>, isInterface(e)};
@memo public set[loc] traits(M3 m) = {e | e <- m@declarations<name>, isTrait(e)};
@memo public set[loc] functions(M3 m)  = {e | e <- m@declarations<name>, isFunction(e)};
@memo public set[loc] variables(M3 m) = {e | e <- m@declarations<name>, isVariable(e)};
@memo public set[loc] methods(M3 m) = {e | e <- m@declarations<name>, isMethod(e)};
@memo public set[loc] parameters(M3 m)  = {e | e <- m@declarations<name>, isParameter(e)};
@memo public set[loc] fields(M3 m) = {e | e <- m@declarations<name>, isField(e)};
@memo public set[loc] constants(M3 m) =  {e | e <- m@declarations<name>, isconstant(e)};
@memo public set[loc] classConstants(M3 m) =  {e | e <- m@declarations<name>, isClassConstant(e)};

public set[loc] elements(M3 m, loc parent) = { e | <parent, e> <- m@containment };

@memo public set[loc] fields(M3 m, loc class) = { e | e <- elements(m, class), isField(e) };
@memo public set[loc] methods(M3 m, loc class) = { e | e <- elements(m, class), isMethod(e) };


public str normalizeName(str phpName, str \type)
{
	str name = replaceAll(phpName, "\\", "/");

	if (\type in ["namespace", "class", "interface", "trait"])
	{
		name = toLowerCase(name);
	}
	
	return name;
}

public loc nameToLoc(Name nameNode, str \type)
{
	str phpName = "";
	
    switch(getNameQualification(nameNode.name))
    {
        case fullyQualified():	phpName = nameNode.name;
        case qualified(): 		phpName = "<getNamespace(nameNode@scope).path>/<nameNode.name>";
        case unqualified(): 	phpName = "<getNamespace(nameNode@scope).path>/<nameNode.name>";
    }

	return nameToLoc(phpName, \type);
}

public loc nameToLoc(str phpName, str \type)
{
	str name = normalizeName(phpName, \type);

	if (/^\/.*$/ !:= name)
	{
		name = "/" + name;
	}

	return |php+<\type>://<name>|;
}


public loc appendName(str phpName, str \type, loc prefix)
{
	str name = normalizeName(phpName, \type);

	return |php+<\type>://<prefix.path>/<name>|;
}


public loc getNamespace(loc name)
{
	if (isNamespace(name)) return name;
	
	int partsToDiscard;
	
	if (isClass(name) || isInterface(name) || isTrait(name) || isFunction(name) || isConstant(name) || isGlobalVar(name))
	{
		partsToDiscard = 1; 
	}
	else if (isMethod(name) || isField(name) || isClassConstant(name) || isFunctionParam(name) || isFunctionVar(name))
	{
		partsToDiscard = 2;
	}
	else if (isMethodParam(name) || isMethodVar(name))
	{
		partsToDiscard = 3;
	}
	else
	{
		throw "Unknown name type: <name>";
	}
	
	namespacePath = intercalate("/", split("/", name.path)[..-partsToDiscard]);
	
	return |php+namespace:///<namespacePath>|;
}
