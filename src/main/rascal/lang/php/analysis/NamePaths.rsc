@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::NamePaths

import String;
import IO;

@doc{Define name paths, which are equivalent to M3 locs}
//alias NamePath = loc;

public loc addLibrary(loc l, str library) = l when size(trim(library)) == 0;
public loc addLibrary(loc l, str library) = l[authority=cleanString(library)] when size(trim(library)) > 0;

public str cleanString(str input) {
	goodChars = "abcdefghijklmnopqrstuvwxzyABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";
	newString = "";
	input = trim(input);
	for (i <- [0..size(input)], findFirst(goodChars,input[i]) != -1) {
		newString += input[i];
	}
	if (size(newString) == 0) {
		newString = "PLACEHOLDER";
		println("WARNING: discarded all characters from input <input>");
	}
	return newString;
}

@doc{Create name paths for a function, with or without an explicit namespace}
public loc functionPath(str fname, str library="", str namespace="") = 
	addLibrary(|php+function:///<cleanString(fname)>|,library) when size(trim(namespace)) == 0;
public loc functionPath(str fname, str library="", str namespace="") = 
	addLibrary(|php+function:///<cleanString(namespace)>/<cleanString(fname)>|,library) when size(trim(namespace)) > 0;

@doc{Check to see if the provided path is for a PHP function}
public bool isFunctionPath(loc path) = path.scheme == "php+function";

@doc{Get the name of the function defined by the path}
public str getFunctionName(loc functionPath) {
	if (isFunctionPath(functionPath)) {
		return functionPath.file;
	} else {
		throw "Invalid path: <functionPath>";
	}
}

@doc{Create name paths for a closure, with or without an explicit namespace}
public loc closurePath(loc closureLoc, str library="", str namespace="") =
	addLibrary(|php+closure:///<cleanString(closureLoc.file)>/<closureLoc.offset>/<closureLoc.length>|,library) when size(trim(namespace)) == 0;
public loc closurePath(loc closureLoc, str library="", str namespace="") = 
	addLibrary(|php+closure:///<cleanString(namespace)>/<cleanString(closureLoc.file)>/<closureLoc.offset>/<closureLoc.length>|,library) when size(trim(namespace)) > 0;

@doc{Check to see if the provided path is for a PHP closure}
public bool isClosurePath(loc path) = path.scheme == "php+closure";
	
@doc{Create name paths for a regular constant, with or without an explicit namespace}
public loc constPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(cname)>|,library) when size(trim(namespace)) == 0;
public loc constPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(namespace)>/<cleanString(cname)>|,library) when size(trim(namespace)) > 0;

@doc{Check to see if the provided path is for a PHP constant}
public bool isConstPath(loc path) = path.scheme == "php+constant" && path.parent.file == "";

@doc{Get the name of the constant defined by the path}
public str getConstName(loc constPath) {
	if (isConstPath(constPath)) {
		return constPath.file;
	} else {
		throw "Invalid path: <constPath>";
	}
}

@doc{Create name paths for a class, with or without an explicit namespace}
public loc classPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+class:///<cleanString(cname)>|,library) when size(trim(namespace)) == 0;
public loc classPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+class:///<cleanString(namespace)>/<cleanString(cname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for an interface, with or without an explicit namespace}
public loc interfacePath(str iname, str library="", str namespace="") = 
	addLibrary(|php+interface:///<cleanString(iname)>|,library) when size(trim(namespace)) == 0;
public loc interfacePath(str iname, str library="", str namespace="") = 
	addLibrary(|php+interface:///<cleanString(namespace)>/<cleanString(iname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a trait, with or without an explicit namespace}
public loc traitPath(str tname, str library="", str namespace="") = 
	addLibrary(|php+trait:///<cleanString(tname)>|,library) when size(trim(namespace)) == 0;
public loc traitPath(str tname, str library="", str namespace="") = 
	addLibrary(|php+trait:///<cleanString(namespace)>/<cleanString(tname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a method, with or without an explicit namespace}
public loc methodPath(str cname, str mname, str library="", str namespace="") = 
	addLibrary(|php+method:///<cleanString(cname)>/<cleanString(mname)>|,library) when size(trim(namespace)) == 0;
public loc methodPath(str cname, str mname, str library="", str namespace="") = 
	addLibrary(|php+method:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(mname)>|,library) when size(trim(namespace)) > 0;

@doc{Check to see if the provided path is for a PHP method}
public bool isMethodPath(loc path) = path.scheme == "php+method";

@doc{Get the name of the function defined by the path}
public str getMethodClassName(loc methodPath) {
	if (isMethodPath(methodPath)) {
		return methodPath.parent.file;
	} else {
		throw "Invalid path: <methodPath>";
	}
}

@doc{Get the name of the function defined by the path}
public str getMethodName(loc methodPath) {
	if (isMethodPath(methodPath)) {
		return methodPath.file;
	} else {
		throw "Invalid path: <methodPath>";
	}
}

@doc{Create name paths for a field, with or without an explicit namespace}
public loc fieldPath(str cname, str fname, str library="", str namespace="") = 
	addLibrary(|php+field:///<cleanString(cname)>/<cleanString(fname)>|,library) when size(trim(namespace)) == 0;
public loc fieldPath(str cname, str fname, str library="", str namespace="") = 
	addLibrary(|php+field:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(fname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a class constant, with or without an explicit namespace}
public loc classConstPath(str cname, str constName, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(cname)>/<cleanString(constName)>|,library) when size(trim(namespace)) == 0;
public loc classConstPath(str cname, str constName, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(constName)>|,library) when size(trim(namespace)) > 0;
	
@doc{Check to see if the provided path is for a PHP class constant}
public bool isClassConstPath(loc path) = path.scheme == "php+constant" && path.parent.file != "";

@doc{Get the name of the class and constant defined by the path}
public tuple[str className, str constName] getClassConstInfo(loc constPath) {
	if (isClassConstPath(constPath)) {
        return < constPath.parent.file, constPath.file >;
    } else {
        throw "Invalid path: <constPath>";
    }
}

@doc{Get the name of the class containing the constant defined by the path}
public str getClassConstClassName(loc constPath) = getClassConstInfo(constPath).className;

@doc{Get the name of the constant defined by the path}
public str getClassConstName(loc constPath) = getClassConstInfo(constPath).constName;

@doc{Create name paths for a script, with or without an explicit namespace}
public loc scriptPath(str library, str namespace="") = 
	addLibrary(|php+script:///|,library) when size(trim(namespace)) == 0;
public loc scriptPath(str library, str namespace="") = 
	addLibrary(|php+script:///|,library) when size(trim(namespace)) > 0;
	