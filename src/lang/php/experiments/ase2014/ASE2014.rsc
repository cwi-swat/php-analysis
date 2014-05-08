module lang::php::experiments::ase2014::ASE2014

import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::php::stats::Stats;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::analysis::includes::IncludesInfo;
import lang::php::analysis::includes::QuickResolve;
import lang::php::analysis::includes::ScriptResolve;
import lang::php::analysis::includes::LibraryIncludes;
import IO;
import Set;
import List;
import String;
import ValueIO;
import DateTime;
import util::Math;

private map[str,set[str]] extensions = (
	//"Symfony" : { "php", "inc", "cache", "map", "phar", "dist" }
	);

private set[str] getExtensions(str p) {
	if (p in extensions) return extensions[p];
	return { "php", "inc" };
}

@doc{The base corpus used in the ASE 2014 submission.}
private Corpus ase14BaseCorpus = (
	"osCommerce":"2.3.3.4",
	"ZendFramework":"1.12.3",
	"CodeIgniter":"2.1.4",
	"Symfony":"2.4.0",
	"SilverStripe":"3.1.2",
	"WordPress":"3.8.1",
	"Joomla":"3.2.1",
	"phpBB":"3.0.12",
	"Drupal":"7.24",
	"MediaWiki":"1.22.0",
	"Gallery":"3.0.9",
	"SquirrelMail":"1.4.22",
	"Moodle":"2.6",
	"Smarty":"3.1.16",
	"Kohana":"3.3.1",
	"phpMyAdmin":"4.1.3-english",
	"PEAR":"1.9.4",
	"CakePHP":"2.4.4",
	"DoctrineORM":"2.3.3",
	"Magento":"1.8.1.0");

private map[str,set[loc]] usedLibs = (
	"MediaWiki" : getStandardLibraries("PearMail", "PearMailMime", "PHPUnit"),
	"CakePHP" : getStandardLibraries("PHPUnit"),
	"SilverStripe" : getStandardLibraries("PHPUnit", "Benchmark", "CodeCoverage"),
	"Joomla" : getStandardLibraries("PearCache", "PearCacheLite"),
	"SquirrelMail" : getStandardLibraries("PearDB"),
	"Kohana" : getStandardLibraries("PHPUnit"),
	"phpMyAdmin" : getStandardLibraries("PearSOAP", "PearOpenID", "PearCrypt"),
	"PEAR" : getStandardLibraries("PearArchiveTar", "PearBase", "PearStructuresGraph", "PearConsoleGetopt", "PearXMLUtil", "PearCommandPackaging"),
	"Magento" : getStandardLibraries("PearBase","PearPackageFileManager","PearPackageFileManager2", "PearNetDIME", "PearXMLUtil"),
	"ZendFramework" : getStandardLibraries("PHPUnit", "PHPUnitDB", "PHPUnitException" ),
	"Moodle" : getStandardLibraries("PearBase", "PHPUnit", "PHPUnitDB")
);

@doc{Library paths for the various applications, based on the installation instructions}
private map[str,list[str]] defaultIncludePaths = (
	"osCommerce" : ["."]
);

private list[str] getIncludePath(str p) {
	if (p in defaultIncludePaths)
		return defaultIncludePaths[p];
	else
		return [ ];
}

@doc{The location of serialized quick resolve information}
private loc infoLoc = baseLoc + "serialized/quickResolved";

@doc{Build the corpus files.}
public void buildCorpus(Corpus corpus) {
	for (p <- corpus, v := corpus[p]) {
		buildBinaries(p,v,extensions=getExtensions(p));
	}
}

@doc{Run the quick resolve over the entire base corpus}
public void doQuickResolve() {
	doQuickResolve(getBaseCorpus());
}

