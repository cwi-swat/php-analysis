module lang::php::stats::Latex

import lang::php::stats::Unfriendly;
import lang::php::stats::Overall;

public void writeTableFiles(list[tuple[str p, str v, QueryResult qr]] vvuses, 
							   list[tuple[str p, str v, QueryResult qr]] vvcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvmcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvnews,
							   list[tuple[str p, str v, QueryResult qr]] vvprops) {
	res = showFileInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvuses + vvcalls + vvmcalls + vvnews + vvprops);
	writeFile(|file:///Users/mhills/Documents/Papers/2012/php-icse12/vvstats.tex|, res);
	
	res = generateCorpusInfoTable("The PHP Corpus", "tbl:php-corpus");
	writeFile(|file:///Users/mhills/Documents/Papers/2012/php-icse12/corpustbl.tex|, res);
}