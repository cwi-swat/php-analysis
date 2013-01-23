module lang::php::stats::Unfriendly

import lang::php::util::Utils;
import lang::php::stats::Stats;
import lang::php::util::System;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::analysis::includes::IncludeCP;
import lang::php::analysis::includes::IncludeGraph;
import lang::rascal::types::AbstractType;
import lang::php::util::Config;
import lang::php::analysis::signatures::Summaries;
import lang::php::analysis::includes::ResolveIncludes;

import List;
import String;
import Set;
import Real;
import Relation;
import IO;
import ValueIO;
import Map;
import Node;
import util::Math;

import lang::csv::IO;
import VVU = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/VarVarUses.csv?funname=varVarUses|;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=expressionCounts|;
import Feats = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/FeaturesByFile.csv?funname=getFeats|;
import Sizes = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|;
import Versions = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/Versions.csv?funname=getVersions|;

data QueryResult
	= exprResult(loc l, Expr e)
	;
	
alias QueryResults = list[QueryResult];

public real mygini(list[tuple[num observation,int frequency]] values) {
	list[num] dup(num item, int frequency) {
		if (frequency <= 0) return [ ];
		return dup(item,frequency-1) + item;
	}
	
	return mygini([ *dup(o1,f) | <o1,f> <- values ]);
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

public tuple[list[tuple[str p, str v, QueryResult qr]] vvuses, 
			 list[tuple[str p, str v, QueryResult qr]] vvcalls,
			 list[tuple[str p, str v, QueryResult qr]] vvmcalls,
			 list[tuple[str p, str v, QueryResult qr]] vvnews,
			 list[tuple[str p, str v, QueryResult qr]] vvprops,
			 list[tuple[str p, str v, QueryResult qr]] vvcconsts,
			 list[tuple[str p, str v, QueryResult qr]] vvscalls,
			 list[tuple[str p, str v, QueryResult qr]] vvstargets,
			 list[tuple[str p, str v, QueryResult qr]] vvsprops,
			 list[tuple[str p, str v, QueryResult qr]] vvsptargets] getAllVV() 
{
	list[tuple[str p, str v, QueryResult qr]] vvuses = [ ]; 
	list[tuple[str p, str v, QueryResult qr]] vvcalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvmcalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvnews = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvprops = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvcconsts = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvscalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvstargets = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvsprops = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvsptargets = [ ];
	
	lv = getLatestVersions();
	for (product <- lv) {
		ptmap = loadBinary(product,lv[product]);

		vvuses += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherVarVarUses(ptmap)];
		vvcalls += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherVVCalls(ptmap)];
		vvmcalls += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherMethodVVCalls(ptmap)];
		vvnews += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherVVNews(ptmap)];
		vvprops += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherPropertyFetchesWithVarNames(ptmap)];
		vvcconsts += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherVVClassConsts(ptmap)];
		vvscalls += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherStaticVVCalls(ptmap)];
		vvstargets += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherStaticVVTargets(ptmap)];
		vvsprops += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherStaticPropertyVVNames(ptmap)];
		vvsptargets += [< product, lv[product], exprResult(e@at,e) > | <_,e> <-  gatherStaticPropertyVVTargets(ptmap)];
	}
	
	return < vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets >;
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
			 list[tuple[str p, str v, QueryResult qr]] vvsptargets] getAllVV(str product, str version, map[loc fileloc, Script scr] ptmap) 
{
	list[tuple[str p, str v, QueryResult qr]] vvuses = [ ]; 
	list[tuple[str p, str v, QueryResult qr]] vvcalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvmcalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvnews = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvprops = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvcconsts = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvscalls = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvstargets = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvsprops = [ ];
	list[tuple[str p, str v, QueryResult qr]] vvsptargets = [ ];
	
	vvuses += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherVarVarUses(ptmap)];
	vvcalls += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherVVCalls(ptmap)];
	vvmcalls += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherMethodVVCalls(ptmap)];
	vvnews += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherVVNews(ptmap)];
	vvprops += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherPropertyFetchesWithVarNames(ptmap)];
	vvcconsts += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherVVClassConsts(ptmap)];
	vvscalls += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherStaticVVCalls(ptmap)];
	vvstargets += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherStaticVVTargets(ptmap)];
	vvsprops += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherStaticPropertyVVNames(ptmap)];
	vvsptargets += [< product, version, exprResult(e@at,e) > | <_,e> <-  gatherStaticPropertyVVTargets(ptmap)];
	
	return < vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets >;
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

//public str showVVInfoAsLatex(list[tuple[str p, str v, QueryResult qr]] vvuses, 
//				 		   	 list[tuple[str p, str v, QueryResult qr]] vvcalls,
//							 list[tuple[str p, str v, QueryResult qr]] vvmcalls,
//							 list[tuple[str p, str v, QueryResult qr]] vvnews,
//							 list[tuple[str p, str v, QueryResult qr]] vvprops,
//							 list[tuple[str p, str v, QueryResult qr]] vvall) {
//	res = "\\begin{table*}
//		  '  \\centering
//		  '  <createSubfloat(vvuses,"Variable Variables","tbl-vvuses")>
//		  ' \\qquad
//		  '  <createSubfloat(vvcalls,"Variable Calls","tbl-vvcalls")>
//		  '
//		  '  <createSubfloat(vvmcalls,"Variable Method Calls","tbl-vvmcalls")>
//		  ' \\qquad
//		  '  <createSubfloat(vvprops,"Variable Properties","tbl-vvprops")>
//		  '
//		  '  <createSubfloat(vvnews,"Variable Instantiations","tbl-vvnews")>
//		  ' \\qquad
//		  '  <createSubfloat(vvall,"Combined","tbl-vvcombined")>
//		  '  \\caption{PHP Variable Features\\label{table-var}}
//		  '\\end{table*}
//		  '";
//	return res;
//}

