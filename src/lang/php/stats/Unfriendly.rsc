module lang::php::stats::Unfriendly

import lang::php::util::Utils;
import lang::php::stats::Stats;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import List;
import String;
import Set;
import Real;
import Relation;
import IO;
import ValueIO;
import Map;
import stat::Inference;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::analysis::includes::IncludeCP;
import lang::rascal::types::AbstractType;
import util::Math;

import lang::csv::IO;
import VVU = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/VarVarUses.csv?funname=varVarUses|;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=expressionCounts|;
import Feats = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/FeaturesByFile.csv?funname=getFeats|;
import Sizes = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|;

data QueryResult
	= exprResult(loc l, Expr e)
	;
	
alias QueryResults = list[QueryResult];

public real mygini(list[tuple[num observation,int frequency]] values) {
	list[num] dup(num item, int frequency) {
		if (frequency <= 0) return [ ];
		return dup(item,frequency-1) + item;
	}
	
	return mygini([ *dup(o,f) | <o,f> <- values ]);
}

public real mygini(list[int] dist) {
	dist = sort(dist);
	n = size(dist);
	sum1 = ( 0.0 | it + (n + 1 - (idx+1)) * dist[idx] | idx <- index(dist) );
	sum2 = ( 0.0 | it + r | r <- dist );
	sum3 = n + 1 - (2 * sum1 / sum2 );
	total = sum3 / n;
	return total;
}

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

public QueryResults getVVClassConsts(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherVVClassConsts(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVClassConstsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVClassConsts(p,lv[p]) ];
}

public QueryResults getVVStaticCalls(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherStaticVVCalls(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVStaticCallsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVStaticCalls(p,lv[p]) ];
}

public QueryResults getVVStaticCallTargets(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherStaticVVTargets(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVStaticCallTargetsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVStaticCallTargets(p,lv[p]) ];
}

public QueryResults getVVStaticPropNames(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherStaticPropertyVVNames(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVStaticPropNamesAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVStaticPropNames(p,lv[p]) ];
}

public QueryResults getVVStaticPropTargets(str product, str version) {
	ptmap = loadBinary(product, version);
	return [exprResult(e@at,e) | <_,e> <-  gatherStaticPropertyVVTargets(ptmap)];
}

public list[tuple[str p, str v, QueryResult qr]] getVVStaticPropTargetsAsList() {
	lv = getLatestVersions();
	return [ < p, lv[p], u > | p <- getProducts(), u <- getVVStaticPropTargets(p,lv[p]) ];
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
		return "<p> & <fileCount> & <featureFileCount> & < round((featureFileCount*1.0)/fileCount*10000)/100.0 > & & <pc[p]> & < (featureFileCount <= 1) ? "X" : "<round(gmap[p] * 100.0)/100.0>" > \\\\";
	}
		
	res = "\\subfloat[<caption>]{
		  '\\centering
		  '\\ra{1.0}
		  '\\begin{tabular}{@{}lrrrcrr@{}} \\toprule 
		  'Product & \\multicolumn{3}{c}{Files} & \\phantom{abc}  & \\multicolumn{2}{c}{Features} \\\\
		  '        \\cmidrule{2-4} \\cmidrule{6-7}
		  '        & Total & Hits & \\% & & Total & Gini  \\\\ \\midrule <for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '  <productLine(p)> <}>
		  '\\bottomrule
		  '\\end{tabular}
		  '\\label{<label>}
		  '}";

	return res;
}

public str showVVInfoAsLatex(list[tuple[str p, str v, QueryResult qr]] vvuses, 
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

public void saveVVFiles(list[tuple[str p, str v, QueryResult qr]] vvuses, 
					    list[tuple[str p, str v, QueryResult qr]] vvcalls,
					    list[tuple[str p, str v, QueryResult qr]] vvmcalls,
					    list[tuple[str p, str v, QueryResult qr]] vvnews,
					    list[tuple[str p, str v, QueryResult qr]] vvprops,
					    list[tuple[str p, str v, QueryResult qr]] vvcconsts,
					    list[tuple[str p, str v, QueryResult qr]] vvscalls,
					    list[tuple[str p, str v, QueryResult qr]] vvstargets,
					    list[tuple[str p, str v, QueryResult qr]] vvsprops,
					    list[tuple[str p, str v, QueryResult qr]] vvsptargets
					   ) {
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvuses.bin|, vvuses);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvcalls.bin|, vvcalls);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvmcalls.bin|, vvmcalls);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvnews.bin|, vvnews);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvprops.bin|, vvprops);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvcconsts.bin|, vvcconsts);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvscalls.bin|, vvscalls);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvstargets.bin|, vvstargets);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvsprops.bin|, vvsprops);
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/vvsptargets.bin|, vvsptargets);
}					   

public tuple[list[tuple[str p, str v, QueryResult qr]] vvuses, 
			 list[tuple[str p, str v, QueryResult qr]] vvcalls,
			 list[tuple[str p, str v, QueryResult qr]] vvmcalls,
			 list[tuple[str p, str v, QueryResult qr]] vvnews,
			 list[tuple[str p, str v, QueryResult qr]] vvprops,
			 list[tuple[str p, str v, QueryResult qr]] vvcconsts,
			 list[tuple[str p, str v, QueryResult qr]] vvscalls,
			 list[tuple[str p, str v, QueryResult qr]] vvstargets,
			 list[tuple[str p, str v, QueryResult qr]] vvsprops,
			 list[tuple[str p, str v, QueryResult qr]] vvsptargets] loadVVFiles() {
	return <
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvuses.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvcalls.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvmcalls.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvnews.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvprops.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvcconsts.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvscalls.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvstargets.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvsprops.bin|),
	readBinaryValueFile(#list[tuple[str p, str v, QueryResult qr]],|file:///export/scratch1/hills/temp/vvsptargets.bin|) >;
}

