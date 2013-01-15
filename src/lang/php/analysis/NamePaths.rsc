@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::NamePaths

//
// TODO: We need some way to encode the dynamic scopes of PHP here; for instance,
// to encode that a function could be defined in one way on one branch of a conditional,
// and in another way on another. This code assumes that we have a unique initial
// introduction of a name in the code.
@doc{Component parts of the name path.}
data NamePart 
	= root() 
	| global()
	| library(str libName) 
	| class(str className)
	| interface(str interfaceName)
	| function(str functionName)
	| method(str methodName) 
	| field(str fieldName) 
	| var(str varName) 
	| const(str constName)
	| arrayContents() 
	;

@doc{The path, in terms of declared scoping constructs, to a name}
alias NamePath = list[NamePart];

public NamePath globalPath() = [global()];
public NamePath functionPath(str fname) = [global(),function(fname)];
public NamePath constPath(str cname) = [global(),const(cname)];
public NamePath classPath(str cname) = [class(cname)];
public NamePath methodPath(str cname, str mname) = [class(cname),method(mname)];
public NamePath classConstPath(str cname, str constName) = [class(cname),const(constName)];

public str printNamePath([global()]) = "script";
public str printNamePath([global(),function(str fn)]) = "function <fn>";
public str printNamePath([global(),const(str cn)]) = "const <cn>";
public str printNamePath([class(str cn)]) = "class <cn>";
public str printNamePath([class(str cn),method(str mn)]) = "method <cn>::<mn>";
public str printNamePath([class(str cn),const(str constName)]) = "class const <cn>::<constName>";

