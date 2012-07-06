module lang::php::util::Utils

import util::ShellExec;
import IO;
import ValueIO;
import String;
import Set;
import List;
import Exception;
import DateTime;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;
import lang::csv::IO;

public Script loadPHPFile(loc l) {
	//println("Loading PHP file <l>");
	PID pid = createProcess(phploc.path, [rgenLoc.path, "<l.path>"], rgenCwd);
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	Script res = script([exprstmt(scalar(string("Could not parse file <l.path>: <phcErr>")))]);
	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) {
		if (trim(phcOutput) == "")
			res = errscript("Parser failed in unknown way");
		else
			res = readTextValueString(#Script, phcOutput);
	}
	killProcess(pid);
	return res;
}

public map[loc,Script] loadPHPFiles(loc l) {

	list[loc] entries = [ l + e | e <- listEntries(l) ];
	list[loc] dirEntries = [ e | e <- entries, isDirectory(e) ];
	list[loc] phpEntries = [ e | e <- entries, e.extension in {"php","inc"} ];

	map[loc,Script] phpNodes = ( );
	for (e <- phpEntries) {
		try {
			Script scr = loadPHPFile(e);
			phpNodes[e] = scr;
		} catch IO(msg) : {
			println("<msg>");
		} catch Java(msg) : {
			println("<msg>");
		}
	}
	for (d <- dirEntries) phpNodes = phpNodes + loadPHPFiles(d);
	
	return phpNodes;
}

public rel[str product, str version, loc fileloc, Script scr] loadCorpus() {

	rel[str product, str version, loc fileloc, Script scr] corpusItems = { };
	
	for (product <- getProducts()) {
		for (version <- getVersions(product)) {
			loc l = getCorpusItem(product,version);
			files = loadPHPFiles(l);
			for (fl <- files<0>) corpusItems += < product, version, fl, files[fl] >;
		}
	}	
	return corpusItems;
}

public rel[str product, str version, loc fileloc, Script scr] loadProduct(str product) {
	rel[str product, str version, loc fileloc, Script scr] corpusItems = { };
	
	for (version <- getVersions(product)) {
		loc l = getCorpusItem(product,version);
		files = loadPHPFiles(l);
		for (fl <- files<0>) corpusItems += < product, version, fl, files[fl] >;
	}
	return corpusItems;
}

public rel[str product, str version, loc fileloc, Script scr] loadProduct(str product, str version) {
	rel[str product, str version, loc fileloc, Script scr] corpusItems = { };

	loc l = getCorpusItem(product,version);
	files = loadPHPFiles(l);
	for (fl <- files<0>) corpusItems += < product, version, fl, files[fl] >;
	return corpusItems;
}

public void buildBinaries(str product, str version) {
	loc l = getCorpusItem(product,version);
	println("Parsing <product>-<version>");
	files = loadPHPFiles(l);
	loc binLoc = parsedDir + "<product>-<version>.pt";
	writeBinaryValueFile(binLoc, files);
}

public void buildBinaries(str product) {
	for (version <- getVersions(product))
		buildBinaries(product, version);
}

public void buildBinaries() {
	for (product <- getProducts(), version <- getVersions(product))
		buildBinaries(product, version);
}

public map[loc,Script] loadBinary(str product, str version) {
	parsedItem = parsedDir + "<product>-<version>.pt";
	return readBinaryValueFile(#map[loc,Script],parsedItem);
}

public void writeFeatureCounts(str product, str version, map[str,int] fc) {
	println("Writing counts for <product>-<version>");
	loc fcLoc = statsDir + "<product>-<version>.fc";
	writeBinaryValueFile(fcLoc, fc);
}

public void writeStats(str product, str version, map[str,int] fc, map[str,int] sc, map[str,int] ec) {
	loc fcLoc = statsDir + "<product>-<version>.fc";
	loc scLoc = statsDir +  "<product>-<version>.sc";
	loc ecLoc = statsDir +  "<product>-<version>.ec";
	writeBinaryValueFile(fcLoc, fc);
	writeBinaryValueFile(scLoc, sc);
	writeBinaryValueFile(ecLoc, ec);
}

public tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec] getStats(str product, str version) {
	loc fcLoc = statsDir + "<product>-<version>.fc";
	loc scLoc = statsDir +  "<product>-<version>.sc";
	loc ecLoc = statsDir +  "<product>-<version>.ec";
	return < readBinaryValueFile(#map[str,int],fcLoc), readBinaryValueFile(#map[str,int],scLoc), readBinaryValueFile(#map[str,int],ecLoc) >;
}

public map[tuple[str,str],tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec]] getStats(str product) {
	return ( < product, v > : getStats(product,v) | v <- getVersions(product) );
}

public map[tuple[str,str],tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec]] getStats() {
	return ( < product, v > : getStats(product,v) | product <- getProducts(), v <- getVersions(product) );
}

public list[tuple[str p, str v, map[str,int] fc, map[str,int] sc, map[str,int] ec]] getSortedStats() {
	list[tuple[str p, str v, map[str,int] fc, map[str,int] sc, map[str,int] ec]] res = [ ];
	
	sm = getStats();
	pvset = sm<0>;

	for (p <- sort(toList(pvset<0>)), v <- sort(toList(pvset[p]),compareVersion))
		res += < p, v, sm[<p,v>].fc, sm[<p,v>].sc, sm[<p,v>].ec >;
	
	return res;
}

public int loadCount(str product, str version) {
	countItem = countsDir + "<toLowerCase(product)>-<version>";
	if (!exists(countItem))
		countItem = countsDir + "<toLowerCase(product)>_<version>";
	if (!exists(countItem))
		throw "Could not find counts file for <product>-<version>";
	lines = readFileLines(countItem);
	if(l <- lines, /PHP\s+\d+\s+\d+\s+\d+\s+<phploc:\d+>/ := l) return toInt(phploc); 
	throw "Could not find PHP LOC counts for <product>-<version>";
}

public list[tuple[str p, str v, int count]] getSortedCounts() {
	return [ <p,v,loadCount(p,v)> | p <- sort(toList(getProducts())), v <- sort(toList(getVersions(p)),compareVersion) ];	
}

public void writeSortedCounts() {
	sc = getSortedCounts();
	scLines = [ "Product,Version,LoC" ] + [ "<i.p>,<i.v>,<i.count>" | i <- sc ];
	writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/linesOfCode.csv|, intercalate("\n",scLines));
}

public rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] loadVersionsCSV() {
	rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] res = readCSV(#rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments],|project://PHPAnalysis/src/lang/php/extract/csvs/Versions.csv|);
	return res;
	//return { <r.Product,r.Version,parseDate(r.ReleaseDate,"yyyy-MM-dd"),r.RequiredPHPVersion,r.Comments> | r <-res };  
}

public rel[str Product,str Version,int Count] loadCountsCSV() {
	rel[str Product,str Version,int Count] res = readCSV(#rel[str Product,str Version,int Count],|project://PHPAnalysis/src/lang/php/extract/csvs/linesOfCode.csv|);
	return res;
}

public map[str Product, str Version] getLatestVersions() {
	versions = loadVersionsCSV();
	return ( p : last(sort(toList(versions[p]<2,3>), bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[0] < t2[0]; }))[0] | p <- versions<0> );
}

public map[str Product, str Version] getLatestPHP4Versions() {
	versions = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versions<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5Versions() {
	versions = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versions<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v5l) );
}
