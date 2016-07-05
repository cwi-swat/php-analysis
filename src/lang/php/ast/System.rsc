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