public str showVVInfoAsLatex(list[tuple[str p, str v, QueryResult qr]] vvuses, 
				 		   	 list[tuple[str p, str v, QueryResult qr]] vvcalls,
							 list[tuple[str p, str v, QueryResult qr]] vvmcalls,
							 list[tuple[str p, str v, QueryResult qr]] vvnews,
							 list[tuple[str p, str v, QueryResult qr]] vvprops,
							 list[tuple[str p, str v, QueryResult qr]] vvall,
							 map[str,set[str]] transitiveUses) {
							 
	lv = getLatestVersions();
	ci = loadCountsCSV();
	hasGini = ( p : (size({qr|<p,_,qr> <- vvall}) > 1) ? true : false | p <- lv );
	
	gmap = resultsToGini(vvall);
	
	str headerLine() {
		return "Product & Files & \\multicolumn{19}{c}{PHP Variable Features} \\\\
		       '\\cmidrule{3-21}
		       ' & & \\multicolumn{2}{c}{Variables} & \\phantom{a} & \\multicolumn{2}{c}{Function Calls} & \\phantom{a} & \\multicolumn{2}{c}{Method Calls} & \\phantom{a} & \\multicolumn{2}{c}{Property Fetches} & \\phantom{a} & \\multicolumn{2}{c}{Instantiations} & \\phantom{a} & \\multicolumn{4}{c}{All} \\\\
		       '\\cmidrule{3-4} \\cmidrule{6-7} \\cmidrule{9-10} \\cmidrule{12-13} \\cmidrule{15-16} \\cmidrule{18-21}
		       ' &  & Files & Uses && Files & Uses && Files & Uses && Files & Uses && Files & Uses && Files & w/Inc & Uses & Gini \\\\ \\midrule";
	}
	
	str c(str p, list[tuple[str p, str v, QueryResult qr]] vv) = "\\numprint{<size({qr.l.path|<p,_,qr><-vv})>} & \\numprint{<size([qr|<p,_,qr><-vv])>}";
	
	str productLine(str p) {
		< lineCount, fileCount > = getOneFrom(ci[p,lv[p]]);
		return "<p> & \\numprint{<fileCount>} & <c(p,vvuses)> && <c(p,vvcalls)> && <c(p,vvmcalls)> && <c(p,vvprops)> && <c(p,vvnews)> && \\numprint{<size({qr.l.path|<p,_,qr><-vvall})>} & \\numprint{<size(transitiveUses[p])>} & \\numprint{<size([qr|<p,_,qr><-vvall])>} & < (!hasGini[p]) ? "N/A" : "\\nprounddigits{2} \\numprint{<round(gmap[p] * 100.0)/100.0>} \\npnoround" > \\\\";
	}

	res = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table*}
		  '\\centering
		  '\\ra{1.0}
		  '\\scriptsize
		  '\\begin{tabular}{@{}lrrrcrrcrrcrrcrrcrrrr@{}} \\toprule 
		  '<headerLine()> <for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '  <productLine(p)> <}>
		  '\\bottomrule
		  '\\end{tabular}
		  '\\normalsize
		  '\\caption{PHP Variable Features.\\label{table-var}}
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
							   list[tuple[str p, str v, QueryResult qr]] vvsptargets,
							   map[str,set[str]] transitiveUses
							   ) {
	res = showVVInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls + vvstargets + vvsprops + vvsptargets, transitiveUses);
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

alias ICLists = map[tuple[str product, str version] sysinfo, tuple[lrel[loc fileloc, Expr call] initial, lrel[loc fileloc, Expr call] unresolved] hits];

public ICLists includesAnalysis() {
	corpus = getLatestVersions();
	return includesAnalysis(corpus);
}

public ICLists includesAnalysis(Corpus corpus) {
	res = ( );
	for (product <- corpus) {
		sys = loadBinary(product,corpus[product]);
		initial = gatherIncludesWithVarPaths(sys);
		
		sysResolved = resolveIncludes(sys, getCorpusItem(product,corpus[product]));
		unresolved = gatherIncludesWithVarPaths(sysResolved);
		
		res[<product,corpus[product]>] = < initial, unresolved >;		
	}
	return res;
}

public ICLists includesAnalysisFromBinaries(Corpus corpus) {
	res = ( );
	for (product <- corpus) {
		sys = loadBinary(product,corpus[product]);
		initial = gatherIncludesWithVarPaths(sys);
		
		sysResolved = loadBinaryWithIncludes(product,corpus[product]);
		unresolved = gatherIncludesWithVarPaths(sysResolved);
		
		res[<product,corpus[product]>] = < initial, unresolved >;		
	}
	return res;
}

public void saveForLater(ICLists res) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/includes.bin|, res);
}

public ICLists reload() {
	return readBinaryValueFile(#ICLists, |project://PHPAnalysis/src/lang/php/serialized/includes.bin|); 
}

// NOTE: Technically, field resolved holds info on the number of unresolved includes
// left after all resolution attempts are made.
alias ICResult = map[tuple[str product, str version] sysinfo, tuple[tuple[int hc,int fc,real gc] initial, tuple[int hc,int fc,real gc] unresolved] counts];

public ICResult calculateIncludeCounts(ICLists res) {
	counts = ( );
	
	tuple[int hc, int fc, real gc] calc(list[tuple[loc fileloc, Expr call]] hits) {
		hc = size(hits);
		fc = size({ l.path | <l,_> <- hits });
		map[str,int] hitmap = ( );
		for (<l,e> <- hits)
			if (l.path in hitmap)
				hitmap[l.path] += 1;
			else
				hitmap[l.path] = 1;
		//hitmap = ( l.path : size([i|i:<l,_> <- hits]) | l <- {l | <l,_> <- hits} );
		//distmap = ( );
		//for (l <- hitmap) if (hitmap[l] in distmap) distmap[hitmap[l]] += 1; else distmap[hitmap[l]] = 1;
		distlist = [ hitmap[l] | l <- hitmap ];

		giniC = (size(distlist) > 1) ? mygini(distlist) : 0;
		giniToPrint = (giniC == 0.0) ? 0.0 : round(giniC*1000.0)/1000.0;

		//gc = round(mygini(distlist)*10000.0)/10000.0;
		return < hc, fc, giniToPrint >;
	}
	
	for (<p,v> <- res) {
		l1 = res[<p,v>].initial;
		l2 = res[<p,v>].unresolved;
		counts[<p,v>] = < calc(l1), calc(l2) >;
	}
	
	return counts;
}

public void saveIncludeCountsForLater(ICResult res) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/includeCounts.bin|, res);
}

public ICResult reloadIncludeCounts() {
	return readBinaryValueFile(#ICResult, |project://PHPAnalysis/src/lang/php/serialized/includeCounts.bin|); 
}

public map[tuple[str p, str v], int] includeCounts(Corpus corpus) {
	map[tuple[str p, str v], int] res = ( );
	for (p <- corpus) {
		sys = loadBinary(p,corpus[p]);
		totalIncludes = size([ i | /i:include(iexp,_) := sys ]);
		res[<p,corpus[p]>] = totalIncludes;
	}
	return res;
}

public void saveTotalIncludes(map[tuple[str p, str v], int] ti) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/totalIncludes.bin|, ti);
}

