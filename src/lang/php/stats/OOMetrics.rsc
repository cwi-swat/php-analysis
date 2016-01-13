module lang::php::stats::OOMetrics

import List;
import Relation;

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;

public list[ClassDef] getClasses(System product) = [ c | /ClassDef c := product.files ];
public list[InterfaceDef] getInterfaces(System product) = [ i | /InterfaceDef i := product.files ];
public list[ClassItem] getMethods(System product) = [ m |  /m:method(_, _, _, _, _) := product.files ];
public list[Property] getProperties(System product) = [ p | /property(_, list[Property] prop) := product.files, p <- prop ];
public list[ClassItem] getPropertyDecls(System product) = [ p | /p:property(_, _) := product.files ];
public list[Stmt] getFunctions(System product) = [ f | /f:function(_,_,_,_) := product.files ];

public int classesCount(System product) {
	return size(getClasses(product));
}

public int interfaceCount(System product) {
	return size(getInterfaces(product));
}

public int methodCount(System product) {
	return size(getMethods(product));
}

public int propertyCount(System product) {
	return size(getProperties(product));
}

public int functionCount(System product) {
	return size(getFunctions(product));
}

public rel[loc classLoc, str className, ClassItem method] methodsPerClass(System product) {
	return { < l, className, m > | l <- product.files, 
		/class(str className, _, _, _, list[ClassItem] members) := product.files[l],
		/m:method(_, _, _, _, _) <- members };
}

public rel[loc ifcLoc, str ifcName, ClassItem method] methodsPerInterface(System product) {
	return { < l, ifcName, m > | l <- product.files, 
		/interface(str ifcName, _, list[ClassItem] members) := product.files[l],
		/m:method(_, _, _, _, _) <- members };
}

public rel[str parent, str child] inheritsRelation(System product) {
	return { < extendsName, className > | class(className, _, someName(name(str extendsName)), _, _) <- getClasses(product) };
}

public rel[str parent, str child] implementsRelation(System product) {
	return { < implementsName, className > | class(className, _, _, implementsNames, _) <- getClasses(product), name(str implementsName) <- implementsNames };
}

public rel[str parent, str child] extendsRelation(System product) {
	return { < extendsName, ifcName > | interface(ifcName, extendsNames, _) <- getInterfaces(product), name(str extendsName) <- extendsNames };
}

public map[str child,list[str] parents] inheritsChains(System product) {
	inheritsRev = invert(inheritsRelation(product));
	inheritsRevMap = ( c : p | <c,p> <- inheritsRev );
	
	list[str] chainAux(str c) {
		if (c in inheritsRevMap) {
			p = inheritsRevMap[c];
			return p + chainAux(p);
		} else {
			return [ ];
		}
	}
	
	return ( c.className : chainAux(c.className) | c <- getClasses(product) );
}

public map[int size, int count] chainSizes(map[str child, list[str] parents] chain) {
	map[int size, int count] res = ( );
	
	for (c <- chain) {
		sz = 1 + size(chain[c]);
		if (sz in res)
			res[sz] += 1;
		else
			res[sz] = 1;
	}
	
	return res;
}

public map[int size, int count] methodSizes(System product) {
	res = ( );
	for (method(_, _, _, _, list[Stmt] body) <- getMethods(product)) {
		msize = size([ s | /Stmt s := body]);
		if (msize in res)
			res[msize] += 1;
		else
			res[msize] = 1;
	}
	return res;
}