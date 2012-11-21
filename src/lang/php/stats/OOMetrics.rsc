module lang::php::stats::OOMetrics

import List;
import Relation;

import lang::php::ast::AbstractSyntax;

public list[ClassDef] getClasses(map[loc,Script] product) = [ c | /ClassDef c := product ];
public list[InterfaceDef] getInterfaces(map[loc,Script] product) = [ i | /InterfaceDef i := product ];
public list[ClassItem] getMethods(map[loc,Script] product) = [ m |  /m:method(_, _, _, _, _) := product ];
public list[Property] getProperties(map[loc,Script] product) = [ p | /property(_, list[Property] prop) := product, p <- prop ];
public list[ClassItem] getPropertyDecls(map[loc,Script] product) = [ p | /p:property(_, _) := product ];
public list[Stmt] getFunctions(map[loc,Script] product) = [ f | /f:function(_,_,_,_) := product ];

public int classesCount(map[loc,Script] product) {
	return size(getClasses(product));
}

public int interfaceCount(map[loc,Script] product) {
	return size(getInterfaces(product));
}

public int methodCount(map[loc,Script] product) {
	return size(getMethods(product));
}

public int propertyCount(map[loc,Script] product) {
	return size(getProperties(product));
}

public int functionCount(map[loc,Script] product) {
	return size(getFunctions(product));
}

public rel[loc classLoc, str className, ClassItem method] methodsPerClass(map[loc,Script] product) {
	return { < l, className, m > | l <- product, 
		/class(str className, _, _, _, list[ClassItem] members) := product[l],
		/m:method(_, _, _, _, _) <- members };
}

public rel[loc ifcLoc, str ifcName, ClassItem method] methodsPerInterface(map[loc,Script] product) {
	return { < l, ifcName, m > | l <- product, 
		/interface(str ifcName, _, list[ClassItem] members) := product[l],
		/m:method(_, _, _, _, _) <- members };
}

public rel[str parent, str child] inheritsRelation(map[loc,Script] product) {
	return { < extendsName, className > | class(className, _, someName(name(str extendsName)), _, _) <- getClasses(product) };
}

public rel[str parent, str child] implementsRelation(map[loc,Script] product) {
	return { < implementsName, className > | class(className, _, _, implementsNames, _) <- getClasses(product), name(str implementsName) <- implementsNames };
}

public rel[str parent, str child] extendsRelation(map[loc,Script] product) {
	return { < extendsName, ifcName > | interface(ifcName, extendsNames, _) <- getInterfaces(product), name(str extendsName) <- extendsNames };
}

public map[str child,list[str] parents] inheritsChains(map[loc,Script] product) {
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

public map[int size, int count] methodSizes(map[loc,Script] product) {
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