public map[tuple[str p, str v], int] loadTotalIncludes() {
	return readBinaryValueFile(#map[tuple[str p, str v], int], |project://PHPAnalysis/src/lang/php/serialized/totalIncludes.bin|);
}

public str generateIncludeCountsTable(ICResult counts, map[tuple[str p, str v], int] totalIncludes) {
	lv = ( p : v | <p,v> <- counts<0> );
	ci = loadCountsCSV();
		
	str productLine(str p) {
		v = lv[p];
		< lineCount, fileCount > = getOneFrom(ci[p,v]);
		giniC = counts[<p,v>].unresolved.gc;
		giniToPrint = (giniC == 0.0) ? 0.0 : round(giniC*1000.0)/1000.0;

		return "<p> & \\numprint{<totalIncludes[<p,v>]>} & \\numprint{<counts[<p,v>].initial.hc>}  & \\numprint{<counts[<p,v>].initial.hc-counts[<p,v>].unresolved.hc>} & \\numprint{<fileCount>}(\\numprint{<counts[<p,v>].unresolved.fc>}) & \\nprounddigits{2} \\numprint{<giniToPrint>} \\npnoround \\\\";
	}
		
	res = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '  \\centering
		  '  \\ra{1.2}
		  '  \\scriptsize
		  '  \\begin{tabular}{@{}lrrrrr@{}} \\toprule
		  '  Product & \\multicolumn{3}{c}{Includes} & Files & Gini \\\\
		  ' \\cmidrule{2-4} 
		  '   &  Total & Dynamic & Resolved & &  \\\\ \\midrule<for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '  \\normalsize
		  '  \\caption{PHP Non-Literal Includes.\\label{table-includes}}
		  '\\end{table}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";
	return res;	
}

public void writeIncludeCountsTable(ICResult counts) {
	writeFile(|home:///Documents/Papers/2012/php-icse12/includes.tex|, generateIncludeCountsTable(counts));
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

public str magicMethodCounts(MMResult res, map[str,set[str]] transitiveUses) {
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

		return "<p> & \\numprint{<size(hits<0>)>} & \\numprint{<size(transitiveUses[p])>} && \\numprint{<setsSize>} & \\numprint{<getsSize>} & \\numprint{<isSetsSize>} & \\numprint{<unsetsSize>} & \\numprint{<callsSize>} & \\numprint{<staticCallsSize>} & <(size(hits) > 1) ? "\\nprounddigits{2} \\numprint{<round(giniC*1000.0)/1000.0>} \\npnoround" : "N/A"> \\\\";
	}
		
	tbl = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '  \\centering
		  '  \\ra{1.0}
		  '\\scriptsize
		  '  \\begin{tabular}{@{}lrrcrrrrrrr@{}} \\toprule
		  '  Product & \\multicolumn{2}{c}{Files} & \\phantom{a} & \\multicolumn{6}{c}{Magic Methods} & GC \\\\
		  '  \\cmidrule{2-3} \\cmidrule{5-10}
		  '          & MM & WI && S & G & I & U & C & SC &  \\\\ \\midrule<for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '\\normalsize
		  '  \\caption{PHP Overloading (Magic Methods).\\label{table-magic}}
		  '\\end{table}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
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
   return "\\begin{figure}[t]
          '\\begin{tikzpicture}
          '\\begin{loglogaxis}[width=.6\\columnwidth, ymax=1000,grid=both,legend cell align=left,ylabel={Frequency (log)},xlabel={``Variable feature\'\' occurences per file (log)},cycle list name=exotic,legend pos=outer north east,legend style={xshift=-.1\\columnwidth}]
          '<squiglyRound(hi<1,2>, labels[2])>
          '<squiglyRound(hi<1,3>, labels[3])>
          '<squiglyRound(hi<1,4>, labels[4])>
          '<squiglyRound(hi<1,5>, labels[5])>
          '<squiglyRound(hi<1,6>, labels[6])>
          '\\end{loglogaxis}
          '\\end{tikzpicture}
          '\\hfill
          '\\begin{tikzpicture}
          '\\begin{axis}[width=.6\\columnwidth,grid=both,legend cell align=left,ylabel={Frequency},xlabel={``Variable feature\'\' occurences per file},cycle list name=exotic,legend pos=outer north east,legend style={xshift=-.1\\columnwidth}]
          '<squigly(hi<1,7>, labels[7])>
          '<squigly(hi<1,8>, labels[8])>
          '<squigly(hi<1,9>, labels[9])>
          '<squigly(hi<1,10>, labels[10])>
          '<squigly(hi<1,11>, labels[11])>
	      '\\end{axis}
          '\\end{tikzpicture}
          '\\caption{How ``variable features\'\' are distributed over the corpus. Lines are guidelines for the eye only. Percentages show how many files contain at least one of these features. The histograms show how many files contain how many of which variable feature.\\label{Figure:VariableFeatureHistograms}}
          '\\end{figure}
          ";
  
}

public str squigly(rel[str, int] counts, str label) {
  ds = distribution([b|<a,b> <- counts]);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  perc = (s - ds[0]) / s;
  perc = round(perc * 10000.0) / 100.0;
  return "\\addplot+ coordinates { <for (ev <- sort([*ds<0>]), ev != 0) {>(<ev>,<ds[ev]>) <}>};
         '\\addlegendentry{<shortLabel(label)> (<perc>\\%)}
         ";
}

public str squiglyRound(rel[str, int] counts, str label) {
  ds = distribution([b|<a,b> <- counts]);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  perc = (s - ds[0]) / s;
  perc = round(perc * 10000.0) / 100.0;
  return "\\addplot+ coordinates { <for (ev <- sort([*ds<0>]), ev != 0) {>(<ev>,<toInt(round(ds[ev] / 5.0) * 5)>) <}>};
         '\\addlegendentry{<shortLabel(label)> (<perc>\\%)}
         ";
}

public str squigly2(rel[str, int] counts, str label) {
  ds = distribution([b|<a,b> <- counts]);
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
  ds = distribution([b|<a,b> <- counts]);
  s = sum([ ds[n] | n <- ds ]) * 1.0;
  
  if ((ds - (0:0)) == ()) {
    return "\\addplot+ [only marks, mark=text, text mark={}] coordinates { (1,1) }; \\label{<label>}";
  }
  else {
    return "\\addplot+ [mark=<substring(label, 0, 1)>] coordinates { <for (ev <- [5,10..100] /*, ev != 0 */) {>(<ev>,<ev in ds ? ds[ev] : 0>) <}>};  \\addlegendentry{<label>} \\label{<label>}
           ";
  }
}

public str labeledSquigly(rel[str, int] counts, str label) {
  ds = distribution([b|<a,b> <- counts]);
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
  writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/featsmap.bin|, m);
}

public FMap readFeatsMap() {
  return readBinaryValueFile(#FMap, |project://PHPAnalysis/src/lang/php/serialized/featsmap.bin|);
}


public map[str,list[str]] getFeatureGroups() {
 labels = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];
  //labels = ["break","classDef","const","continue","declare","do","echo","expressionStatementChainRule","for","foreach","functionDef","global","goto","haltCompiler","if","inlineHTML","interfaceDef","traitDef","label","namespace","return","static","switch","throw","tryCatch","unset","use","whileDef","array","fetchArrayDim","fetchClassConst","assign","assignWithOperationBitwiseAnd","assignWithOperationBitwiseOr","assignWithOperationBitwiseXor","assignWithOperationConcat","assignWithOperationDiv","assignWithOperationMinus","assignWithOperationMod","assignWithOperationMul","assignWithOperationPlus","assignWithOperationRightShift","assignWithOperationLeftShift","listAssign","refAssign","binaryOperationBitwiseAnd","binaryOperationBitwiseOr","binaryOperationBitwiseXor","binaryOperationConcat","binaryOperationDiv","binaryOperationMinus","binaryOperationMod","binaryOperationMul","binaryOperationPlus","binaryOperationRightShift","binaryOperationLeftShift","binaryOperationBooleanAnd","binaryOperationBooleanOr","binaryOperationGt","binaryOperationGeq","binaryOperationLogicalAnd","binaryOperationLogicalOr","binaryOperationLogicalXor","binaryOperationNotEqual","binaryOperationNotIdentical","binaryOperationLt","binaryOperationLeq","binaryOperationEqual","binaryOperationIdentical","unaryOperationBooleanNot","unaryOperationBitwiseNot","unaryOperationPostDec","unaryOperationPreDec","unaryOperationPostInc","unaryOperationPreInc","unaryOperationUnaryPlus","unaryOperationUnaryMinus","new","classConst","castToInt","castToBool","castToFloat","castToString","castToArray","castToObject","castToUnset","clone","closure","fetchConst","empty","suppress","eval","exit","call","methodCall","staticCall","include","instanceOf","isSet","print","propertyFetch","shellExec","exit","fetchStaticProperty","scalar","var","counts"];
//  feats = getFeats();
//  println("Building feats map");
//  featsMap = ( f : getOneFrom(feats[_,_,f]) | f <- feats<2> );
//  println("Done");
  //lls = (t.file:t.phplines | t <- ls);

 return  ("binary ops"     : [ l | str l:/^binaryOp.*/ <- labels ])
         + ("unary ops"      : [l | str l:/^unaryOp.*/ <- labels ])
         + ("control flow"   : ["break","continue","declare","do","for","foreach","goto","if","return","switch","throw","tryCatch","while","exit","suppress","label","ternary","haltCompiler","expressionStatementChainRule"])
         + ("assignment ops" : [l | str l:/^assign.*/ <-labels] + ["listAssign","refAssign", "unset"])
         + ("definitions" : ["functionDef","interfaceDef","traitDef","classDef","namespace","global","static","const","use","include","closure","methodDef","classConstDef","propertyDef"])
         + ("invocations" : ["call","methodCall","staticCall", "eval", "shellExec"])
         + ("allocations" : ["array","new","scalar", "clone", "fetchArrayDim"]) 
         + ("casts"       : [l | str l:/^cast.*/ <- labels])
         + ("print"       : ["print","echo","inlineHTML" ])
         + ("predicates"  : ["isSet","empty","instanceOf"])
         + ("lookups"     : ["fetchClassConst","var","fetchConst","propertyFetch","fetchStaticProperty","traitUse"]);
}

public str groupsTable(set[str] notIn80, set[str] notIn90, set[str] notIn100) {
  gg = getFeatureGroups();
  
  str formatLabel(str orig, str l) {
    rval = l;
  	if (orig in notIn100) rval = "\\textbf{<rval>}";
  	if (orig in notIn90) rval = "\\textit{<rval>}";
  	if (orig in notIn80) rval = "\\underline{<rval>}";
  	return rval;
  }
  
  return "\\begin{table}
         '\\begin{tabularx}{\\columnwidth}{lX}
         '<for (g <- sort([*gg<0>])) {>\\textbf{<g>} & <intercalate(", ", [formatLabel(n,sn) | <n,sn> <- sort([<n,shortLabel(n)> | n <- gg[g]], bool(tuple[str s1,str s2] v1, tuple[str s1, str s2] v2) { return v1.s2 < v2.s2; })])> \\\\
         '<}> & \\\\ \\end{tabularx}
         '\\parbox{\\columnwidth}{Features in \\textbf{bold} are not used in the corpus. Features in \\textit{italics} and \\underline{underlined}
		 'are not needed to achieve 90\\% and 80\\% coverage of the corpus,respectively.}
         '\\ \\vspace{1ex}
         '\\caption{Logical groups of PHP features used to aggregrate usage data.\\label{Table:FeatureGroups}}
         '\\end{table}";
}

public str groupsTable() = groupsTable({},{},{});

public list[str] getFeatureLabels() = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];

