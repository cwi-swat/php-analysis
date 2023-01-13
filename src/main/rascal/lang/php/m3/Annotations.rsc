module lang::php::m3::Annotations
extend lang::php::m3::Core;

import ParseTree;
import String;
import Set;
import List;
import Relation;

import lang::php::types::TypeSymbol;
import lang::php::parser::DocBlockParser;

public M3 fillPhpDocAnnotations(M3 m3, Script script) {
	visit (script) {
		case node n:
			if ( n@phpdoc? && n@decl? )
			{
				try {
					; // todo: add option to use annotations or not.
					//set[Annotation] annotations = parseAnnotation(n);
					//m3@annotations += { <n@decl, a> | a <- annotations };
				} catch ParseError(loc l): {
					m3@messages += error("Parse error while parsing annotation: <n@phpdoc>", n@at);
				} catch: {
					m3@messages += error("Unknown error while parsing annotation: <n@phpdoc>", n@at);
				}
			}
	}
	
	return m3;
}

public set[Annotation] parseAnnotation(node n) {
	set[Annotation] annotations = {};
	
	node nodes = implode(#node, parse(#DocBlock, n@phpdoc));
	
	set[TypeSymbol] returnTypes = getReturnTypes(nodes);
	rel[str, TypeSymbol] params = getParams(nodes);
	rel[str, TypeSymbol] varTypes = getVarTypes(nodes);
	
	// add parameter annotations
	annotations += { parameterType(types, params[var]) 	| var <- domain(params), types <- paramToLoc(var, n) };
	// add var type annotations
	annotations += { varType(types, varTypes[var]) 		| var <- domain(varTypes), types <- varToLoc(var, n) };
	
	// add return type annotations
	if (!isEmpty(returnTypes)) {
		annotations += { returnType(returnTypes) };
	}
	

	return annotations;
}

private set[loc] paramToLoc(str var, Stmt::function(_,_,list[Param] params,_)) 
	= { p@decl | p <- params, p.paramName == var[1..] };
private set[loc] paramToLoc(str var, ClassItem::method(_,_,_,list[Param] params,_)) 
	= { p@decl | p <- params, p.paramName == var[1..] };
default set[loc] paramToLoc(str var, node n) = {};

// return a set so it also can be empty
private set[loc] varToLoc(str var, node n)
{
	varName = var[1..]; // remove the first char
	
	if (var(name(name(str name))) := n && name == varName) {
		return ((n@decl?) ? { n@decl } : {}); // return the decl is available
	}

	println("varToLoc Error: var \'<var>\' is not found in node \'<n>\'"); 
	return {};	
}

private set[TypeSymbol] getReturnTypes(node nodes) = { toTypeSymbol(t) | /"return"("types"(types)) <- nodes, t <- types };
private rel[str, TypeSymbol] getParams(node nodes) = { <var, toTypeSymbol(t)> | /"param"(<"types"(types),"variable"(str var)>) <- nodes, t <- types };
private rel[str, TypeSymbol] getVarTypes(node nodes) = { <var, toTypeSymbol(t)> | /"var"(<"types"(types),"variable"(str var)>) <- nodes, t <- types };

private TypeSymbol toTypeSymbol("int"()) = \int();
private TypeSymbol toTypeSymbol("string"()) = string();
private TypeSymbol toTypeSymbol("mixed"()) = mixed();
private TypeSymbol toTypeSymbol("null"()) = \null();
private TypeSymbol toTypeSymbol("class"(str className)) = class(className);
default TypeSymbol toTypeSymbol(node n) { throw("Type \'<n>\' is not supported"); }