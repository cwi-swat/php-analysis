@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::stats::PrepStats

import lang::php::stats::Stats;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import List;
import Set;
import String;
import IO;

public void prepareStats(map[tuple[str product, str version], tuple[map[str,int] featureCounts, map[str,int] exprCounts, map[str,int] stmtCounts]] infoMap) {
	oftr = featureOrder();
	oexp = exprKeyOrder();
	ostmt = stmtKeyOrder();

	list[str] fFile = ["product,version,<intercalate(",",oftr)>"];
	list[str] exprFile = ["product,version,<intercalate(",",oexp)>"];
	list[str] stmtFile = ["product,version,<intercalate(",",ostmt)>"];
	
	lookupPairs = [ < p,v > | p <- getProducts(), v <- getVersions(p) ] +
	              [ < p,v > | p <- getPlugins(), v <- getPluginVersions(p) ];
	              
	for (< p, v > <- lookupPairs) {
		info = infoMap[<p,v>];
		finfo = info.featureCounts;
		einfo = info.exprCounts;
		sinfo = info.stmtCounts;
		list[int] fCounts = [ finfo[f] | f <- oftr ];
		list[int] einfoCounts = [ (e in einfo) ? einfo[e] : 0 | e <- oexp ];
		list[int] sinfoCounts = [ (s in sinfo) ? sinfo[s] : 0 | s <- ostmt ];
		fFile += "<p>,<v>,<intercalate(",",fCounts)>";
		exprFile += "<p>,<v>,<intercalate(",",einfoCounts)>";
		stmtFile += "<p>,<v>,<intercalate(",",sinfoCounts)>";
	}
	
	writeFile(|file:///tmp/features.csv|, intercalate("\n",fFile));
	writeFile(|file:///tmp/exprs.csv|, intercalate("\n",exprFile));
	writeFile(|file:///tmp/stmts.csv|, intercalate("\n",stmtFile));
}

public void prepareStatsMW(map[tuple[str product, str version], tuple[map[str,int] featureCounts, map[str,int] exprCounts, map[str,int] stmtCounts]] mwinfo) {
	sortedMWVersions = List::sort(toList(getMWVersions()),compareMWVersion);

	oftr = featureOrder();
	oexp = exprKeyOrder();
	ostmt = stmtKeyOrder();

	list[str] fFile = ["version,<intercalate(",",oftr)>"];
	list[str] exprFile = ["version,<intercalate(",",oexp)>"];
	list[str] stmtFile = ["version,<intercalate(",",ostmt)>"];
	
	for (v <- sortedMWVersions) {
		info = mwinfo[<"MediaWiki",v>];
		finfo = info.featureCounts;
		einfo = info.exprCounts;
		sinfo = info.stmtCounts;
		list[int] fCounts = [ finfo[f] | f <- oftr ];
		list[int] einfoCounts = [ (e in einfo) ? einfo[e] : 0 | e <- oexp ];
		list[int] sinfoCounts = [ (s in sinfo) ? sinfo[s] : 0 | s <- ostmt ];
		fFile += "<v>,<intercalate(",",fCounts)>";
		exprFile += "<v>,<intercalate(",",einfoCounts)>";
		stmtFile += "<v>,<intercalate(",",sinfoCounts)>";
	}
	
	writeFile(|file:///tmp/mwfeatures.csv|, intercalate("\n",fFile));
	writeFile(|file:///tmp/mwexprs.csv|, intercalate("\n",exprFile));
	writeFile(|file:///tmp/mwstmts.csv|, intercalate("\n",stmtFile));
}