//public void checkGroups() {
//  labels = getFeatureLabels();
//  groups = getFeatureGroups();
//  //keys = [rascalFriendlyKey(k) | k <- (exprKeyOrder()+stmtKeyOrder())];
//  missing = {*labels} - {*groups[g] | g <- groups};
//  extra = {*groups[g] | g <- groups} - {*labels};
//  for (m <- missing) println("Missing: <m>");
//  for (e <- extra) println("Extra: <e>");          
//}

public str generalFeatureSquiglies(FMap featsMap) {
   labels = getFeatureLabels();
   groups = getFeatureGroups();
         
   groupLabels = sort([*groups<0>]);
         
  int counter = 0;
  return 
  "<for (g <- groups) {>\\pgfdeclareplotmark{<substring(g,0,1)>}{\\pgfpathmoveto{\\pgfpoint{1em}{1em}}\\pgftext{<substring(g,0,1)>}}
  '<}>
  '\\begin{figure*}[t]
  '\\centering
  '\\begin{tikzpicture}
  '\\begin{semilogyaxis}[grid=both, ymax=10000, ylabel={Frequency (log)}, xlabel={Feature ratio per file (\\%)},height=.5\\textwidth,width=\\textwidth,xmin=0,axis x line=bottom, axis y line=left,legend cell align=left,cycle list name=exotic, legend columns=3,legend style={xshift=.4cm,yshift=.5cm}]
  '<for (g <- sort([*groups<0>])) { indices = [ indexOf(labels, l) | l <- groups[g]];>
  '<squigly3({<file,toInt(((sum([featsMap[file][i] | i <- indices ]) * 1.0) / s) * 200) / 10 * 5> | file <- featsMap, s := sum([e | e <- featsMap[file]]), s != 0}, g)>
  '<}>\\end{semilogyaxis}
  '\\end{tikzpicture}
  '\\caption{What features to expect in a given PHP file? This histogram shows, for each feature group, how many times it covers a certain percentage of the total number of features per file. Lines between dots are guidelines for the eye only.\\label{Figure:FeatureHistograms}} 
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
    case /^variable<rest:.*>/ : return shortLabel(rest);
    case /expressionStatementChainRule/ : return "expStmt";
    case /^fetchArrayDim/ : return "nextArrayElem";
    case "NotIdentical" : return "NotId";
    default: return l;
  }
}

