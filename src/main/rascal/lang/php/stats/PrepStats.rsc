@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::stats::PrepStats

import lang::php::stats::Stats;
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
		appendToFile(|rascal://src/lang/php/extract/csvs/features.csv|, intercalate("\n",fFile));
		appendToFile(|rascal://src/lang/php/extract/csvs/exprs.csv|, intercalate("\n",exprFile));
		appendToFile(|rascal://src/lang/php/extract/csvs/stmts.csv|, intercalate("\n",stmtFile));
	} else {
		writeFile(|rascal://src/lang/php/extract/csvs/features.csv|, intercalate("\n",fFile));
		writeFile(|rascal://src/lang/php/extract/csvs/exprs.csv|, intercalate("\n",exprFile));
		writeFile(|rascal://src/lang/php/extract/csvs/stmts.csv|, intercalate("\n",stmtFile));	
	}
}

