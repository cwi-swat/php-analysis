module lang::php::analysis::string::StringAnalysis

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::BuildCFG;
import lang::php::analysis::AnalysisFact;

data StrExp
	= stringLiteral(str s)
	| concatenated(StrExp l, StrExp r)
	| option(StrExp l, StrExp r)
	| input(str inVar)
	;

anno FactBase CFGNode@fb;

alias StrMap = map[str,StrExp];

data AnalysisFact = strResult(StrExp sres);

data AnalysisFact = strEnv(StrMap smap);

public CFG transfer(CFG inputCFG) {
	// TODO: It would be better to pick an optimal node ordering
	// here to start, look at the literature to get this. For now,
	// just use whatever order we get back, but this could then take
	// longer to stabilize.
	list[CFGNode] workingList = toList(inputCFG.nodes);
	
	// Initialize the string facts on all the nodes, we assume
	// everything starts "empty" and then work our way up to more
	// complex string contents
}

