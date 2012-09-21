@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::Split

import lang::php::analysis::NamePaths;
import lang::php::ast::AbstractSyntax;
import IO;
import Set;

@doc{The items we split the script into. This includes functions, methods, and the various
     statements that sit at the top level and form the global scope.}
public data SplitItem
	= globalItem(list[Stmt])
	| functionItem(str name, bool byRef, list[Param] params, list[Stmt] body)
	| methodItem(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)
	;
	
@doc{The representation of the script, after splitting. This is a map from names to the item that
     actually defines that name.}
public alias SplitScript = map[NamePath,SplitItem];

@doc{Split the script into it's component parts.}
public SplitScript splitScript(Script scr) {
	if (script(body) := scr) {
		SplitScript ss = ( [global()] :  globalItem(scr.body) );

		for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),_) <- bs)
			ss[[global(),method(mn)]] = f;
			
		for (c:class_def(_,_,class_name(cn),_,_,members(ml)) <- bs) {
			for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),_) <- ml)
				ss[[class(cn),method(mn)]] = f;
			for (a:attribute(_,_,_,_,_,name(variable_name(n),_)) <- ml)
				ss[[class(cn),var(n)]] = a;
		}

		for (i:interface_def(interface_name(cn),_,members(ml)) <- bs) {
			for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),_) <- ml)
				ss[[class(cn),method(mn)]] = f;
			for (a:attribute(_,_,_,_,_,name(variable_name(n),_)) <- ml)
				ss[[class(cn),var(n)]] = a;
		}
		
		return ss;
	}
	
	return ( ); 
}
