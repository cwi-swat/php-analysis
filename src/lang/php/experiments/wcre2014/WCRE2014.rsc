module lang::php::experiments::wcre2014::WCRE2014

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::util::Corpus;
import lang::php::util::Utils;

import List;
import IO;

alias TaggedExprs = rel[str product, str version, loc at, Expr expr];

public TaggedExprs getEvalLike(str product, str version) {
	t = loadBinary(product, version);
	evalLike = { < e@at, e > | /e:eval(_) := t } +  
			   { < e@at, e > | /e:call(name(name("create_function")),_) := t };
	return { < product, version > } join evalLike; 
}

public TaggedExprs getEvalLike(str product) {
	return { *getEvalLike(product,version) | version <- getVersions(product) };
}

public map[str,int] evalCounts(str product, TaggedExprs te) {
	return ( v : size([l | <l,eval(_) > <- te[_,v]]) | v <- getVersions(product) );
}

public map[str,int] createFunctionCounts(str product, TaggedExprs te) {
	return ( v : size([l | <l,call(name(name("create_function")),_) > <- te[_,v]]) | v <- getVersions(product) );
}

public void printEvalLike(str product, TaggedExprs te) {
	ec = evalCounts(product, te);
	fc = createFunctionCounts(product, te);
	println("Version\t\tEvals\t\tcreate_function calls");
	for (v <- getSortedVersions(product)) println("<v>\t\t<ec[v]>\t\t<fc[v]>");
}

public void printEvalLike(str product) {
	printEvalLike(product, getEvalLike(product));
}