@doc{Run the quick resolve over the entire provided corpus}
public void doQuickResolve(Corpus corpus) {
	for (p <- corpus, v := corpus[p]) {
		pt = loadBinary(p,v);
		IncludesInfo iinfo = loadIncludesInfo(p, v);
		rel[loc,loc,loc] res = { };
		println("Resolving for <size(pt<0>)> files");
		counter = 0;
		for (l <- pt) {
			qr = quickResolve(pt, iinfo, l, getCorpusItem(p,v) libs = (p in usedLibs) ? usedLibs[p] : { });
			res = res + { < l, ll, lr > | < ll, lr > <- qr };
			counter += 1;
			if (counter % 100 == 0) {
				println("Resolved <counter> files");
			}
		}
		writeBinaryValueFile(infoLoc + "<p>-<v>-qr.bin", res);
	}
}

@doc{Run the quick resolve over the entire provided corpus, saving reduced expressions}
public void doQuickResolveExpr(Corpus corpus) {
	for (p <- corpus, v := corpus[p]) {
		pt = loadBinary(p,v);
		IncludesInfo iinfo = loadIncludesInfo(p, v);
		rel[loc,loc,Expr,loc] res = { };
		println("Resolving <p> for <size(pt<0>)> files");
		counter = 0;
		for (l <- pt) {
			qr = quickResolveExpr(pt, iinfo, l, getCorpusItem(p,v) libs = (p in usedLibs) ? usedLibs[p] : { });
			res = res + { < l, ll, e, lr > | < ll, e, lr > <- qr };
			counter += 1;
			if (counter % 100 == 0) {
				println("Resolved <counter> files");
			}
		}
		writeBinaryValueFile(infoLoc + "<p>-<v>-qre.bin", res);
	}
}

