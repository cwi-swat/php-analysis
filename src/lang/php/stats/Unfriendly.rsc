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

import lang::csv::IO;
import VVU = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/VarVarUses.csv?funname=varVarUses|;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=expressionCounts|;

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
   return "\\newcounter{plotOffset}	
          '\\setcounter{plotOffset}{1}% counters do not like floating point, so we have to divide it inside pgf
          '\\pgfplotsset{
          '  eeg/.style={
		  '    y filter/.code={\\pgfmathparse{\\pgfmathresult+(\\value{plotOffset}/10)}},
		  '    execute at begin plot={\\addtocounter{plotOffset}{5}}, % shift next plot 0.5 higher
		  '    no markers
          '  }
          '}
          '
          '\\begin{tikzpicture}
          '\\begin{axis}[axis y line=none, axis x line*=middle, y=1cm] % y defines the height between 0.0 and 1.0         
          '<squigly(hi<1,2>)>
          '<squigly(hi<1,3>)>
          '<squigly(hi<1,4>)>
          '<squigly(hi<1,5>)>
          '<squigly(hi<1,6>)>
          '<squigly(hi<1,7>)>
          '<squigly(hi<1,8>)>
          '<squigly(hi<1,9>)>
          '<squigly(hi<1,10>)>
          '<squigly(hi<1,11>)>          
	      '\\end{axis}
          '\\end{tikzpicture}
          ";
  
}

public str squigly(rel[str, int] counts) {
  ds = distribution(counts);
  s = sum((ds - (0:0))<1>) * 1.0;
  return "\\addplot+ [eeg] coordinates { (0,0)
          '<for (ev <- sort([*ds<0>]), ev != 0) {>(<ev>,<ds[ev] / s>) <}>
          '(<s>,0)};
          ";
}



