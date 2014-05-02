module lang::php::ast::System

import lang::php::ast::AbstractSyntax;
import lang::php::ast::NormalizeAST;

alias System = map[loc fileloc, Script scr];


public System normalizeSystem(System s) {
	s = discardErrorScripts(s);
	
	for (l <- s) {
		s[l] = oldNamespaces(s[l]);
		s[l] = normalizeIf(s[l]);
		s[l] = flattenBlocks(s[l]);
		s[l] = discardEmpties(s[l]);
		s[l] = useBuiltins(s[l]);
		s[l] = discardHTML(s[l]);
	}
	
	return s;
}


@doc { filter a system to only contain script(_), and therefore discard errscript }
public System discardErrorScripts(System s) {
	return (l : s[l] | l <- s, script(_) := s[l]);
}