@doc{Reload the quick resolve info.}
public rel[loc,loc,loc] loadQuickResolveInfo(str p, str v) {
	return readBinaryValueFile(#rel[loc,loc,loc], infoLoc + "<p>-<v>-qr.bin");
}

@doc{Reload the quick resolve info with expressions.}
public rel[loc,loc,Expr,loc] loadQuickResolveExprInfo(str p, str v) {
	return readBinaryValueFile(#rel[loc,loc,Expr,loc], infoLoc + "<p>-<v>-qre.bin");
}
@doc{Compute basic distribution: how many possibilities for each include?}
public map[int hits, int includes] computeQuickResolveCounts(str p, str v) {
	map[int hits, int includes] res = ( );
	rel[loc,loc,loc] perFileCounts = loadQuickResolveInfo(p,v);
	pt = loadBinary(p,v);
	ptIncludes = { < lf, i@at > | lf <- pt, /i:include(_,_) := pt[lf] };
	for (lf <- pt, li <- ptIncludes[lf]) {
		icount = size(perFileCounts[lf,li]);
		if (icount == 0) println(li);
		if (icount in res) {
			res[icount] += 1;
		} else {
			res[icount] = 1;
		}
	}
	return res;
}

public map[tuple[str p, str v] s, map[int hits, int includes] res] computeQuickResolveCounts(Corpus corpus) {
	map[tuple[str p, str v] s, map[int hits, int includes] res] res = ( );
	for (p <- corpus, v := corpus[p]) {
		res[<p,v>] = computeQuickResolveCounts(p,v);
	}
	return res;
}

public void saveQuickResolveCounts(map[tuple[str p, str v] s, map[int hits, int includes] res] counts) {
	writeBinaryValueFile(infoLoc + "qr-summary.bin", counts);
}

public map[tuple[str p, str v] s, map[int hits, int includes] res] loadQuickResolveCounts() {
	return readBinaryValueFile(#map[tuple[str p, str v] s, map[int hits, int includes] res], infoLoc + "qr-summary.bin");
}

public str createQuickResolveCountsTable() {
	counts = loadQuickResolveCounts();
	corpus = getBaseCorpus();
	
	str headerLine() {
		return "System & Includes & Dynamic & Unique & Missing & Any & Other & Average \\\\ \\midrule";
	}
	
	str productLine(str p, str v) {
		map[int hits, int includes] m = counts[<p,v>];
		total = ( 0 | it + m[h] | h <- m<0> );
		pt = loadBinary(p,v);
		dyn = total - size([ i | /i:include(ip,_) := pt, scalar(sv) := ip, encapsed(_) !:= sv ]);
		unique = (1 in m) ? m[1] : 0;
		missing = (0 in m) ? m[0] : 0;
		files = size(pt<0>);
		threshold = floor(files * 0.9);
		anyinc = ( 0 | it + m[h] | h <- m<0>, h >= threshold );
		other = total - unique - anyinc;
		denom = ( 0 | it + m[h] | h <- m<0>, h > 1, h < threshold );
		avg = (denom == 0) ? 0 : ( ( 0 | it + (m[h] * h) | h <- m<0>, h > 1, h < threshold ) * 1.000 / denom);
							
		return "<p> & \\numprint{<total>} & \\numprint{<dyn>} & \\numprint{<unique>} & \\numprint{<missing>} & \\numprint{<anyinc>} & \\numprint{<other>} & \\nprounddigits{2} \\numprint{<avg>} \\npnoround \\\\";
	}

	res = "\\npaddmissingzero
		  '\\npfourdigitsep
		  '\\begin{table}
		  '\\centering
		  '\\ra{1.0}
		  '\\resizebox{\\columnwidth}{!}{%
		  '\\begin{tabular}{@{}lrrrrrrr@{}} \\toprule 
		  '<headerLine()> <for (p <- sort(toList(corpus<0>),bool(str s1,str s2) { return toUpperCase(s1)<toUpperCase(s2); })) {>
		  '  <productLine(p,corpus[p])> <}>
		  '\\bottomrule
		  '\\end{tabular}
		  '}
		  '\\caption{File-Level Resolution.\\label{table-quick}}
		  '\\end{table}
		  '";
	return res;
}

@doc{Retrieve the base corpus}
public Corpus getBaseCorpus() = ase14BaseCorpus;

@doc{The location of serialized quick resolve information}
private loc incLoc = baseLoc + "serialized/progResolved";

data ResolveInfo = rinfo(str p, str v, loc l, tuple[rel[loc,loc] resolved, lrel[str,datetime] timings] res);
data RInfoMap = rmap(map[loc,int] rmap, int nextidx);

@doc{Load the resolved info map.}
public RInfoMap loadResolveInfoMap() {
	lipath = incLoc + "rinfo.map";
	if (exists(lipath)) {
		return readBinaryValueFile(#RInfoMap, lipath);
	} else {
		return rmap(( ), 1);
	}
}

public void saveResolveInfoMap(RInfoMap rmap) {
	lipath = incLoc + "rinfo.map";
	writeBinaryValueFile(lipath, rmap);
}

public void buildResolveInfo(Corpus corpus, str p, set[loc] files) {
	RInfoMap rmap = loadResolveInfoMap();
	rootloc = getCorpusItem(p,corpus[p]);
	pt = loadBinary(p, corpus[p]);
	qrei = loadQuickResolveExprInfo(p,corpus[p]);
	map[loc,rel[loc,Expr,loc]] qrmap = ( );
	for (<lf,li,e,lr> <- qrei) {
		if (lf in qrmap) {
			qrmap[lf] = qrmap[lf] + < li, e, lr >;
		} else {
			qrmap[lf] = { < li, e, lr > };
		}
	}
	for (f <- files) {
		println("Resolving script <f>");
		res = scriptResolve(pt, p, corpus[p], f, rootloc, ipath=getIncludePath(p), quickResolveInfo=qrmap);
		ResolveInfo ri = rinfo(p, corpus[p], f, res);
		lipath = incLoc + "ri<rmap.nextidx>.bin";
		writeBinaryValueFile(lipath, ri);
		rmap.rmap[f] = rmap.nextidx;
		rmap.nextidx = rmap.nextidx + 1;
	}
	saveResolveInfoMap(rmap);
}