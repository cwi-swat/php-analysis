@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::Split

import Node;
import IO;
import Set;

data Owner = globalOwns() | classOwns(str className) | interfaceOwns(str interfaceName);

public alias SplitScript = rel[Owner,str,list[node]];

public SplitScript splitScript(node scr) {
	println("Splitting script into individual functions/methods");
	if (script(list[node] body) := scr) {
		return splitScript(globalOwns(), "***toplevel", body);
	}
	
	return { }; 
}

public SplitScript splitScript(Owner ow, str s, list[node] bs) {
	list[node] myBody = [ ];
	
	// First, grab back the parts of the body that are not either members/functions, classes, or interfaces
	for (b <- bs, getName(b) notin { "class_def", "interface_def", "method" })
		myBody = myBody + b;
	SplitScript res = { < ow, s, myBody > };

	// Now, process all the meothods in any included classes	
	for (class_def(_,_,class_name(cn),_,_,members(list[node] ms)) <- bs, method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),body(list[node] mb)) <- ms)
		res = res + splitScript(classOwns(cn),mn,mb);
		
	// Do the same for interfaces
	for (interface_def(interface_name(cn),_,members(list[node] ms)) <- bs, method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),body(list[node] mb)) <- ms)
		res = res + splitScript(interfaceOwns(cn),mn,mb);

	// Finally, handle any methods directly given at the global level
	for (method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),_),body(list[node] mb)) <- bs)
		res = res + splitScript(globalOwns(),mn,mb);
		
	return res;
}

public set[node] getTopLevelFunctions(node n) {
	return { bi | script(b) := n, bi <- b, getName(bi) == "method"};
}

public set[node] getClasses(node n) {
	return { bi | script(b) := n, bi <- b, getName(bi) == "class_def"};
}

public set[node] getInterfaces(node n) {
	return { bi | script(b) := n, bi <- b, getName(bi) == "interface_def"};
}

public set[node] getUserTypes(node n) {
	return getClasses(n) + getInterfaces(n);
}

public node getClass(node n, str className) {
	return getOneFrom({ bi | script(b) := n, bi:class_def(_,_,class_name(className),_,_,members(list[node] ms)) <- b});
}

public node getInterface(node n, str interfaceName) {
	return getOneFrom({ bi | script(b) := n, bi:interface_def(interface_name(interfaceName),_,members(list[node] ms)) <- b});
}

public set[node] getMethods(node n) {
	return { mi | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi <- ms, getName(mi) == "method" };
}

public set[node] getStaticMethods(node n) {
	return { methodName | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:method(sig:signature(_,_,_,static(true),_,_,_,_,method_name(methodName),_),body(list[node] mb)) <- ms };
}

public set[str] getMethodNames(node n) {
	return { methodName | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:method(sig:signature(_,_,_,_,_,_,_,_,method_name(methodName),_),body(list[node] mb)) <- ms };
}

public set[node] getAttributes(node n) {
	return { mi | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi <- ms, getName(mi) == "attribute" };
}

public set[node] getStaticAttributes(node n) {
	return { fieldName | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:attribute(_,_,_,static(true),_,name(variable_name(fieldName),_)) <- ms };
}

public set[str] getAttributeNames(node n) {
	return { fieldName | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:attribute(_,_,_,_,_,name(variable_name(fieldName),_)) <- ms };
}

public set[node] getMembers(node n) {
	return { mi | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi <- ms };
}

public node getMethod(node n, str methodName) {
	return getOneFrom({ mi | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:method(sig:signature(_,_,_,_,_,_,_,_,method_name(methodName),_),body(list[node] mb)) <- ms });
}

public node getAttribute(node n, str fieldName) {
	return getOneFrom({ mi | class_def(_,_,class_name(cn),_,_,members(list[node] ms)) := n || interface_def(interface_name(cn),_,members(list[node] ms)) := n, mi:attribute(_,_,_,_,_,name(variable_name(fieldName),_)) <- ms });
}

public set[str] getStaticDeclarations(node n) {
	return { vn | method(_,body(b)) := n, /static_decl(name(variable_name(vn),_),_) <- b };
}

