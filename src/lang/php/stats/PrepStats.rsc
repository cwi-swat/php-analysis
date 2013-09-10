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

public void prepareStats(list[tuple[str p, str v, map[str,int] fc, map[str,int] sc, map[str,int] ec]] stats, bool appendToFiles) {
	oftr = featureOrder();
	oexp = exprKeyOrder();
	ostmt = stmtKeyOrder();

	list[str] fFile = ["product,version,<intercalate(",",oftr)>"];
	list[str] exprFile = ["product,version,<intercalate(",",oexp)>"];
	list[str] stmtFile = ["product,version,<intercalate(",",ostmt)>"];
	
	for (i <- stats) {
		list[int] fCounts = [ i.fc[f] | f <- oftr ];
		list[int] einfoCounts = [ (e in i.ec) ? i.ec[e] : 0 | e <- oexp ];
		list[int] sinfoCounts = [ (s in i.sc) ? i.sc[s] : 0 | s <- ostmt ];
		fFile += "<i.p>,<i.v>,<intercalate(",",fCounts)>";
		exprFile += "<i.p>,<i.v>,<intercalate(",",einfoCounts)>";
		stmtFile += "<i.p>,<i.v>,<intercalate(",",sinfoCounts)>";
	}
	
	if (appendToFiles) {
		appendToFile(|project://PHPAnalysis/src/lang/php/extract/csvs/features.csv|, intercalate("\n",fFile));
		appendToFile(|project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv|, intercalate("\n",exprFile));
		appendToFile(|project://PHPAnalysis/src/lang/php/extract/csvs/stmts.csv|, intercalate("\n",stmtFile));
	} else {
		writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/features.csv|, intercalate("\n",fFile));
		writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv|, intercalate("\n",exprFile));
		writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/stmts.csv|, intercalate("\n",stmtFile));	
	}
}

