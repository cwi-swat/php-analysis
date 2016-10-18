@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::NamePaths

import String;
import IO;

@doc{Define name paths, which are equivalent to M3 locs}
alias NamePath = loc;

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
public NamePath functionPath(str fname, str library="", str namespace="") = 
	addLibrary(|php+function:///<cleanString(fname)>|,library) when size(trim(namespace)) == 0;
public NamePath functionPath(str fname, str library="", str namespace="") = 
	addLibrary(|php+function:///<cleanString(namespace)>/<cleanString(fname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a regular constant, with or without an explicit namespace}
public NamePath constPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(cname)>|,library) when size(trim(namespace)) == 0;
public NamePath constPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(namespace)>/<cleanString(cname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a class, with or without an explicit namespace}
public NamePath classPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+class:///<cleanString(cname)>|,library) when size(trim(namespace)) == 0;
public NamePath classPath(str cname, str library="", str namespace="") = 
	addLibrary(|php+class:///<cleanString(namespace)>/<cleanString(cname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for an interface, with or without an explicit namespace}
public NamePath interfacePath(str iname, str library="", str namespace="") = 
	addLibrary(|php+interface:///<cleanString(iname)>|,library) when size(trim(namespace)) == 0;
public NamePath interfacePath(str iname, str library="", str namespace="") = 
	addLibrary(|php+interface:///<cleanString(namespace)>/<cleanString(iname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a trait, with or without an explicit namespace}
public NamePath traitPath(str tname, str library="", str namespace="") = 
	addLibrary(|php+trait:///<cleanString(tname)>|,library) when size(trim(namespace)) == 0;
public NamePath traitPath(str tname, str library="", str namespace="") = 
	addLibrary(|php+trait:///<cleanString(namespace)>/<cleanString(tname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a method, with or without an explicit namespace}
public NamePath methodPath(str cname, str mname, str library="", str namespace="") = 
	addLibrary(|php+method:///<cleanString(cname)>/<cleanString(mname)>|,library) when size(trim(namespace)) == 0;
public NamePath methodPath(str cname, str mname, str library="", str namespace="") = 
	addLibrary(|php+method:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(mname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a field, with or without an explicit namespace}
public NamePath fieldPath(str cname, str fname, str library="", str namespace="") = 
	addLibrary(|php+field:///<cleanString(cname)>/<cleanString(fname)>|,library) when size(trim(namespace)) == 0;
public NamePath fieldPath(str cname, str fname, str library="", str namespace="") = 
	addLibrary(|php+field:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(fname)>|,library) when size(trim(namespace)) > 0;

@doc{Create name paths for a class constant, with or without an explicit namespace}
public NamePath classConstPath(str cname, str constName, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(cname)>/<cleanString(constName)>|,library) when size(trim(namespace)) == 0;
public NamePath classConstPath(str cname, str constName, str library="", str namespace="") = 
	addLibrary(|php+constant:///<cleanString(namespace)>/<cleanString(cname)>/<cleanString(constName)>|,library) when size(trim(namespace)) > 0;
	
@doc{Create name paths for a script, with or without an explicit namespace}
public NamePath scriptPath(str library="", str namespace="") = 
	addLibrary(|php+script:///|,library) when size(trim(namespace)) == 0;
public NamePath scriptPath(str library="", str namespace="") = 
	addLibrary(|php+script:///|,library) when size(trim(namespace)) > 0;
	