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

import Node;
import IO;
import Set;

public alias SplitScript = map[NamePath,node];

public SplitScript splitScript(node scr) {
	println("INFO: Splitting script into individual functions/methods");
	SplitScript ss = ( );
	if (script(bs) := scr) {
		gbody = [ b | b <- bs, getName(b) notin { "class_def", "interface_def", "method" }];
		ss[[global()]] = "script"(gbody);
		
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

	}
	
	return ss; 
}