// TODO: Change this to generate these list...
public void generateTableFiles(list[tuple[str p, str v, QueryResult qr]] vvuses, 
							   list[tuple[str p, str v, QueryResult qr]] vvcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvmcalls,
							   list[tuple[str p, str v, QueryResult qr]] vvnews,
							   list[tuple[str p, str v, QueryResult qr]] vvprops,
							   list[tuple[str p, str v, QueryResult qr]] vvcconsts,
							   list[tuple[str p, str v, QueryResult qr]] vvscalls,
							   list[tuple[str p, str v, QueryResult qr]] vvstargets,
							   list[tuple[str p, str v, QueryResult qr]] vvsprops,
							   list[tuple[str p, str v, QueryResult qr]] vvsptargets
							   ) {
	res = showVVInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls + vvstargets + vvsprops + vvsptargets);
	writeFile(|file:///ufs/hills/Documents/Papers/2012/php-icse12/vvstats.tex|, res);
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
			gcmap[p] = mygini(gctupleList);
	}
	
	return gcmap;
}

alias ICLists = map[tuple[str p, str v] pv, tuple[list[tuple[loc fileloc, Expr call]] unresolved, list[tuple[loc fileloc, Expr call]] afterEval, list[tuple[loc fileloc, Expr call]]afterMatch, list[tuple[loc fileloc, Expr call]] afterBoth] hits];

public ICLists includesAnalysis() {
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

public void saveForLater(ICLists res) {
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/includes.bin|, res);
}

