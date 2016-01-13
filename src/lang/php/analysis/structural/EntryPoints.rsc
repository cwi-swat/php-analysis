module lang::php::analysis::structural::EntryPoints

import lang::php::ast::AbstractSyntax;

@doc{Find all possible entry points, assuming we have an initial set of entries, like the index.php page that visitors would first access.}
public set[loc] identifyEntryPoints(System sys, set[loc] initialEntries) {
	set[loc] res = { };
	for (ie <- initialEntries) {
		ieScript = sys.files[ie];
		// Identify all the <a> tags to find the links
		
		;	
	}
} 