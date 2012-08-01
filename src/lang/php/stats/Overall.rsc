module lang::php::stats::Overall

import Set;
import List;
import String;
import lang::php::util::Utils;
import lang::php::util::Corpus;

public str generateFullCorpusInfoTable() {
	pInfo = loadProductInfoCSV();
	pSorted = sort(toList(pInfo<0>), bool (str a, str b) { return toUpperCase(a) < toUpperCase(b); });
	vInfo = loadVersionsCSV();
	counts = loadCountsCSV();
	
	lv = getLatestVersions();
	ev = ( p : head(vl)[0] | p <- vInfo<0>, vl := sort([ <v,d> | <v,d,pv,_> <- vInfo[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }) );
	
	list[tuple[str p, str pname, str pdesc, int vc, tuple[str v, str rdate, str phpversion] oldest, tuple[str v, str rdate, str phpversion] newest]] tableTuples = 
		[ <p, pname, pdesc, size(vInfo[p]), < replaceLast(v1,"-english",""), prd1, phpv1 >, < replaceLast(v2,"-english",""), prd2, phpv2 > > | p <- pSorted, v1 := ev[p], v2 := lv[p], <p,pname,pdesc> <- pInfo, <p,v1,prd1,phpv1,_> <- vInfo, <p,v2,prd2,phpv2,_> <- vInfo ];

	str headerLine() {
		return "Product & Description & Versions & \\phantom{def} & \\multicolumn{3}{c}{Earliest} & \\phantom{abc} & \\multicolumn{3}{c}{Latest} \\\\
			   ' \\cmidrule{5-7} \\cmidrule{9-11} 
		       '        &             &          & & Version & Release Date & PHP & & Version & Release Date & PHP \\\\ \\midrule";
	}
	
	str productLine(tuple[str p, str pname, str pdesc, int vc, tuple[str v, str rdate, str phpversion] oldest, tuple[str v, str rdate, str phpversion] newest] ci) {
		return "<ci.pname> & <ci.pdesc> & <ci.vc> && <ci.oldest.v> & <ci.oldest.rdate> & <ci.oldest.phpversion> && <ci.newest.v> & <ci.newest.rdate> & <ci.newest.phpversion> \\\\";
	}

	totalSystems = size(vInfo<0,1>);
	totalSLOC = (0 | it + n | <_,_,n,_> <- counts );
	totalFiles = (0 | it + n | <_,_,_,n> <- counts );
	
	res = "\\begin{table*}
		  '\\centering
		  '\\ra{1.2}
		  '\\begin{tabular}{@{}llrclllclll@{}} \\toprule
		  '<headerLine()> <for (tt <- tableTuples) {>
		  '  <productLine(tt)> <}>
		  '\\bottomrule
		  '\\end{tabular} 
		  '\\\\
		  '\\vspace{2ex}
		  '\\footnotesize
		  'The PHP Version listed above is the minimum required version for the system. 
		  'The File Count includes files with either 
		  '\\\\
		  'a .php or an .inc extension, while SLOC includes source lines from these files.
		  'In total, counting the most recent version \\\\ of each system, there are <totalSystems>
		  'systems consisting of <totalFiles> files with <totalSLOC> total lines of source. 
		  '\\normalsize
		  '\\caption{The PHP Corpus: Summary\\label{tbl:php-corpus-summary}}
		  '\\end{table*}
		  '";

	return res;

}

public str generateCorpusInfoTable() {
	lv = getLatestVersions();
	pSorted = sort(toList(lv<0>), bool (str a, str b) { return toUpperCase(a) < toUpperCase(b); });
	pInfo = loadProductInfoCSV();
	vInfo = loadVersionsCSV();
	counts = loadCountsCSV();
	
	list[tuple[str p, str v, str pname, str pdesc, str rdate, str phpversion, int sloc, int fc]] tableTuples = 
		[ <p, v, pname, pdesc, prd, phpv, sloc, fc> | p <- pSorted, v := lv[p], <p,pname,pdesc> <- pInfo, <p,v,prd,phpv,_> <- vInfo, <p,v,sloc,fc> <- counts ];

	str headerLine() {
		return "Product & Version & PHP & Release Date & File Count & SLOC & Description \\\\ \\midrule";
	}
	
	str productLine(tuple[str p, str v, str pname, str pdesc, str rdate, str phpversion, int sloc, int fc] ci) {
		return "<ci.pname> & <replaceLast(ci.v,"-english","")> & <ci.phpversion> & <ci.rdate> & <ci.fc> & <ci.sloc> & <ci.pdesc> \\\\";
	}

	totalSystems = size(lv<0>);
	totalSLOC = (0 | it + n | p <- lv, v := lv[p], <p,v,n,_> <- counts );
	totalFiles = (0 | it + n | p <- lv, v := lv[p], <p,v,_,n> <- counts );
	
	res = "\\begin{table*}
		  '\\centering
		  '\\ra{1.2}
		  '\\begin{tabular}{@{}llllrrl@{}} \\toprule
		  '<headerLine()> <for (tt <- tableTuples) {>
		  '  <productLine(tt)> <}>
		  '\\bottomrule
		  '\\end{tabular} 
		  '\\\\
		  '\\vspace{2ex}
		  '\\footnotesize
		  'The PHP Version listed above is the minimum required version for the system. 
		  'The File Count includes files with either 
		  '\\\\
		  'a .php or an .inc extension, while SLOC includes source lines from these files.
		  'In total, counting the most recent version \\\\ of each system, there are <totalSystems>
		  'systems consisting of <totalFiles> files with <totalSLOC> total lines of source. 
		  '\\normalsize
		  '\\caption{The PHP Corpus: Most Recent Versions\\label{tbl:php-corpus}}
		  '\\end{table*}
		  '";

	return res;

}

