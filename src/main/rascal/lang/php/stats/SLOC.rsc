@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::stats::SLOC

import lang::php::config::Config;
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
