module lang::php::stats::Overall

import Set;
import List;
import String;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::stats::Stats;

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
		return "System & Description & Versions & \\phantom{def} & \\multicolumn{3}{c}{Earliest} & \\phantom{abc} & \\multicolumn{3}{c}{Latest} \\\\
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

public str generateCorpusInfoTable(Corpus corpus) {
	pSorted = sort(toList(corpus<0>), bool (str a, str b) { return toUpperCase(a) < toUpperCase(b); });
	pInfo = loadProductInfoCSV();
	vInfo = loadVersionsCSV();
	counts = loadCountsCSV();
	
	list[tuple[str p, str v, str pname, str pdesc, str rdate, str phpversion, int sloc, int fc]] tableTuples = 
		[ <p, v, pname, pdesc, prd, phpv, sloc, fc> | p <- pSorted, v := corpus[p], <p,pname,pdesc> <- pInfo, <p,v,prd,phpv,_> <- vInfo, <p,v,sloc,fc> <- counts ];

	str headerLine() {
		return "System & Version & PHP & Release Date & File Count & SLOC & Description \\\\ \\midrule";
	}
	
	str productLine(tuple[str p, str v, str pname, str pdesc, str rdate, str phpversion, int sloc, int fc] ci) {
		return "<ci.pname> & <replaceLast(ci.v,"-english","")> & <ci.phpversion> & <ci.rdate> & \\numprint{<ci.fc>} & \\numprint{<ci.sloc>} & <ci.pdesc> \\\\";
	}

	totalSystems = size(corpus<0>);
	totalSLOC = (0 | it + n | p <- corpus, v := corpus[p], <p,v,n,_> <- counts );
	totalFiles = (0 | it + n | p <- corpus, v := corpus[p], <p,v,_,n> <- counts );
	
	res = "\\npaddmissingzero
	      '\\npfourdigitsep
		  '\\begin{table*}
		  '\\centering
		  '\\ra{1.2}
		  '\\begin{tabularx}{\\textwidth}{XlllrrX} \\toprule
		  '<headerLine()> <for (tt <- tableTuples) {>
		  '  <productLine(tt)> <}>
		  '\\bottomrule
		  '\\end{tabularx}
		  '\\parbox{\\textwidth}{\\mbox{} \\\\ The PHP versions listed above in column PHP are the minimum required versions. 
          'The File Count includes files with a .php or an .inc extension. In total there are \\numprint{<totalSystems>}
		  'systems consisting of \\numprint{<totalFiles>} files with \\numprint{<totalSLOC>} total lines of source.} 
		  '\\caption{The PHP Corpus.\\label{tbl:php-corpus}}
		  '\\end{table*}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";

	return res;

}

public str generateESECIncludesInfoTable(Corpus corpus) {
	pSorted = sort(toList(corpus<0>), bool (str a, str b) { return toUpperCase(a) < toUpperCase(b); });
	counts = loadCountsCSV();
	
	list[tuple[str p, str v, int sloc, int fc]] tableTuples = 
		[ <p, v, sloc, fc> | p <- pSorted, v := corpus[p], <p,v,sloc,fc> <- counts ];

	str headerLine() {
		return "Product & File Count & SLOC  \\\\ \\midrule";
	}
	
	str productLine(tuple[str p, str v, int sloc, int fc] ci) {
		return "<ci.p> & \\numprint{<ci.fc>} & \\numprint{<ci.sloc>} \\\\";
	}

	totalSystems = size(corpus<0>);
	totalSLOC = (0 | it + n | p <- corpus, v := corpus[p], <p,v,n,_> <- counts );
	totalFiles = (0 | it + n | p <- corpus, v := corpus[p], <p,v,_,n> <- counts );
	
	res = "\\npaddmissingzero
	      '\\npfourdigitsep
		  '\\begin{table*}
		  '\\centering
		  '\\ra{1.2}
		  '\\begin{tabular}{@{}lrr@{}} \\toprule
		  '<headerLine()> <for (tt <- tableTuples) {>
		  '  <productLine(tt)> <}>
		  '\\bottomrule
		  '\\end{tabular}
		  '\\parbox{.75\\textwidth}{The File Count includes files with either a .php or an .inc extension, while SLOC includes source lines
		  'from these files. In total, there are \\numprint{<totalSystems>}
		  'systems consisting of \\numprint{<totalFiles>} files with \\numprint{<totalSLOC>} total lines of source.} 
		  '\\caption{Github Systems in Extension.\\label{tbl:php-extension}}
		  '\\end{table*}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";

	return res;

}
