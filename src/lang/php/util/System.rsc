module lang::php::util::System

import lang::php::ast::AbstractSyntax;

alias System = map[loc fileloc, Script scr];

//data System = system(map[loc fileloc, Script scr] files);

//public System emptySystem() = system( () );
//
//public System addFile(System sys, loc l, Script s) {
//	sys.files[l] = s;
//	return sys;
//}
