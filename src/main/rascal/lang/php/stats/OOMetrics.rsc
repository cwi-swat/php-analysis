@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::stats::OOMetrics

import List;
import Relation;

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;

public list[ClassDef] getClasses(System product) = [ c | /ClassDef c := product.files ];
public list[InterfaceDef] getInterfaces(System product) = [ i | /InterfaceDef i := product.files ];
public list[ClassItem] getMethods(System product) = [ m |  /m:method(_, _, _, _, _, _, _) := product.files ];
public list[Property] getProperties(System product) = [ p | /property(_, list[Property] prop, _, _, _) := product.files, p <- prop ];
public list[ClassItem] getPropertyDecls(System product) = [ p | /ClassItem p:property(_, _, _, _, _) := product.files ];
public list[Stmt] getFunctions(System product) = [ f | /f:function(_,_,_,_,_,_) := product.files ];

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
		/class(str className, _, _, _, list[ClassItem] members,_) := product.files[l],
		/m:method(_, _, _, _, _, _, _) <- members };
}

public rel[loc ifcLoc, str ifcName, ClassItem method] methodsPerInterface(System product) {
	return { < l, ifcName, m > | l <- product.files, 
		/interface(str ifcName, _, list[ClassItem] members, _) := product.files[l],
		/m:method(_, _, _, _, _, _, _) <- members };
}

public rel[str parent, str child] inheritsRelation(System product) {
	return { < extendsName, className > | class(className, _, someName(name(str extendsName)), _, _, _) <- getClasses(product) };
}

public rel[str parent, str child] implementsRelation(System product) {
	return { < implementsName, className > | class(className, _, _, implementsNames, _, _) <- getClasses(product), name(str implementsName) <- implementsNames };
}

public rel[str parent, str child] extendsRelation(System product) {
	return { < extendsName, ifcName > | interface(ifcName, extendsNames, _, _) <- getInterfaces(product), name(str extendsName) <- extendsNames };
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
	
	return ( c.className : chainAux(c.className) | c <- getClasses(product), c has className );
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
	map[int size, int count] res = ( );
	for (method(_, _, _, _, list[Stmt] body, _, _) <- getMethods(product)) {
		msize = size([ s | /Stmt s := body]);
		if (msize in res)
			res[msize] += 1;
		else
			res[msize] = 1;
	}
	return res;
}