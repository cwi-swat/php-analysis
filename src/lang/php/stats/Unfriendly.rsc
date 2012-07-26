module lang::php::stats::Unfriendly

import lang::php::util::Utils;
import lang::php::stats::Stats;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import List;
import String;
import Set;
import Real;
import IO;
import ValueIO;
import stat::Inference;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::analysis::includes::IncludeCP;

import VVU = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/VarVarUses.csv?funname=varVarUses|;

data QueryResult
	= exprResult(loc l, Expr e)
	;
	
alias QueryResults = list[QueryResult];

public QueryResults getVVUses(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherVarVarUses(ptmap)];
}

public rel[str p, str v, QueryResult qr] getVVUses() {
	lv = getLatestVersions();
	return { < p, lv[p], u > | p <- getProducts(), u <- getVVUses(p,lv[p]) };
}

public list[tuple[str p, str v, QueryResult qr]] getVVUsesAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVUses(p,lv[p]) ];
}

public QueryResults getVVNews(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherVVNews(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVNewsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVNews(p,lv[p]) ];
}

public QueryResults getVVCalls(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherVVCalls(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVCallsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVCalls(p,lv[p]) ];
}

public QueryResults getVVMethodCalls(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherMethodVVCalls(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVMethodCallsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVMethodCalls(p,lv[p]) ];
}

public QueryResults getVVPropertyRefs(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherPropertyFetchesWithVarNames(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVPropertyRefsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVPropertyRefs(p,lv[p]) ];
}

public list[tuple[str p, str path, int line]] showOrderedRel(rel[str p, str v, QueryResult qr] res) =
	[ < i, rst, j.l.begin.line > | i <- sort(toList(res<0>)), j <- sort(toList(res[i]<1>),bool(QueryResult a, QueryResult b) { return (a.l.file < b.l.file) || (a.l.file == b.l.file && a.l.begin.line < b.l.begin.line); }), /<i>\/[^\/]+\/<rst:.+>/ := j.l.path ];
	
public void writeOrderedRel(rel[str p, str v, QueryResult qr] res, loc writeLoc) {
	orel = showOrderedRel(res);
	str toWrite = "Product,Path,Line\n" + intercalate("\n",["<a>,<b>,<c>" | <a,b,c> <- orel]) + "\n";
	writeFile(writeLoc,toWrite);
}

public map[str,tuple[int totalCount, int derivableCount]] varVarUsesInfo() {
	vvu = varVarUses();
	lv = getLatestVersions();
	map[str,int] derivableCount = ( p : 0 | p <- lv<0> );
	map[str,int] totalCount = ( p : 0 | p <- lv<0> );
	for (i <- vvu) {
		if (i.DerivableNames == "Y")
			derivableCount[i.Product] += 1;
		totalCount[i.Product] += 1;
	}
	return ( p : < totalCount[p], derivableCount[p] > | p <- lv<0> );
}

public void showUsageCounts(list[tuple[str p, str v, QueryResult qr]] res) {
	mr = ( p : size([ e | <p,_,e> <- res ]) | p <- getLatestVersions()<0> );
	for (p <- sort([p | str p <- mr<0>])) println("<p>:<mr[p]>");
}

public void showFileInfo(list[tuple[str p, str v, QueryResult qr]] res) {
	lv = getLatestVersions();
	ci = loadCountsCSV();
	pr = { < p, v, qr.l.path > | <p, v, qr > <- res };
	pc = ( p : size([qr|<p,_,qr><-res])  | p <- lv<0> );
	println("product,# of files,# of hits,# of files with hits,% of files with hits,average number per file with hit");
	for (p <- sort(toList(lv<0>))) {
		< lineCount, fileCount > = getOneFrom(ci[p,lv[p]]);
		featureFileCount = size(pr[p,lv[p]]);
		println("<p>: <fileCount>, <pc[p]>, <featureFileCount>, < toInt((featureFileCount*1.0)/fileCount*100000)/1000.0 >, < (featureFileCount == 0) ? 0 : (toInt((pc[p]*1.0)/featureFileCount*1000)/1000.0) >");
	}
}

public str createSubfloat(list[tuple[str p, str v, QueryResult qr]] qrlist, str caption, str label) {
	lv = getLatestVersions();
	ci = loadCountsCSV();
	// relation between products and the files that contain the features of interest
	pr = { < p, qr.l.path > | <p, v, qr > <- qrlist };
	// number of occurrences of the feature in a given product
	pc = ( p : size([qr|<p,_,qr><-qrlist])  | p <- lv<0> );

	gmap = resultsToGini(qrlist);
	
	str productLine(str p) {
		< lineCount, fileCount > = getOneFrom(ci[p,lv[p]]);
		featureFileCount = size(pr[p]);
		return "<p> & <fileCount> & <featureFileCount> & < round((featureFileCount*1.0)/fileCount*10000)/100.0 > & <pc[p]> & < (featureFileCount <= 1) ? "X" : "<round(gmap[p] * 100.0)/100.0>" > \\\\ \\hline";
	}
		
	res = "\\subfloat[<caption>]{
		  '\\begin{tabular}{|l|r|r|r|r|r|} \\hline 
		  'Product & \\multicolumn{3}{|c|}{Files}       & \\multicolumn{2}{|c|}{Features} \\\\
		  '        & Total & Hits & \\% & Total & Gini  \\\\ \\hline \\hline <for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '  <productLine(p)> <}>
		  '\\end{tabular}
		  '\\label{<label>}
		  '}";

	return res;
}

