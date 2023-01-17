module lang::php::stats::SLOC

import lang::php::util::Config;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;

import IO;
import String;
import List;
import Set;

public map[str lang, tuple[int lineCount, int fileCount] counts] loadCounts(str product, str version) {
	map[str lang, tuple[int lineCount, int fileCount] counts] res = ( );
	
	countItem = countsDir + "<toLowerCase(product)>-<version>";
	
	if (!exists(countItem))
		countItem = countsDir + "<toLowerCase(product)>_<version>";
	
	if (!exists(countItem))
		throw "Could not find counts file for <toLowerCase(product)>-<version>";
	
	lines = readFileLines(countItem);
	
	for (l <- lines, /<lang:\S+>\s+<langfiles:\d+>\s+\d+\s+\d+\s+<langloc:\d+>/ := l) {
		 res[lang] = < toInt(langloc), toInt(langfiles) >;
	}
	
	if ("PHP" notin res) {
		println("WARNING: Could not find PHP LOC counts for <product>-<version>");
		res["PHP"] = < 0, 0 >;
	}
	
	return res;
}

public list[tuple[str p, str v, int count, int fileCount]] getSortedCounts(str lang="PHP") {
	return [ <p,v,lc,fc> | p <- sort(toList(getProducts())), v <- sort(toList(getVersions(p)),compareVersion), <lc,fc> := (loadCounts(p,v))[lang] ];	
}

public list[tuple[str p, str v, int count, int fileCount]] getSortedCountsCaseInsensitive(str _) {
	pForSort = [ < toUpperCase(p), p > | p <- getProducts() ];
	pForSort = sort(pForSort, bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[0] < t2[0]; });
	return [ <p,v,lc,fc> | <_,p> <- pForSort, v <- sort(toList(getVersions(p)),compareVersion), <lc,fc> := (loadCounts(p,v))["PHP"] ];	
}
