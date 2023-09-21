@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::ast::System

import lang::php::ast::AbstractSyntax;
import lang::php::ast::NormalizeAST;

data System 
	= system(map[loc fileloc, Script scr] files)
	| namedVersionedSystem(str name, str version, loc baseLoc, map[loc fileloc, Script scr] files)
	| namedSystem(str name, loc baseLoc, map[loc fileloc, Script scr] files)
	| locatedSystem(loc baseLoc, map[loc fileloc, Script scr] files)
	;

public System normalizeSystem(System s) {
	s = discardErrorScripts(s);
	
	for (l <- s.files) {
		s.files[l] = oldNamespaces(s.files[l]);
		s.files[l] = normalizeIf(s.files[l]);
		s.files[l] = flattenBlocks(s.files[l]);
		s.files[l] = discardEmpties(s.files[l]);
		s.files[l] = useBuiltins(s.files[l]);
		s.files[l] = discardHTML(s.files[l]);
	}
	
	return s;
}


@doc { filter a system to only contain script(_), and therefore discard errscript }
public System discardErrorScripts(System s) {
	s.files = (l : s.files[l] | l <- s.files, script(_) := s.files[l]);
	return s;
}

public System createEmptySystem() = system( () );
public System createEmptySystem(loc l) = locatedSystem(l, ( ) );

public System convertSystem(value v) {
	if (map[loc fileloc, Script scr] files := v) {
		return system(files);
	} else if (System s := v) {
		return s;
	} else {
		throw "Unexpected input";
	}
}

public System convertSystem(value v, loc l) {
	if (map[loc fileloc, Script scr] files := v) {
		return locatedSystem(l, files);
	} else if (System s := v) {
		return s;
	} else {
		throw "Unexpected input";
	}
}

public set[loc] errorScripts(System s) = { l | l <- s.files, s.files[l] is errscript };

//public System addFile(System sys, loc l, Script s) {
//	sys.files[l] = s;
//	return sys;
//}