public str fileSizesHistogram(getLinesType ls) {
  ds = distribution([ b | <a,b> <- ls<file,phplines>]);
  cds = cumulative(ds);
  
  return "\\begin{figure}
         '\\subfloat[Linear scale]{
         '\\begin{tikzpicture}
         '\\begin{axis}[ylabel={Frequency},xlabel={LOC},grid=both, height=.5\\columnwidth,width=.45\\columnwidth,xmin=1,axis x line=bottom, axis y line=left]
         '\\addplot [only marks] coordinates {<for(x <- ds) {>(<x>,<ds[x]>) <}>};
         '\\end{axis}
         '\\end{tikzpicture}
         '}
         '\\hfill
         '\\subfloat[Log scale]{
         '\\begin{tikzpicture}
         '\\begin{loglogaxis}[xlabel={LOC \\& cumulative LOC},grid=both, height=.5\\columnwidth,width=.45\\columnwidth,xmin=1,axis x line=bottom, axis y line=left]
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
	
	FeatureLattice lattice = buildFeatureLattice(nodesBySize, bottomNode, size(fmap<0>));
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

public tuple[set[FeatureNode],set[str],int] minimumFeaturesForPercent(FMap fmap, FeatureLattice lattice, int targetPercent) {
	println("Calculating coverage needed for <targetPercent>%");

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

	for (feature <- featuresToTry, featureFileCount[labelIndex[feature]] > 0) {
		solutionLabels += feature;
		solution = { n | n <- nodes, n.features < solutionLabels };
		found = size({ *(n@transFiles) | n <- solution});
		if (found > threshold) break;
	}

	return < solution, solutionLabels, found >;
}

public map[int,set[str]] minimumFeaturesForPercent2(FMap fmap, FeatureLattice lattice) {
	// The features in the system 
	features = toSet(tail(tail(tail(getRelFieldNames((#getFeatsType).symbol)))));
	
	// The nodes in the system, representing feature * file combinations
	nodes = carrier(lattice);

	// The total number of files in the system
	totalFileCount = size(fmap<0>);
	
	// labels that make up the solution (so far)
	set[str] solution = { };
	
	// Which features are left?
	set[str] remainingFeatures = features;
	
	// solutions -- map from percent (as int) to labels that cover it
	map[int,set[str]] res = ( );
	
	// covered so far (percent-wise)
	int coveredSoFar = 0;
	
	// Build some bookkeeping info -- this tells us which features we need to
	// achieve a certain percent of coverage, coming at it from the other way --
	// if we have 5% coverage, anything in more than 95% of the files must
	// be in it. So, neededForLabels[5] would have the names of any features
	// that occur in more than 95% of all files
	list[str] fieldNames = tail(tail(tail(getRelFieldNames((#getFeatsType).symbol))));
	map[int,str] indexes = ( i : fieldNames[i] | i <- index(fieldNames) ); 
	map[str,int] labelIndex = ( fieldNames[i] : i | i <- index(fieldNames) ); 
	map[int,int] featureFileCount = ( n : size({l|l<-fmap<0>,fmap[l][n]>0}) | n <- index(fieldNames) );
	map[int,real] featureFilePercent = ( n : featureFileCount[n]*100.0/totalFileCount | n <- featureFileCount ); 
	map[int,set[int]] neededFor = ( m : { n | n <- featureFilePercent, featureFilePercent[n] > 100-m } | m <- [1..100] ); 
	map[int,set[str]] neededForLabels = ( n : { indexes[p] | p <- neededFor[n] } | n <- neededFor ); 
	
	// seed the solution with all the features we need to achieve 1% coverage
	solution = neededForLabels[1];
	remainingFeatures = remainingFeatures - solution;
	
	// the features that aren't in there are left as the features to try
	featuresToTry = reverse(sort(toList(remainingFeatures),bool(str a, str b) { return featureFilePercent[labelIndex[a]] <= featureFilePercent[labelIndex[b]]; }));
	
	// now, continually grow until we cover 100% of the files
	while(coveredSoFar < 100) {
		// nextStepMap holds the number of files we cover if we choose a specific feature
		nextStepMap = ( feature : size({ *(n@transFiles) | n <- { n | n <- nodes, n.features < (solution + feature) } }) | feature <- remainingFeatures );
		// this then sorts the map results, getting back the one that adds the most files
		<nextFeature,nextFeatureCount> = head(reverse(sort([ < feature,nextStepMap[feature] > | feature <- nextStepMap ],bool(<str s1,int n1>, <str st,int n2>) { return n1 <= n2; })));

		// it is possible that any one feature won't extend our set of solutions; if that is the
		// case, we instead add the most popular
		if (nextFeatureCount == 0 || (size(nextStepMap<0>) > 1 && size(nextStepMap<1>) == 1)) {
			nextFeature = head(featuresToTry); featuresToTry = tail(featuresToTry);
			nextFeatureCount = size({*(n@transFiles) | n <- nodes, n.features < (solution+nextFeature)});
		}
			
		// Here, we did extend, so we add this feature into the solution
		solution += nextFeature; remainingFeatures -= nextFeature; featuresToTry -= nextFeature;

		// We may have grown by more than 1%, so check which percentiles we now cover
		while(coveredSoFar < 100) {
			nextTarget = round(((coveredSoFar + 1) / 100.0) * totalFileCount);
			if (nextFeatureCount >= nextTarget) {
				res[nextTarget] = solution;
				coveredSoFar += 1;
				println("Found coverage for <coveredSoFar>%, now covering <nextFeatureCount> files with <size(solution)> features.");

				// to push this more quickly to a solution, add in anything we know we will
				// need to reach the next percentile that isn't yet in there
				notInYet = neededForLabels[coveredSoFar+1] - solution;
				if (size(notInYet) > 0) {
					solution += notInYet; remainingFeatures -= notInYet; for (f <- notInYet) featuresToTry -= f;
					// if we did add something, extend the nextFeatureCount as well, since that should
					// also have grown (i.e., we cover more files now that we added more stuff into
					// the solution set)
					nextFeatureCount = size({*(n@transFile) | n <- nodes, n.features < solution});
				}
			} else {
				break;
			}
		}
	}

	return res;
}

public map[int,set[str]] featuresForPercents(FMap fmap, FeatureLattice lattice, list[int] percents) {
	return ( p : features | p <- percents, < nodes, features, files > := minimumFeaturesForPercent(fmap,lattice,p) );
}

public map[int,set[str]] featuresForAllPercents(FMap fmap, FeatureLattice lattice) {
	return featuresForPercents(fmap, lattice, [1..100]);
}

public map[int,set[str]] featuresForPercents2(FMap fmap, FeatureLattice lattice, list[int] percents) {
	return ( p : minimumFeaturesForPercent2(fmap,lattice,p) | p <- percents );
}

public map[int,set[str]] featuresForAllPercents2(FMap fmap, FeatureLattice lattice) {
	return featuresForPercents2(fmap, lattice, [1..100]);
}

public void saveCoverageMap(map[int,set[str]] coverageMap) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/coverageMap.bin|, coverageMap);
}

public map[int,set[str]] loadCoverageMap() {
	return readBinaryValueFile(#map[int,set[str]], |project://PHPAnalysis/src/lang/php/serialized/coverageMap.bin|);
}

public void saveFeatureLattice(FeatureLattice fl) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/featureLattice.bin|, fl);
}

public FeatureLattice loadFeatureLattice() {
	return readBinaryValueFile(#FeatureLattice, |project://PHPAnalysis/src/lang/php/serialized/featureLattice.bin|);
}

public str coverageGraph(map[int,set[str]] coverageMap) {
  
  angles = ( n : 90 | n <- coverageMap<0> ); angles[95] = 0; angles[100] = 90;
  position = ( n : "right" | n <- coverageMap<0> ); position[95] = "left"; position[100] = "left";
  
  return "\\begin{figure}
  		 '\\centering
         '\\begin{tikzpicture}
         '\\begin{axis}[grid=both, height=\\columnwidth,width=\\columnwidth,xmin=0,xmax=105,ymin=0,ymax=109,axis x line=bottom, axis y line=left,ylabel=Implemented Features,xlabel=Percent of Files Covered]
         '\\addplot [color=blue,only marks,mark=*] coordinates {<for(n <- sort(toList(coverageMap<0>)),n%5==0) {>(<n>,<size(coverageMap[n])>) <}>};
         '\\addplot [color=blue] coordinates {<for(n <- sort(toList(coverageMap<0>))) {>(<n>,<size(coverageMap[n])>) <}>};
         '<for(n<-sort(toList(coverageMap<0>)),n%5==0){>\\node[coordinate,pin={[color=black,rotate=<angles[n]>]<position[n]>:<size(coverageMap[n])>}] at (axis cs:<n>,<size(coverageMap[n])>) { };<}>
         '\\end{axis}
         '\\end{tikzpicture}
         '\\caption{Features Needed for File Coverage. Numbers given for each 5\\% increment. 109 Features Total. \\label{Figure:FileCoverageGraph}}
         '\\end{figure}
         ";
}

public str vvUsagePatternsTable() {
	vvUses = varVarUses();
	map[str,int] templateCounts = ( p : size({n|<n,p,path,line,"Y",at,mg,lpat,feach,sw,cond,der,notes> <- vvUses,(lpat=="X"||feach=="X"||sw=="X"||cond=="X")}) | p <- vvUses<1> );
	map[str,int] reflectiveCounts = ( p : size({n|<n,p,path,line,drv,at,mg,lpat,feach,sw,cond,der,notes> <- vvUses, drv != "Y"}) | p <- vvUses<1> );
	map[str,int] totalCounts = ( p : size({n| <n,p,_,_,_,_,_,_,_,_,_,_,_> <- vvUses}) | p <- vvUses<1> );
	
	templateTotal = ( 0 | it + templateCounts[p] | p <- templateCounts<0> );
	overallTotal = ( 0 | it + totalCounts[p] | p <- totalCounts<0> );
	templateAverage = round(templateTotal*10000.0/overallTotal)/100.0;

	lv = getLatestVersions();
	ver = getVersions();
	php4Products = { p | p <- lv, <_,phpv,_> <- ver[p,lv[p]], "4" := phpv[0] };

	templateTotalPHP5 = ( 0 | it + templateCounts[p] | p <- templateCounts<0>, p notin php4Products );
	overallTotalPHP5 = ( 0 | it + totalCounts[p] | p <- totalCounts<0>, p notin php4Products );
	templateAveragePHP5 = round(templateTotalPHP5*10000.0/overallTotalPHP5)/100.0;
	  	
	str productLine(str p) {
		return "<p> & <templateCounts[p]> & <reflectiveCounts[p]> & <totalCounts[p]> \\\\";
	}
		
	res = "\\begin{table}
		  '  \\centering
		  '  \\ra{1.1}
		  '  \\begin{tabular}{@{}lrrr@{}} \\toprule
		  '  Product & \\multicolumn{3}{c}{Variable-Variable Uses} \\\\
		  '  \\cmidrule{2-4}
		  '          & Derivable Names & Other & Total \\\\ \\midrule<for (p <- sort(toList(totalCounts<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '  \\parbox{.8\\columnwidth}{Across all systems, <templateAverage>\\% of the uses have derivable names. In those systems that use PHP5, <templateAveragePHP5>\\% of the uses have derivable names.}
		  '  \\caption{Derivability of Variable-Variable Name Assignments.\\label{table-varvar-patterns}}
		  '\\end{table}
		  '";
		  
	return res;	
}

public set[loc] getVVLocs(list[tuple[str p, str v, QueryResult qr]] vv) = { qr.l | <_,_,qr> <- vv };
public set[loc] getVVLocs(str p, str v, list[tuple[str p, str v, QueryResult qr]] vv) = { qr.l | <p,v,qr> <- vv };

@doc{Given an includes graph and a set of files, return these files plus the files that (transitively) import them.}
public set[str] calculateFeatureTrans(IncludeGraph ig, set[loc] featureLocs, str prefix) {
	featureFiles = { substring(l.path,size(prefix)) | l <- featureLocs };
	igCollapsed = collapseToGraph(ig);
	
	igFlipped = invert(igCollapsed);
	igTrans = igFlipped+;
	
	importers = igTrans[featureFiles];
	return importers + featureFiles;
}

public map[str,set[str]] calculateVVTransIncludes(
	list[tuple[str p, str v, QueryResult qr]] vvuses, 
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
	map[str,set[str]] transitiveFiles = ( );
	lv = getLatestVersions();
	
	for (product <- lv) {
		version = lv[product];
		pt = loadBinaryWithIncludes(product,version);
		corpusItemLoc = getCorpusItem(product,version);
		IncludeGraph ig = extractIncludeGraph(pt, corpusItemLoc.path);
		vvLocs = { qr.l | <product,version,qr> <- (vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls + vvstargets + vvsprops + vvsptargets) };
		transFiles = calculateFeatureTrans(ig, vvLocs, corpusItemLoc.path);
		transitiveFiles[product] = transFiles;
	}
	
	return transitiveFiles;
} 

//alias MMResult = map[tuple[str p, str v], tuple[list[ClassItem] sets, list[ClassItem] gets, list[ClassItem] isSets, list[ClassItem] unsets, list[ClassItem] calls, list[ClassItem] staticCalls]];

public map[str,set[str]] calculateMMTransIncludes(MMResult mmr)
{
	map[str,set[str]] transitiveFiles = ( );
	lv = getLatestVersions();
	
	for (product <- lv) {
		version = lv[product];
		pt = loadBinaryWithIncludes(product,version);
		corpusItemLoc = getCorpusItem(product,version);
		IncludeGraph ig = extractIncludeGraph(pt, corpusItemLoc.path);
		mmrLocs = { mm@at | mm <- (mmr[<product,version>].sets + mmr[<product,version>].gets + mmr[<product,version>].isSets + mmr[<product,version>].unsets + mmr[<product,version>].calls + mmr[<product,version>].staticCalls) };
		transFiles = calculateFeatureTrans(ig, mmrLocs, corpusItemLoc.path);
		transitiveFiles[product] = transFiles;
	}
	
	return transitiveFiles;
} 

public void writeIncludeBinaries(Corpus corpus) {
	for (product <- corpus) {
		version = corpus[product];
		pt = loadBinary(product,version);
		pt2 = resolveIncludes(pt,getCorpusItem(product,corpus[product]));
		parsedItem = parsedDir + "<product>-<version>-icp.pt";
		println("Writing binary: <parsedItem>");
		writeBinaryValueFile(parsedItem, pt2);
	}
}

public map[loc,Script] loadBinaryWithIncludes(str product, str version) {
	parsedItem = parsedDir + "<product>-<version>-icp.pt";
	println("Loading binary: <parsedItem>");
	return readBinaryValueFile(#map[loc,Script],parsedItem);
}

public NotCoveredMap notCoveredBySystem(FeatureLattice lattice, map[int,set[str]] coverageMap) {
	fieldNames = toSet(tail(tail(tail(getRelFieldNames((#getFeatsType).symbol)))));
	
	in80 = coverageMap[80];
	in90 = coverageMap[90];
	
	in80Files = { *(n@files) | n <- carrier(lattice), n.features < in80 };
	in90Files = { *(n@files) | n <- carrier(lattice), n.features < in90 };
	
	lv = getLatestVersions();
	
	map[str product,tuple[set[str] notIn80, set[str] notIn90] filesNotCovered] res = ( );
	for (product <- lv) {
		pt = loadBinary(product,lv[product]);
		res[product] = < {l.path|l<-pt<0>} - in80Files, {l.path|l<-pt<0>} - in90Files >;
	}
	
	return res;
}

alias NotCoveredMap = map[str product, tuple[set[str] notIn80, set[str] notIn90] filesNotCovered];

public void writeNotCoveredInfo(NotCoveredMap notCovered) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/notCovered.bin|, notCovered);
}

public NotCoveredMap readNotCoveredInfo() {
	return readBinaryValueFile(#NotCoveredMap, |project://PHPAnalysis/src/lang/php/serialized/notCovered.bin|);
}

public str coverageComparison(NotCoveredMap ncm) {
	filecount = loadCountsCSV();
	lv = getLatestVersions();

	eightyPer = ( );
	ninetyPer = ( );
	
	for (p <- sort(toList(lv<0>),bool(str s1,str s2) { return toUpperCase(s1) <= toUpperCase(s2); }), v := lv[p], <notIn80,notIn90> := ncm[p], <v,_,fc> <- filecount[p]) {
		eightyPer[p] = 100.0-round(size(notIn80)*10000.0/fc)/100.0;
		ninetyPer[p] = 100.0-round(size(notIn90)*10000.0/fc)/100.0;
	}
	
	pOrder = reverse(sort(toList(lv<0>), bool(str s1,str s2) { return eightyPer[s1] <= eightyPer[s2]; }));
	
	tbl = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '  \\centering
		  '  \\ra{1.2}
		  '  \\begin{tabular}{@{}lrr@{}} \\toprule
		  '  Product & \\multicolumn{2}{c}{\\%  Covered By} \\\\
		  '  \\cmidrule{2-3}
		  '  & 80\\% Features & 90\\% Features \\\\ \\midrule<for (p <- pOrder) {>
		  '    <p> & \\nprounddigits{1} \\numprint{<eightyPer[p]>}\\% \\npnoround & \\nprounddigits{1} \\numprint{<ninetyPer[p]>}\\% \\npnoround \\\\ <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '  \\caption{Percent of System Covered by Feature Sets.\\label{table-fset-cover}}
		  '\\end{table}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";
	return tbl;	
		//return "<p> & \\numprint{<fileCount>} & <c(p,vvuses)> && <c(p,vvcalls)> && <c(p,vvmcalls)> && <c(p,vvprops)> && <c(p,vvnews)> && \\numprint{<size({qr.l.path|<p,_,qr><-vvall})>} & \\numprint{<size(transitiveUses[p])>} & \\numprint{<size([qr|<p,_,qr><-vvall])>} & < (!hasGini[p]) ? "N/A" : "\\nprounddigits{2} \\numprint{<round(gmap[p] * 100.0)/100.0>} \\npnoround" > \\\\";
}	

alias EvalUses = rel[str product, str version, loc fileloc, Expr call];

public EvalUses corpusEvalUses(Corpus corpus) {
	rel[str product, str version, loc fileloc, Expr call] res = { };
	for (p <- corpus) {
		corpusItem = loadBinary(p,corpus[p]);
		evals = gatherEvals(corpusItem);
		for (<l,e> <- evals) res += < p, corpus[p], l, e >;
	}
	return res;
}

public void saveEvalUses(EvalUses evalUses) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/evalUses.bin|, evalUses);
}

public EvalUses loadEvalUses() {
	return readBinaryValueFile(#EvalUses, |project://PHPAnalysis/src/lang/php/serialized/evalUses.bin|);
}

public map[str,set[str]] calculateEvalTransIncludes(Corpus corpus, EvalUses evalUses)
{
	map[str,set[str]] transitiveFiles = ( );
	
	for (product <- corpus) {
		version = corpus[product];
		pt = loadBinaryWithIncludes(product,version);
		corpusItemLoc = getCorpusItem(product,version);
		IncludeGraph ig = extractIncludeGraph(pt, corpusItemLoc.path);
		evalLocs = { l | l <- evalUses[product, version]<0>  };
		transFiles = calculateFeatureTrans(ig, evalLocs, corpusItemLoc.path);
		transitiveFiles[product] = transFiles;
	}
	
	return transitiveFiles;
} 

public map[str,set[str]] calculateTransIncludes(Corpus corpus, set[loc] locset)
{
	map[str,set[str]] transitiveFiles = ( );
	
	for (product <- corpus) {
		version = corpus[product];
		pt = loadBinaryWithIncludes(product,version);
		corpusItemLoc = getCorpusItem(product,version);
		IncludeGraph ig = extractIncludeGraph(pt, corpusItemLoc.path);
		transFiles = calculateFeatureTrans(ig, locset, corpusItemLoc.path);
		transitiveFiles[product] = transFiles;
	}
	
	return transitiveFiles;
} 

public str evalCounts(Corpus corpus, EvalUses evalUses, FunctionUses fuses) {
	ci = loadCountsCSV();
	fuses = createFunctionUses(fuses);
	
	str productLine(str p) {
		v = corpus[p];
		< lineCount, fileCount > = getOneFrom(ci[p,v]);
		evalsForProduct = size(evalUses[p,v]);
		hits = ( );
		for (<l,e> <- (evalUses[p,v]+fuses[p,v])) {
			hitloc = l.path;
			if (hitloc in hits)
				hits[hitloc] += 1;
			else
				hits[hitloc] = 1;
		}
		giniC = (size(hits) > 1) ? mygini([ hits[hl] | hl <- hits ]) : 0;
		giniToPrint = (giniC == 0.0) ? 0.0 : round(giniC*1000.0)/1000.0;
		return "<p> & \\numprint{<fileCount>} & \\numprint{<size(hits<0>)>} && \\numprint{<size(evalUses[p,v])>}/\\numprint{<size(fuses[p,v])>}  & <(size(hits) > 1) ? "\\nprounddigits{2} \\numprint{<giniToPrint>} \\npnoround" : "N/A">  \\\\";
	}
		
	tbl = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '  \\centering
		  '  \\ra{1.1}
		  '\\scriptsize
		  '  \\begin{tabular}{@{}lrrcrr@{}} \\toprule
		  '  Product & \\multicolumn{2}{c}{Files} & \\phantom{a} & Total Uses & Gini \\\\
		  '  \\cmidrule{2-3} 
		  '          & Total & w/eval logic & & & \\\\ \\midrule<for (p <- sort(toList(corpus<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '\\normalsize
		  '  \\caption{Usage of \\texttt{eval} and \\texttt{create\\_function}.\\label{table-eval}}
		  '\\end{table}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";
	return tbl;		
}

alias FunctionUses = rel[str product, str version, loc fileloc, Expr call];

public FunctionUses systemFunctionUses(str product, str version, System sys) {
	rel[str product, str version, loc fileloc, Expr call] res = { };
	funsToFind = { "create_function", "call_user_func", "call_user_func_array", "call_user_method", "call_user_method_array", "func_get_args", "func_num_args", "func_get_arg" };
	evals = [ < e@at, e > | /e:call(name(name(str fn)),_) := sys, fn in funsToFind ];
	for (<l,e> <- evals) res += < product, version, l, e >;
	return res;
}

public FunctionUses corpusFunctionUses(Corpus corpus)
	= { *systemFunctionUses(p, corpus[p], loadBinary(p,corpus[p])) | p <- corpus };

public void saveFunctionUses(FunctionUses functionUses) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/functionUses.bin|, functionUses);
}

public FunctionUses loadFunctionUses() {
	return readBinaryValueFile(#FunctionUses, |project://PHPAnalysis/src/lang/php/serialized/functionUses.bin|);
}

public void functionUsesByFun(FunctionUses functionUses) {
	for (<p,v> <- functionUses<0,1>) {
		functionsForPV = functionUses[p,v];
		map[str,int] fcount = ( );
		for (<l,e> <- functionsForPV, call(name(name(fn)),_) := e) {
			if (fn notin fcount)
				fcount[fn] = 1;
			else
				fcount[fn] = fcount[fn] + 1;
		}
		println(p);
		for (fn <- fcount) {
			println("<fn>:<fcount[fn]>");
		}
	}
}

public str functionUsesCounts(Corpus corpus, FunctionUses functionUses) {
	ci = loadCountsCSV();
	
	str productLine(str p) {
		v = corpus[p];
		< lineCount, fileCount > = getOneFrom(ci[p,v]);
		usesForProduct = size(functionUses[p,v]);
		hits = ( );
		for (<l,e> <- functionUses[p,v]) {
			hitloc = l.path;
			if (hitloc in hits)
				hits[hitloc] += 1;
			else
				hits[hitloc] = 1;
		}
		giniC = (size(hits) > 1) ? mygini([ hits[hl] | hl <- hits ]) : 0;
		giniToPrint = (giniC == 0.0) ? 0.0 : round(giniC*1000.0)/1000.0;
		return "<p> & \\numprint{<fileCount>} & \\numprint{<size(hits<0>)>} && \\numprint{<size(functionUses[p,v])>}  & <(size(hits) > 1) ? "\\nprounddigits{2} \\numprint{<giniToPrint>} \\npnoround" : "N/A">  \\\\";
	}
		
	tbl = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '  \\centering
		  '  \\ra{1.1}
		  '\\scriptsize
		  '  \\begin{tabular}{@{}lrrcrr@{}} \\toprule
		  '  Product & \\multicolumn{2}{c}{Files} & \\phantom{a} & Function Uses & Gini \\\\
		  '  \\cmidrule{2-3} 
		  '          & Total & w/\\texttt{eval} & & &  \\\\ \\midrule<for (p <- sort(toList(corpus<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '    <productLine(p)> <}>
		  '  \\bottomrule
		  '  \\end{tabular}
		  '\\normalsize
		  '  \\caption{Usage of Variadic Functions.\\label{table-fuses}}
		  '\\end{table}
		  '\\npfourdigitnosep
		  '\\npnoaddmissingzero
		  '";
	return tbl;		
}

public FunctionUses filterFunctionUses(FunctionUses functionUses, set[str] fnames) =
	{ fu | fu:<p,v,l,e> <- functionUses, call(name(name(s)),_) := e, s in fnames };

public FunctionUses filterFunctionUses(FunctionUses functionUses, str fname) =
	filterFunctionUses(functionUses, { fname });

public FunctionUses createFunctionUses(FunctionUses functionUses) =
	filterFunctionUses(functionUses, "create_function");

public FunctionUses invokeFunctionUses(FunctionUses functionUses) =
	filterFunctionUses(functionUses, { "call_user_func", "call_user_func_array" });

public FunctionUses varargsFunctionUses(FunctionUses functionUses) =
	filterFunctionUses(functionUses, { "func_get_args", "func_num_args", "func_get_arg" });
	
public data Def 
	= functionDef(str functionName, Stmt functionDef, loc defLoc) 
	| methodDef(str className, str methodName, ClassItem methodDef, loc defLoc)
	;
	
public set[Def] varargsFunctionsAndMethods(System sys) {
	set[Def] res = { };
	funsToFind = { "func_get_args", "func_num_args", "func_get_arg" };
	
	for (/f:function(fname, _, _, body) := sys) {
		if (/e:call(name(name(str fn)),_) := body, fn in funsToFind) {
			res += functionDef(fname, f, f@at);   
		}
	}
	for (/c:class(cname, _, _, _, members) := sys) {
		for (m:method(name, modifiers, byRef, params, body) <- members) {
			if (/e:call(name(name(str fn)),_) := body, fn in funsToFind) {
				res += methodDef(cname, name, m, m@at);   
			}
		}
	}
	return res;
}

public rel[loc,Expr,bool] varargsCalls(System sys) {
	// Get the varargs functions and methods in the current system
	defs = varargsFunctionsAndMethods(sys);
	
	// Get the varargs functions and methods in the library
	functionSummaries = loadFunctionSummaries();
	functionSummaries = { fs | fs:functionSummary(_,ps,_,_,_,_) <- functionSummaries, p <- ps, /Var/ := getName(p) };
	methodSummaries = loadMethodSummaries();
	methodSummaries = { ms | ms:methodSummary(_,_,ps,_,_,_,_) <- methodSummaries, p <- ps, /Var/ := getName(p) };
	
	// Build maps from the function names to their definitions
	functionDefs = ( fn : d | d:functionDef(fn,_,_) <- defs );
	systemFunctionNames = functionDefs<0>;
	functionNames = systemFunctionNames + { fn | functionSummary(fn,_,_,_,_,_) <- functionSummaries };
	
	// Also do the same with methods -- here we collapse these into a
	// relation for method names (since we could have multiple methods
	// of the same name but different classes), plus we grab just the
	// method names for matching below
	methodDefs = ( cn : ( mn : d | d:methodDef(cn,mn,_,_) <- defs ) | cn <- { cn | methodDef(cn,_,_,_) <- defs } );
	flatMethodDefs = { < mn , d > | d:methodDef(_,mn,_,_) <- defs };
	systemMethods = flatMethodDefs<0>;
	methodNames = systemMethods + { mn | methodSummary(mn,_,_,_,_,_,_) <- methodSummaries };
	
	// Now, find calls to the varargs functions and methods. We can have standard
	// function calls, standard method calls, and calls to static methods.
	rel[loc,Expr,bool] vaCalls = { };
	visit(sys) {
		case e:call(name(name(str fn)),args) : {
			if (fn in functionNames)
				vaCalls = vaCalls + < e@at, e, fn in systemFunctionNames >;
		}
		
		case e:methodCall(_,name(name(str fn)),args) : {
			if (fn in methodNames)
				vaCalls = vaCalls + < e@at, e, fn in systemMethods>;
		}
		
		case e:staticCall(_,name(name(str fn)),args) : {
			if (fn in methodNames)
				vaCalls = vaCalls + < e@at, e, fn in systemMethods>;
		}
	}

	return vaCalls;
}

public rel[str,str,loc,Expr,bool] varargsCalls(Corpus corpus) {
	rel[str,str,loc,Expr,bool] res = { };
	for (p <- corpus) {
		sys = loadBinary(p,corpus[p]);
		sysCalls = varargsCalls(sys);
		res += { <p,corpus[p],l,e,b> | <l,e,b> <- sysCalls };
	}
	return res;
}

public rel[loc,Expr] allCalls(System sys) {
	return { < e@at, e > | /e:call(name(name(str fn)),args) := sys } + 
		   { < e@at, e > | /e:methodCall(_,name(name(str fn)),args) := sys } +
		   { < e@at, e > | /e:staticCall(_,name(name(str fn)),args) := sys };
}

public rel[str,str,loc,Expr] allCalls(Corpus corpus) {
	rel[str,str,loc,Expr] res = { };
	for (p <- corpus) {
		sys = loadBinary(p,corpus[p]);
		sysCalls = allCalls(sys);
		res += { <p,corpus[p],l,e> | <l,e> <- sysCalls };
	}
	return res;
}

public void saveAllCalls(rel[str,str,loc,Expr] calls) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/allCalls.bin|, calls);	
}

public rel[str,str,loc,Expr] loadAllCalls() {
	return readBinaryValueFile(#rel[str,str,loc,Expr], |project://PHPAnalysis/src/lang/php/serialized/allCalls.bin|);
}

public void saveVarargsCalls(rel[str,str,loc,Expr,bool] calls) {
	writeBinaryValueFile(|project://PHPAnalysis/src/lang/php/serialized/varargsCalls.bin|, calls);	
}

public rel[str,str,loc,Expr,bool] loadVarargsCalls() {
	return readBinaryValueFile(#rel[str,str,loc,Expr,bool], |project://PHPAnalysis/src/lang/php/serialized/varargsCalls.bin|);
}

public map[str product,tuple[int classes, int interfaces] ciCount] classAndInterfaceCount(Corpus corpus) {
	map[str product,tuple[int classes, int interfaces] ciCount] res = ( );
	for (p <- corpus) {
		sys = loadBinary(p,corpus[p]);
		classCount = size({ c | /c:class(_,_,_,_,_) := sys });
		interfaceCount = size({ i | /i:interface(_,_,_) := sys });
		res[p] = < classCount, interfaceCount >;
	}
	return res;
}

public rel[str product, str path] classAndInterfaceFiles(Corpus corpus) {
	rel[str product, str path] res = { };
	for (p <- corpus) {
		sys = loadBinary(p,corpus[p]);
		classPaths = { c@at.path | /c:class(_,_,_,_,_) := sys };
		interfacePaths = { i@at.path | /i:interface(_,_,_) := sys };
		res += { < p, pth > | pth <- (classPaths + interfacePaths) };
	}
	return res;
}