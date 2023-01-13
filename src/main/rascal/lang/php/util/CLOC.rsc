module lang::php::util::CLOC

import util::ShellExec;
import IO;
import String;
import List;

import lang::php::ast::System;
import lang::php::util::Corpus;
import lang::php::util::Utils;

public int phpLinesOfCode(loc l) {
	pid = createProcess("/cwi/bin/perl", args = ["/ufs/hills/project/cloc/cloc-1.53.pl", "--read-lang-def=/ufs/hills/project/cloc/ld.txt", "<l.path>"]);
	res = readEntireStream(pid);
	killProcess(pid);
	if(/PHP\s+<n1:\d+>\s+<n2:\d+>\s+<n3:\d+>\s+<n4:\d+>/ := res) {
		return toInt(n4);
	} else {
		println("Odd, no PHP code found in file <l.path>");
		return 0;
	}
}

public map[loc,int] locsForProduct(str p, str v) {
	System s = loadBinary(p,v);
	return ( l : phpLinesOfCode(l) | l <- s.files ); 
}

public void locsForProducts() {
	lv = getLatestVersions();
	map[loc,int] res = ( );
	
	str header = "product, version, file, phplines\n";
	writeFile(|rascal://src/lang/php/extract/csvs/linesPerFile.csv|, header);
	
	for (p <- lv) {
		res = locsForProduct(p,lv[p]);
		appendToFile(|rascal://src/lang/php/extract/csvs/linesPerFile.csv|, intercalate("\n",["<p>,<lv[p]>,<l.path>,<res[l]>" | l <- res]) + "\n");
	}
	
}