public ICLists reload() {
	return readBinaryValueFile(#ICLists, |file:///export/scratch1/hills/temp/includes.bin|); 
}

alias ICResult = map[tuple[str p, str v] pv, tuple[tuple[int hc,int fc,real gc] unresolved, tuple[int hc,int fc,real gc] afterEval, tuple[int hc, int fc,real gc] afterMatch, tuple[int hc,int fc,real gc] afterBoth] counts];

public ICResult calculateIncludeCounts(ICLists res) {
	counts = ( );
	
	tuple[int hc, int fc, real gc] calc(list[tuple[loc fileloc, Expr call]] hits) {
		hc = size(hits);
		fc = size({ l.path | <l,_> <- hits });
		hitmap = ( l.path : size([i|i:<l,_> <- hits]) | l <- {l | <l,_> <- hits} );
		//distmap = ( );
		//for (l <- hitmap) if (hitmap[l] in distmap) distmap[hitmap[l]] += 1; else distmap[hitmap[l]] = 1;
		distlist = [ hitmap[l] | l <- hitmap ];
		gc = round(mygini(distlist)*10000.0)/10000.0;
		return < hc, fc, gc >;
	}
	
	for (<p,v> <- res) {
		l1 = res[<p,v>].unresolved;
		l2 = res[<p,v>].afterEval;
		l3 = res[<p,v>].afterMatch;
		l4 = res[<p,v>].afterBoth;
		counts[<p,v>] = < calc(l1), calc(l2), calc(l3), calc(l4) >;
	}
	
	return counts;
}

public void saveIncludeCountsForLater(ICResult res) {
	writeBinaryValueFile(|file:///export/scratch1/hills/temp/includeCounts.bin|, res);
}

public ICResult reloadIncludeCounts() {
	return readBinaryValueFile(#ICResult, |file:///export/scratch1/hills/temp/includeCounts.bin|); 
}

public str generateIncludeCountsTable(ICResult counts) {
	lv = getLatestVersions();
	ci = loadCountsCSV();
	ec = expressionCounts();
	includesPerProduct = ( <p,lv[p]> : getOneFrom((ec<product,version,include>)[p,lv[p]]) | p <- lv );
		
	str productLine(str p) {
		v = lv[p];
		< lineCount, fileCount > = getOneFrom(ci[p,v]);
		return "<p> & <fileCount> & <includesPerProduct[<p,v>]> & <counts[<p,v>].unresolved.hc> & <counts[<p,v>].afterEval.hc> & <counts[<p,v>].afterMatch.hc> & <counts[<p,v>].afterBoth.hc> & <round((1.0 * counts[<p,v>].unresolved.hc - counts[<p,v>].afterBoth.hc) / counts[<p,v>].unresolved.hc * 10000.0) / 100.0> &  <counts[<p,v>].afterBoth.fc> & <counts[<p,v>].afterBoth.gc> \\\\";
	}
		
	res = "\\begin{table*}
		  '  \\centering
		  '  \\ra{1.2}
		  '  \\begin{tabular}{@{}lrrrrrrrrr@{}} \\toprule
		  '  Product & Files & Includes & NL & AS & AM & AB & Resolved\\% & AB Files & Gini \\\\ \\midrule<for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '  \\caption{PHP Non-Literal Includes\\label{table-includes}}
		  '\\end{table*}
		  '";
	return res;	
}

alias MMResult = map[tuple[str p, str v], tuple[list[ClassItem] sets, list[ClassItem] gets, list[ClassItem] isSets, list[ClassItem] unsets, list[ClassItem] calls, list[ClassItem] staticCalls]];

public MMResult magicMethodUses() {
	lv = getLatestVersions();
	res = ( );
	for (p <- lv) {
		pt = loadBinary(p,lv[p]);
		sets = fetchOverloadedSet(pt);
		gets = fetchOverloadedGet(pt);
		isSets = fetchOverloadedIsSet(pt);
		unsets = fetchOverloadedUnset(pt);
		calls = fetchOverloadedCall(pt);
		staticCalls = fetchOverloadedCallStatic(pt);
		res[<p,lv[p]>] = < sets, gets, isSets, unsets, calls, staticCalls >;
	}
	return res;
}

public str magicMethodCounts(MMResult res) {
	lv = getLatestVersions();
	ci = loadCountsCSV();
	
	str productLine(str p) {
		v = lv[p];
		< lineCount, fileCount > = getOneFrom(ci[p,v]);

		setsSize = size(res[<p,lv[p]>].sets);
		getsSize = size(res[<p,lv[p]>].gets);
		isSetsSize = size(res[<p,lv[p]>].isSets);
		unsetsSize = size(res[<p,lv[p]>].unsets);
		callsSize = size(res[<p,lv[p]>].calls);
		staticCallsSize = size(res[<p,lv[p]>].staticCalls);
		allMM = res[<p,lv[p]>].sets + res[<p,lv[p]>].gets + res[<p,lv[p]>].isSets + res[<p,lv[p]>].unsets + res[<p,lv[p]>].calls + res[<p,lv[p]>].staticCalls;
		hits = ( );
		for (citem <- allMM) {
			hitloc = citem@at.path;
			if (hitloc in hits)
				hits[hitloc] += 1;
			else
				hits[hitloc] = 1;
		}
		giniC = (size(hits) > 1) ? mygini([ hits[hl] | hl <- hits ]) : 0;

		return "<p> & <fileCount> & <size(hits<0>)> && <setsSize> & <getsSize> & <isSetsSize> & <unsetsSize> & <callsSize> & <staticCallsSize> & <(size(hits) > 1) ? round(giniC*1000.0)/1000.0 : "X"> \\\\";
	}
		
	tbl = "\\begin{table*}
		  '  \\centering
		  '  \\ra{1.2}
		  '  \\begin{tabular}{@{}lrrcrrrrrrr@{}} \\toprule
		  '  Product & \\multicolumn{2}{c}{Files} & \\phantom{abc} & \\multicolumn{6}{c}{Overloading Feature} & Gini \\\\
		  '  \\cmidrule{2-3} \\cmidrule{5-10}
		  '          & Total & w/Overload && Set & Get & Is Set & Unset & Call & Static Call &  \\\\ \\midrule<for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '  \\caption{PHP Overloading (Magic Methods)\\label{table-magic}}
		  '\\end{table*}
		  '";
	return tbl;	
	
}

alias HistInfo = rel[str p, str file, int variableVariables, int variableCalls, int variableMethodCalls, int variableNews, 
                     int variableProperties, int variableClassConsts, int variableStaticCalls, int variableStaticTargets,
                     int variableStaticProperties, int variableStaticPropertyTargets];
                     
public HistInfo calculateHistData(list[tuple[str p, str v, QueryResult qr]] vvuses, 
								  list[tuple[str p, str v, QueryResult qr]] vvcalls,
								  list[tuple[str p, str v, QueryResult qr]] vvmcalls,
								  list[tuple[str p, str v, QueryResult qr]] vvnews,
								  list[tuple[str p, str v, QueryResult qr]] vvprops,
								  list[tuple[str p, str v, QueryResult qr]] vvcconsts,
								  list[tuple[str p, str v, QueryResult qr]] vvscalls,
								  list[tuple[str p, str v, QueryResult qr]] vvstargets,
								  list[tuple[str p, str v, QueryResult qr]] vvsprops,
								  list[tuple[str p, str v, QueryResult qr]] vvsptargets) 
{
	rel[str p, str file] lstFiles(list[tuple[str p, str v, QueryResult qr]] vv) = { < p, qr.l.path > | <p,_,qr> <- vv };
	rel[str p, str file] allHits = lstFiles(vvuses) + lstFiles(vvcalls) + lstFiles(vvmcalls) + lstFiles(vvnews) +
								   lstFiles(vvprops) + lstFiles(vvcconsts) + lstFiles(vvscalls) + lstFiles(vvstargets) +
								   lstFiles(vvsprops) + lstFiles(vvsptargets);

	lv = getLatestVersions();
	rel[str p, str file] allOthers = { };
	for (p <- lv) {
		pt = loadBinary(p,lv[p]);
		allOthers = allOthers + { < p, f.path > | f <- pt, <p,f.path> notin allHits }; 
		println("For <p>, <size(allHits[p])> hits and <size(allOthers[p])> others");
	}
	
	list[QueryResult] pvQueries(list[tuple[str p, str v, QueryResult qr]] vv, str p, str v, str file) = [ qr | <p,v,qr> <- vv, file := qr.l.path ];
	 									
	HistInfo res = { < p, file, 
	  size(pvQueries(vvuses, p, lv[p], file)), 
	  size(pvQueries(vvcalls, p, lv[p], file)),
	  size(pvQueries(vvmcalls, p, lv[p], file)), 
	  size(pvQueries(vvnews, p, lv[p], file)),
	  size(pvQueries(vvprops, p, lv[p], file)), 
	  size(pvQueries(vvcconsts, p, lv[p], file)),
	  size(pvQueries(vvscalls, p, lv[p], file)), 
	  size(pvQueries(vvstargets, p, lv[p], file)),
	  size(pvQueries(vvsprops, p, lv[p], file)), 
	  size(pvQueries(vvsptargets, p, lv[p], file)) > | < p, file > <- allHits } + (allOthers join {<0,0,0,0,0,0,0,0,0,0>});
	
	return res;
}

public void writeHistInfo(loc l, HistInfo h) {
	writeBinaryValueFile(l, h);
}

public HistInfo readHistInfo(loc l) {
	return readBinaryValueFile(#HistInfo, l);
}

alias HistInfo = rel[str p, str file, int variableVariables, int variableCalls, int variableMethodCalls, int variableNews, 
                     int variableProperties, int variableClassConsts, int variableStaticCalls, int variableStaticTargets,
                     int variableStaticProperties, int variableStaticPropertyTargets];

public void writeHistInfoCSV(HistInfo h) {
	lv = getLatestVersions();
	println("Building histogram data map");
	hm = ( <p,f> : <i1,i2,i3,i4,i5,i6,i7,i8,i9,i10> | <p,f,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10> <- h );
	println("Map built");
	
	str s = "p,file,variableVariables,variableCalls,variableMethodCalls,variableNews,variableProperties,variableClassConsts,variableStaticCalls,variableStaticTargets,variableStaticProperties,variableStaticPropertyTargets<for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); }), f <- sort(toList((h<0,1>)[p])), <i1,i2,i3,i4,i5,i6,i7,i8,i9,i10> := hm[<p,f>]) {>
		    '<p>,<f>,<i1>,<i2>,<i3>,<i4>,<i5>,<i6>,<i7>,<i8>,<i9>,<i10><}>
		    '\n";
		    
	writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/VarFeatures.csv|, s);
}

public str squiglies(HistInfo hi) {
   labels = [l | /label(l,_) := #HistInfo];
   return "\\begin{tikzpicture}
          '\\begin{groupplot}[group style={group size=2 by 5},height=4cm,width=\\columnwidth,xmin=1,axis x line=bottom, axis y line=left]
          '<squigly(hi<1,2>, labels[2])>
          '<squigly(hi<1,3>, labels[3])>
          '<squigly(hi<1,4>, labels[4])>
          '<squigly(hi<1,5>, labels[5])>
          '<squigly(hi<1,6>, labels[6])>
          '\\nextgroupplot [legend entries={<labels[7]><for (i <- [8..11]) {>, {<labels[i]>}<}>},legend style={nodes right, xshift=0.3cm, yshift=0.5cm}, legend pos=north east]
          '<labeledSquigly(hi<1,7>, labels[7])>
          '<labeledSquigly(hi<1,8>, labels[8])>
          '<labeledSquigly(hi<1,9>, labels[9])>
          '<labeledSquigly(hi<1,10>, labels[10])>
          '\\addplot+ [smooth] coordinates { (1,0) (10,0)};
	      '\\end{groupplot}
          '\\end{tikzpicture}
          ";
  
}

public str squigly(rel[str, int] counts, str label) {
  ds = distribution(counts);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  perc = (s - ds[0]) / s;
  perc = round(perc * 10000.0) / 100.0;
  return "\\nextgroupplot [title={<label> (<perc>\\%)},title style={yshift=-1cm}]
         '\\addplot+ [smooth] coordinates { <for (ev <- sort([*ds<0>]), ev != 0) {>(<ev>,<ds[ev]>) <}>};
         ";
}

public str squigly2(rel[str, int] counts, str label) {
  ds = distribution(counts);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  perc = (s - ds[0]) / s;
  perc = round(perc * 10000.0) / 100.0;
  if ((ds - (0:0)) == ()) {
    return "\\addplot+ [only marks, mark=text, text mark={}] coordinates { (1,1) }; \\label{<label>} \\addlegendentry{<label>}";
  }
  else {
    return "\\addplot+ [smooth] coordinates { <for (ev <- sort([*ds<0>]) /*, ev != 0 */) {>(<ev>,<ds[ev]>) <}>};  \\addlegendentry{<label>} \\label{<label>}
           ";
  }
}

public str squigly3(rel[str, int] counts, str label) {
  ds = distribution(counts);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  
  for (<y,50> <- counts) {
    println("<label> at 50% in <y>");
  }
  
  if ((ds - (0:0)) == ()) {
    return "\\addplot+ [only marks, mark=text, text mark={}] coordinates { (1,1) }; \\label{<label>}";
  }
  else {
    return "\\addplot+  coordinates { <for (ev <- [0,5..100] /*, ev != 0 */) {>(<ev>,<ev in ds ? ds[ev] : 0>) <}>};  \\addlegendentry{<label>} \\label{<label>}
           ";
  }
}

public str labeledSquigly(rel[str, int] counts, str label) {
  ds = distribution(counts);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  perc = (s - ds[0]) / s;
  perc = round(perc * 10000.0) / 100.0;
  return "\\addplot+ [smooth] coordinates { <for (ev <- sort([*ds<0>]), ev != 0) {>(<ev>,<ds[ev]>) <}>};
         ";
}

public void featureCountsPerFile() {
	map[str p, str v] lv = getLatestVersions();
	list[str] keyOrder = stmtKeyOrder() + exprKeyOrder() + classItemKeyOrder();
	str fileHeader = "product,version,file,<intercalate(",",["\\<rascalFriendlyKey(i)>" | i <- keyOrder ])>\n";
	writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/FeaturesByFile.csv|, fileHeader);
	
	for (product <- lv) {
		productAst = loadBinary(product,lv[product]);
		map[str file, map[str feature, int count] counts] counts = stmtAndExprCountsByFile(productAst);
		list[str] featureFile = [ ];
		for (file <- counts) {
			list[int] infoCounts = [ (f in counts[file]) ? counts[file][f] : 0 | f <- keyOrder ];
			featureFile += "<product>,<lv[product]>,<file>,<intercalate(",",infoCounts)>";
		}
		appendToFile(|project://PHPAnalysis/src/lang/php/extract/csvs/FeaturesByFile.csv|, intercalate("\n",featureFile) + "\n");	
	}

}

alias FMap = map[str file, tuple[int \break, int \classDef, int \const, int \continue, int \declare, int \do, int \echo, int \expressionStatementChainRule, int \for, int \foreach, int \functionDef, int \global, int \goto, int \haltCompiler, int \if, int \inlineHTML, int \interfaceDef, int \traitDef, int \label, int \namespace, int \return, int \static, int \switch, int \throw, int \tryCatch, int \unset, int \use, int \while, int \array, int \fetchArrayDim, int \fetchClassConst, int \assign, int \assignWithOperationBitwiseAnd, int \assignWithOperationBitwiseOr, int \assignWithOperationBitwiseXor, int \assignWithOperationConcat, int \assignWithOperationDiv, int \assignWithOperationMinus, int \assignWithOperationMod, int \assignWithOperationMul, int \assignWithOperationPlus, int \assignWithOperationRightShift, int \assignWithOperationLeftShift, int \listAssign, int \refAssign, int \binaryOperationBitwiseAnd, int \binaryOperationBitwiseOr, int \binaryOperationBitwiseXor, int \binaryOperationConcat, int \binaryOperationDiv, int \binaryOperationMinus, int \binaryOperationMod, int \binaryOperationMul, int \binaryOperationPlus, int \binaryOperationRightShift, int \binaryOperationLeftShift, int \binaryOperationBooleanAnd, int \binaryOperationBooleanOr, int \binaryOperationGt, int \binaryOperationGeq, int \binaryOperationLogicalAnd, int \binaryOperationLogicalOr, int \binaryOperationLogicalXor, int \binaryOperationNotEqual, int \binaryOperationNotIdentical, int \binaryOperationLt, int \binaryOperationLeq, int \binaryOperationEqual, int \binaryOperationIdentical, int \unaryOperationBooleanNot, int \unaryOperationBitwiseNot, int \unaryOperationPostDec, int \unaryOperationPreDec, int \unaryOperationPostInc, int \unaryOperationPreInc, int \unaryOperationUnaryPlus, int \unaryOperationUnaryMinus, int \new, int \castToInt, int \castToBool, int \castToFloat, int \castToString, int \castToArray, int \castToObject, int \castToUnset, int \clone, int \closure, int \fetchConst, int \empty, int \suppress, int \eval, int \exit, int \call, int \methodCall, int \staticCall, int \include, int \instanceOf, int \isSet, int \print, int \propertyFetch, int \shellExec, int \ternary, int \fetchStaticProperty, int \scalar, int \var, int \propertyDef, int \classConstDef, int \methodDef, int \traitUse] counts];

public void writeFeatsMap(FMap m) {
  writeBinaryValueFile(|tmp:///featsmap.bin|, m);
}

public FMap readFeatsMap() {
  return readBinaryValueFile(#FMap, |tmp:///featsmap.bin|);
}


public str generalFeatureSquiglies(FMap featsMap) {
   labels = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];
  //labels = ["break","classDef","const","continue","declare","do","echo","expressionStatementChainRule","for","foreach","functionDef","global","goto","haltCompiler","if","inlineHTML","interfaceDef","traitDef","label","namespace","return","static","switch","throw","tryCatch","unset","use","whileDef","array","fetchArrayDim","fetchClassConst","assign","assignWithOperationBitwiseAnd","assignWithOperationBitwiseOr","assignWithOperationBitwiseXor","assignWithOperationConcat","assignWithOperationDiv","assignWithOperationMinus","assignWithOperationMod","assignWithOperationMul","assignWithOperationPlus","assignWithOperationRightShift","assignWithOperationLeftShift","listAssign","refAssign","binaryOperationBitwiseAnd","binaryOperationBitwiseOr","binaryOperationBitwiseXor","binaryOperationConcat","binaryOperationDiv","binaryOperationMinus","binaryOperationMod","binaryOperationMul","binaryOperationPlus","binaryOperationRightShift","binaryOperationLeftShift","binaryOperationBooleanAnd","binaryOperationBooleanOr","binaryOperationGt","binaryOperationGeq","binaryOperationLogicalAnd","binaryOperationLogicalOr","binaryOperationLogicalXor","binaryOperationNotEqual","binaryOperationNotIdentical","binaryOperationLt","binaryOperationLeq","binaryOperationEqual","binaryOperationIdentical","unaryOperationBooleanNot","unaryOperationBitwiseNot","unaryOperationPostDec","unaryOperationPreDec","unaryOperationPostInc","unaryOperationPreInc","unaryOperationUnaryPlus","unaryOperationUnaryMinus","new","classConst","castToInt","castToBool","castToFloat","castToString","castToArray","castToObject","castToUnset","clone","closure","fetchConst","empty","suppress","eval","exit","call","methodCall","staticCall","include","instanceOf","isSet","print","propertyFetch","shellExec","exit","fetchStaticProperty","scalar","var","counts"];
//  feats = getFeats();
//  println("Building feats map");
//  featsMap = ( f : getOneFrom(feats[_,_,f]) | f <- feats<2> );
//  println("Done");
  //lls = (t.file:t.phplines | t <- ls);

  groups = ("binary ops"     : [ l | str l:/^binaryOp.*/ <- labels ])
         + ("unary ops"      : [l | str l:/^unaryOp.*/ <- labels ])
         + ("control flow"   : ["break","continue","declare","do","for","foreach","goto","if","return","switch","throw","tryCatch","while","exit","suppress","label","ternary","suppress","haltCompiler"])
         + ("assignment ops" : [l | str l:/^assign.*/ <-labels] + ["listAssign","refAssign", "unset"])
         + ("definitions" : ["functionDef","interfaceDef","traitDef","classDef","namespace","global","static","const","use","include","closure"])
         + ("invocations" : ["call","methodCall","staticCall", "eval", "shellExec"])
         + ("allocations" : ["array","new","scalar", "clone"]) 
         + ("casts"       : [l | str l:/^cast.*/ <- labels])
         + ("print"       : ["print","echo","inlineHTML" ])
         + ("predicates"  : ["isSet","empty","instanceOf"])
         + ("lookups"     : ["fetchArrayDim","fetchClassConst","var","fetchConst","propertyFetch","fetchStaticProperty"])
         ;
         
   groupLabels = sort([*groups<0>]);
         
//  indices = [ indexOf(l, labels) | l <- binOps];
//  binOpsMap = { <f, (0 | it + featsMap[f][i] | i <- indices)> | f <- featsMap};
  int counter = 0;
  return 
/*  "\\begin{figure}[t]
  '\\centering
  '\\begin{tikzpicture}
  '\\begin{loglogaxis}[grid=both, height=.5\\columnwidth,width=\\columnwidth,xmin=0,axis x line=bottom, axis y line=left,legend cell align=left, legend style={yshift=2cm}, cycle list name=exotic, legend columns=3]
  '<for (g <- groups) { indices = [ indexOf(labels, l) | l <- groups[g]];>
  '<squigly2({<file,sum([featsMap[file][i] | i <- indices ])> | file <- featsMap}, g)>
  '<}>\\end{loglogaxis}
  '\\end{tikzpicture}
  '\\end{figure}
  '
  '\\begin{figure}[t]
  '\\centering
  '\\begin{tikzpicture}
  '\\begin{axis}[grid=both, height=.5\\columnwidth,width=\\columnwidth,xmin=0,axis x line=bottom, axis y line=left,legend cell align=left,cycle list name=exotic, legend columns=2]
  '<for (g <- groups) { indices = [ indexOf(labels, l) | l <- groups[g]];>
  '<squigly3({<file,toInt(((sum([featsMap[file][i] | i <- indices ]) * 1.0) / s) * 200) / 10 * 5> | file <- featsMap, s := sum([e | e <- featsMap[file]]), s != 0}, g)>
  '<}>\\end{axis}
  '\\end{tikzpicture} 
  '\\end{figure}
  ' */
  "
  '\\begin{figure*}[t]
  '\\centering
  '\\begin{tikzpicture}
  '\\begin{semilogyaxis}[grid=both, ylabel={Frequency (log)}, xlabel={Feature ratio per file (\\%)},height=.5\\textwidth,width=\\textwidth,xmin=0,axis x line=bottom, axis y line=left,legend cell align=left,cycle list name=exotic, legend columns=2]
  '<for (g <- groups) { indices = [ indexOf(labels, l) | l <- groups[g]];>
  '<squigly3({<file,toInt(((sum([featsMap[file][i] | i <- indices ]) * 1.0) / s) * 200) / 10 * 5> | file <- featsMap, s := sum([e | e <- featsMap[file]]), s != 0}, g)>
  '<}>\\end{semilogyaxis}
  '\\end{tikzpicture}
  '\\caption{What features to expect in a given PHP file? This histogram shows, for each feature group, how many times it covers a certain percentage of the total number of features. Lines between dots are guidelines for the eye only.\\label{Figure:FeatureHistograms}} 
  '\\end{figure*}
  ";
  
}

public str shortLabel(str l) {
  switch (l) { 
    case /^.*Operation<rest:.*>/ : return shortLabel(rest);
    case /^whileDef/ : return  "while" ;
    case /^castTo<rest:.*>/ : return  "to<shortLabel(rest)>";
    case /^Bitwise<rest:.*>/ : return  "Bit<shortLabel(rest)>";
    case /^Left<rest:.*>/ : return  "L<rest>";
    case /^Right<rest:.*>/ : return  "R<rest>";
    case /^Boolean<rest:.*>/ : return  "Bool<rest>";
    case /^Logical<rest:.*>/ : return  "Log<rest>";
    case "NotIdentical" : return "NotId";
    default: return l;
  }
}

public str fileSizesHistogram(getLinesType ls) {
  ds = distribution(ls<file,phplines>);
  cds = cumulative(ds);
  
  return "\\begin{figure}
         '\\subfloat[Linear scale]{
         '\\begin{tikzpicture}
         '\\begin{axis}[grid=both, height=.5\\columnwidth,width=.5\\columnwidth,xmin=1,axis x line=bottom, axis y line=left]
         '\\addplot [only marks] coordinates {<for(x <- ds) {>(<x>,<ds[x]>) <}>};
         '\\draw [black, ultra thick] (axis cs:1000,0) -- node [label={98\\%}] (axis cs:1000,19000);
         '\\end{axis}
         '\\end{tikzpicture}
         '}
         '\\subfloat[Log scale]{
         '\\begin{tikzpicture}
         '\\begin{loglogaxis}[grid=both, height=.5\\columnwidth,width=.5\\columnwidth,xmin=1,axis x line=bottom, axis y line=left]
         '\\addplot+ [only marks] coordinates {<for(x <- ds) {>(<x>,<ds[x]>) <}>};
         '\\addplot+ [only marks] coordinates {<for(x <- cds) {>(<x>,<cds[x]>) <}>};
         '\\end{loglogaxis}
         '\\end{tikzpicture}
         '}
         '\\caption{PHP file sizes histogram\\label{Figure:FileSizeHistogram}}
         '\\end{figure}
         ";
}

public map[int,int] cumulative(map[int bucket,int frequency] dist) {
  buckets = sort([*dist<0>]);
  m = max(dist<1>);
  cur = 0;
  result = ();
  
  for (b <- buckets) {
    cur += dist[b];
    result[b] = cur;
  }
  
  return result;
}

public tuple[int threshold, int after] almostAll(map[int bucket, int cumulativeFrequency] dist) {
  m = max(dist<1>);
  th = 0.98 * m;
  
  for (b <- sort([*dist<0>])) {
    if (dist[b] >= th) {
      return <b, m - dist[b]>;
    }
  } 
}

public int main() {
  return 1;
}

public data FeatureNode = featureNode(set[str] features) | synthNode(set[str] features);
public anno set[str] FeatureNode@files;
public anno set[str] FeatureNode@transFiles;
public anno real FeatureNode@percent;

alias FeatureLattice = rel[FeatureNode,FeatureNode];

public FeatureLattice buildFeatureLattice(map[int,set[FeatureNode]] nodesBySize, FeatureNode bottomNode, int totalFiles) {
	rel[FeatureNode,FeatureNode] lattice = { };
	map[FeatureNode,set[FeatureNode]] coveredBy = ( n : { } | i <- nodesBySize, n <- nodesBySize[i] );
	map[FeatureNode,set[FeatureNode]] covers = ( n : { } | i <- nodesBySize, n <- nodesBySize[i] );
	map[FeatureNode,set[str]] transFiles = ( bottomNode : bottomNode@files );
	
	set[int] possibleIndices = nodesBySize<0>;
	list[int] insertionOrder = sort(toList(possibleIndices));
	for (i <- insertionOrder, i > 0) {
		println("Adding nodes for layer <i>");
		for (n <- nodesBySize[i]) {
			set[FeatureNode] children = { };
			set[FeatureNode] covered = { };
			for (ci <- reverse([0..i-1]), ci in possibleIndices) {
				set[FeatureNode] newChildren = { cn | cn <- nodesBySize[ci], cn notin covered, cn.features < n.features }; // , isEmpty(coveredBy[cn] & children) };
				covered = covered + { *covers[cn] | cn <- newChildren };
				children = children + newChildren; 
			}
			if (isEmpty(children)) children = { bottomNode };
			lattice += { < child, n > | child <- children };
			for (child <- children) coveredBy[child] = coveredBy[child] + n;
			covers[n] = children;
			transFiles[n] = { *(child@files) | child <- children };
		}
		println("Added <size(nodesBySize[i])> nodes");
		
		//println("Synthesizing missing nodes for layer <i>");
		//allChildren = { *(nodesBySize[j]) | j <- [0..i-1] };
		//directChildren = nodesBySize[i-1];
		//possibleNodes = { *(dc.features) | dc <- directChildren };
		//addedCounter = 0;
		//for (dc <- directChildren, pn <- (possibleNodes - dc.features), featureNode(dc.features+pn) notin nodesBySize[i]) {
		//	// Synthesize the node and add it to the bookkeeping structures
		//	synthNode = featureNode(dc.features + pn)[@files={}];
		//	coveredBy[synthNode] = { };
		//	covers[synthNode] = { };
		//	nodesBySize[i] = nodesBySize[i] + synthNode;
		//	addedCounter += 1;
		//	
		//	// As with the above, insert it into the lattice and set up the covering relation properly
		//	set[FeatureNode] children = { };
		//	set[FeatureNode] covered = { };
		//	for (ci <- reverse([0..i-1]), ci in possibleIndices) {
		//		set[FeatureNode] newChildren = { cn | cn <- nodesBySize[ci], cn notin covered, cn.features < synthNode.features }; // , isEmpty(coveredBy[cn] & children) };
		//		covered = covered + { *covers[cn] | cn <- newChildren };
		//		children = children + newChildren; 
		//	}
		//	if (isEmpty(children)) children = { bottomNode };
		//	lattice += { < child, synthNode > | child <- children };
		//	for (child <- children) coveredBy[child] = coveredBy[child] + synthNode;
		//	covers[synthNode] = children;
		//}
		//println("Synthesized <addedCounter> nodes");
	}
	
	println("Annotating lattice");
	lattice = visit(lattice) {
		case FeatureNode fn => (fn[@transFiles=transFiles[fn]])[@percent=size(transFiles[fn])*100.0/totalFiles]
	}
	return lattice;
}

public FMap getFMap() {
	feats = getFeats();
	FMap fmap = ( l : getOneFrom(feats[_,_,l]) | l <- feats<2> );
	return fmap;
}

public FeatureLattice calculateFeatureLattice(FMap fmap) {
	fieldNames = tail(tail(tail(getRelFieldNames((#getFeatsType).symbol))));
	indexes = ( i : fieldNames[i] | i <- index(fieldNames) );

	perFile = ( l : { } | l <- fmap );	
	for (l <- fmap, i <- indexes) if (int n := fmap[l][i], n > 0) perFile[l] = perFile[l] + indexes[i];
	
	sizesPerFile = ( l : size(perFile[l]) | l <- perFile );
	size2files = ( n : { } | n <- sizesPerFile<1> );
	for (l <- sizesPerFile) size2files[sizesPerFile[l]] = size2files[sizesPerFile[l]] + l;
	
	featuresToFiles = ( i : { } | i <- perFile<1>);
	for (l <- perFile) featuresToFiles[perFile[l]] = featuresToFiles[perFile[l]] + l;
	
	set[FeatureNode] nodes = { featureNode(i)[@files=featuresToFiles[i]] | i <- featuresToFiles };
	FeatureNode bottomNode = (featureNode({}) notin nodes) ? featureNode({})[@files={}] : getOneFrom({ i | i <- nodes, size(i.features) == 0});
	FeatureNode topNode = (featureNode(toSet(fieldNames)) notin nodes) ? featureNode(toSet(fieldNames))[@files={}] : getOneFrom({ i | i <- nodes, size(i.features) == size(fieldNames)});
	if (bottomNode notin nodes) nodes = nodes + bottomNode;
	if (topNode notin nodes) nodes = nodes + topNode;
	
	map[int,set[FeatureNode]] nodesBySize = ( n : { } | n <- (size2files<0>+0+size(fieldNames)) );
	for (n <- nodes) nodesBySize[size(n.features)] = nodesBySize[size(n.features)] + n;
	
	FeatureLattice lattice = buildFeatureLattice(nodesBySize);
	return lattice;
}

public FeatureLattice calculateTransitiveFiles(FeatureLattice lattice, FeatureNode top, int totalFiles) {
	flipped = invert(lattice);
	map[FeatureNode,set[str]] transFiles = ( );
	 
	void childFiles(FeatureNode current) {
		if (current in transFiles) return;
		
		children = flipped[current];
		if (size(children) == 0) {
			transFiles[current] = current@files;
			if (size(transFiles)%50 == 0) println("transFiles now has <size(transFiles)> elements");
		} else {
			for (child <- children) childFiles(child);
			transFiles[current] = current@files + { *transFiles[child] | child <- children };
			if (size(transFiles)%50 == 0) println("transFiles now has <size(transFiles)> elements");
			return;
		}
	}
	
	println("Computing transitive files for children");
	childFiles(top);
	
	println("Annotating lattice");
	lattice = visit(lattice) {
		case FeatureNode fn => (fn[@transFiles=transFiles[fn]])[@percent=size(transFiles[fn])*100.0/totalFiles]
	}
	return lattice;
}

public void checkGroups() {
  labels = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];
  groups = ("binary ops"     : [ l | str l:/^binaryOp.*/ <- labels ])
         + ("unary ops"      : [l | str l:/^unaryOp.*/ <- labels ])
         + ("control flow"   : ["break","continue","declare","do","for","foreach","goto","if","return","switch","throw","tryCatch","while","exit","suppress","label"])
         + ("assignment ops" : [l | str l:/^assign.*/ <-labels] + ["listAssign","refAssign", "unset"])
         + ("definitions" : ["functionDef","interfaceDef","traitDef","classDef","namespace","global","static","const","use","include","closure"])
         + ("invocations" : ["call","methodCall","staticCall", "eval", "shellExec"])
         + ("allocations" : ["array","new","scalar", "clone"]) 
         + ("casts"       : [l | str l:/^cast.*/ <- labels])
         + ("print"       : ["print","echo","inlineHTML" ])
         + ("predicates"  : ["isSet","empty","instanceOf"])
         + ("lookups"     : ["fetchArrayDim","fetchClassConst","var","classConst","fetchConst","propertyFetch","fetchStaticProperty"])
         ;
  keys = [rascalFriendlyKey(k) | k <- (exprKeyOrder()+stmtKeyOrder())];
  missing = toSet(keys) - {*g|g<-groups<1>};
  extra = {*g|g<-groups<1>} - toSet(keys);
  for (m <- missing) println("Missing: <m>");
  for (e <- extra) println("Extra: <e>");          
}

public tuple[set[FeatureNode],set[str],int] minimumFeaturesForPercent(FMap fmap, FeatureLattice lattice) {
	// Basic info we need for use below
	fieldNames = tail(tail(tail(getRelFieldNames((#getFeatsType).symbol))));
	indexes = ( i : fieldNames[i] | i <- index(fieldNames) );
	labelIndex = ( fieldNames[i] : i | i <- index(fieldNames) );

	// map from feature to the number of files that implement that feature
	featureFileCount = ( n : size({l|l<-fmap<0>,fmap[l][n]>0}) | n <- index(fieldNames) );
	
	// total number of files
	totalFileCount = size(fmap<0>);
	
	// map from feature to the percent of files that implement that feature
	featureFilePercent = ( n : featureFileCount[n]*100.0/totalFileCount | n <- featureFileCount );
	
	// features needed for a given percent -- if we aim for 20%, for instance, any feature occuring
	// in 80% or more of the files must be in this; we get both the IDs and the labels
	neededFor = ( m : { n | n <- featureFilePercent, featureFilePercent[n] > 100-m } | m <- [1..100] );
	neededForLabels = ( n : { indexes[p] | p <- neededFor[n] } | n <- neededFor );
	
	targetPercent = 50; // need to do this for others later, just get it working for now
	
	// Based on the percent, how many files (at least) do we need?
	threshold = round(totalFileCount * (targetPercent / 100.0));
	
	// Provisional solution
	nodes = carrier(lattice);
	solution = { n | n <- nodes, n.features < neededForLabels[targetPercent] };
	solutionLabels = neededForLabels[targetPercent];
	
	// How many have we found so far? This is the number of files covered by the solution
	found = size({ *(n@transFiles) | n <- solution});
	
	// Which features are left?
	remainingFeatures = toSet(fieldNames) - solutionLabels;
	
	// List of features to try -- just sort them by coverage amount
	featuresToTry = reverse(sort(toList(remainingFeatures),bool(str a, str b) { return featureFilePercent[labelIndex[a]] <= featureFilePercent[labelIndex[b]]; })); 

	for (feature <- featuresToTry) {
		solutionLabels += feature;
		solution = { n | n <- nodes, n.features < solutionLabels };
		found = size({ *(n@transFiles) | n <- solution});
		if (found > threshold) break;
	}

	return < solution, solutionLabels, found >;
}