public str showFileInfoAsLatex(list[tuple[str p, str v, QueryResult qr]] vvuses, 
							   list[tuple[str p, str v, QueryResult qr]] vvcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvmcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvnews,
							   list[tuple[str p, str v, QueryResult qr]] vvprops,
							   list[tuple[str p, str v, QueryResult qr]] vvall) {
	res = "\\begin{table*}
		  '  \\centering
		  '  <createSubfloat(vvuses,"Variable Variables","tbl-vvuses")>
		  ' \\qquad
		  '  <createSubfloat(vvcalls,"Variable Calls","tbl-vvcalls")>
		  '
		  '  <createSubfloat(vvmcalls,"Variable Method Calls","tbl-vvmcalls")>
		  ' \\qquad
		  '  <createSubfloat(vvprops,"Variable Properties","tbl-vvprops")>
		  '
		  '  <createSubfloat(vvnews,"Variable Instantiations","tbl-vvnews")>
		  ' \\qquad
		  '  <createSubfloat(vvall,"Combined","tbl-vvcombined")>
		  '  \\caption{PHP Variable Features\\label{table-var}}
		  '\\end{table*}
		  '";
	return res;
}

// TODO: Change this to generate these list...
public void generateTableFiles(list[tuple[str p, str v, QueryResult qr]] vvuses, 
							   list[tuple[str p, str v, QueryResult qr]] vvcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvmcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvnews,
							   list[tuple[str p, str v, QueryResult qr]] vvprops) {
	res = showFileInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvuses + vvcalls + vvmcalls + vvnews + vvprops);
	writeFile(|file:///Users/mhills/Documents/Papers/2012/php-icse12/vvstats.tex|, res);
}

public map[str p, real gc] resultsToGini(list[tuple[str p, str v, QueryResult qr]] res) {
	// Overall, we want to calculate the distribution of number of hits in a file,
	// since we want to know if the number of hits is fairly uniform across the files
	// or is instead heavily weighted to one file. The first step to doing this
	// is to calculate dm, which, for a given product and file, records the number
	// of hits.
	map[tuple[str p, str f] prodfile, int hits] dm = ( );
	for ( < p, _, er > <- res) { 
		if (<p,er.l.path> in dm) 
			dm[<p,er.l.path>] += 1; 
		else 
			dm[<p,er.l.path>] = 1; 
	}
	
	// Now, given the map above, we need to "flip it" around -- we want
	// to record the number of files with a given number of hits, giving
	// us a map from hits -> number of files. This is complicated because
	// this also needs to be calculated on a per-product basis, i.e., we
	// don't want to calculate the distribution over the entire set of
	// results, but individually for MediaWiki, Drupal, etc.
	map[str p, map[int observation, int frequency] fmap] fm = ( );
	for ( <p,f> <- dm ) {
		if (p in fm) {
			if (dm[<p,f>] in fm[p]) {
				fm[p][dm[<p,f>]] += 1;
			} else {
				fm[p][dm[<p,f>]] = 1;
			}
		} else {
			fm[p] = ( dm[<p,f>] : 1 );
		}
	}
	
	// Now, we need to format the data in the format required for the
	// gini calculation, which is as a series of tuples of observation x
	// frequency (e.g., number of hits in a file x number of files with this
	// many hits). For each product, we just need to flatten the map into
	// a list.
	map[str p, real gc] gcmap = ( );
	for ( p <- fm) {
		gctupleList = sort([ < f, fm[p][f] > | f <- fm[p] ], bool(tuple[int l, int r] t1, tuple[int l, int r] t2) { return t1.l < t2.l; });
		if (size(gctupleList) <= 1)
			gcmap[p] = 0.0;
		else	
			gcmap[p] = gini(gctupleList);
	}
	
	return gcmap;
}

public map[tuple[str p, str v] pv, tuple[list[tuple[loc fileloc, Expr call]] unresolved, list[tuple[loc fileloc, Expr call]] afterEval, list[tuple[loc fileloc, Expr call]]afterMatch, list[tuple[loc fileloc, Expr call]] afterBoth] hits] includesAnalysis() {
	lv = getLatestVersions();
	res = ( );
	for (p <- lv) {
		scripts = loadBinary(p,lv[p]);
		unresolved = gatherIncludesWithVarPaths(scripts);
		scripts2 = evalAllScalars(scripts);
		afterEval = gatherIncludesWithVarPaths(scripts2);
		scripts3 = matchIncludes(scripts);
		afterMatch = gatherIncludesWithVarPaths(scripts3);
		scripts4 = matchIncludes(scripts2);
		afterBoth = gatherIncludesWithVarPaths(scripts4);
		res[<p,lv[p]>] = < unresolved, afterEval, afterMatch, afterBoth >;		
	}
	return res;
}

public void saveForLater(map[tuple[str p, str v] pv, tuple[list[tuple[loc fileloc, Expr call]] unresolved, list[tuple[loc fileloc, Expr call]] afterEval, list[tuple[loc fileloc, Expr call]]afterMatch, list[tuple[loc fileloc, Expr call]] afterBoth] hits] res) {
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/includes.bin|, res);
}

public map[tuple[str p, str v] pv, tuple[list[tuple[loc fileloc, Expr call]] unresolved, list[tuple[loc fileloc, Expr call]] afterEval, list[tuple[loc fileloc, Expr call]]afterMatch, list[tuple[loc fileloc, Expr call]] afterBoth] hits] reload() {
	return readBinaryValueFile(#map[tuple[str p, str v] pv, tuple[list[tuple[loc fileloc, Expr call]] unresolved, list[tuple[loc fileloc, Expr call]] afterEval, list[tuple[loc fileloc, Expr call]]afterMatch, list[tuple[loc fileloc, Expr call]] afterBoth] hits], |file:///export/scratch1/hills/temp/includes.bin|); 
}