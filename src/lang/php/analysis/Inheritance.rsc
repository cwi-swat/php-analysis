@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::Inheritance

import Graph;

//
// Calculate the inheritance graph. For classes that do not extend other classes, we just add them
// as extending themselves.
//
public alias InheritanceGraph = Graph[str];

public InheritanceGraph calculateInheritance(node scr) {
	return { < (extends(class_name(cn2)) := e) ? cn2 : cn, cn > | script(n) := scr, class_def(abstract(a),final(f),class_name(cn),e,implements(il),members(ml)) <- n };
}
 
public set[str] getDefinedClasses(node scr) {
	return { cn | script(n) := scr, class_def(abstract(a),final(f),class_name(cn),e,implements(il),members(ml)) <- n };
}

//
// Calculate which classes define which fields, including through inheriting the field. We don't
// make any distinction here between a field that is inherited and one that is defined inside the
// class itself.
//
public alias FieldsRel = Graph[str];

public FieldsRel calculateFieldsRel(node scr, InheritanceGraph ig) {
	rel[str,str] definers = { < cn, fn > | script(n) := scr, class_def(_,_,class_name(cn),_,_,members(ml)) <- n, attribute(_,_,_,_,_,name(variable_name(fn),_)) <- ml };
	solve(definers) {
		definers = definers + { < cn, fn > | pn <- definers<0>, cn <- ig[pn], fn <- definers[pn] }; 
	}
	return definers;
}
 
//
// Calculate which classes define which methods, including through inheriting the method. We don't
// make any distinction here between a method that is inherited and one that is defined inside the
// class itself. Note that we also don't account for security settings here, so in some cases
// this will be an over-approximation.
//
public alias MethodsRel = Graph[str];

public MethodsRel calculateMethodsRel(node scr, InheritanceGraph ig) {
	rel[str,str] definers = { < cn, mn > | script(n) := scr, class_def(_,_,class_name(cn),_,_,members(ml)) <- n, method(signature(_,_,_,_,_,_,_,_,method_name(mn),_),_) <- ml };
	igtrans = ig+;
	solve(definers) {
		definers = definers + { < cn, mn > | pn <- definers<0>, cn <- ig[pn], mn <- definers[pn] }; 
	}
	return definers;
}
 