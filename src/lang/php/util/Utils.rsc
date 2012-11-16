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
	PID pid = createProcess(phploc.path, ["-d memory_limit=512M", rgenLoc.path, "<l.path>"], rgenCwd);
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	Script res = errscript("Could not parse file <l.path>: <phcErr>");
	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) {
		if (trim(phcOutput) == "")
			res = errscript("Parser failed in unknown way");
		else
			res = readTextValueString(#Script, phcOutput);
	}
	if (errscript(_) := res) println("Found error in file <l.path>");
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

public void buildMissingBinaries(str product, str version) {
	loc l = getCorpusItem(product,version);
	loc binLoc = parsedDir + "<product>-<version>.pt";
	if (!exists(binLoc)) {
		println("Parsing <product>-<version>");
		files = loadPHPFiles(l);
		writeBinaryValueFile(binLoc, files);
	}
}

public void buildBinaries(str product) {
	for (version <- getVersions(product))
		buildBinaries(product, version);
}

public void buildMissingBinaries(str product) {
	for (version <- getVersions(product))
		buildMissingBinaries(product, version);
}

public void buildBinaries() {
	for (product <- getProducts(), version <- getVersions(product))
		buildBinaries(product, version);
}

public void buildMissingBinaries() {
	for (product <- getProducts(), version <- getVersions(product))
		buildMissingBinaries(product, version);
}

public void buildNewestBinaries() {
	lv = getLatestVersions();
	for (product <- lv)
		buildBinaries(product, lv[product]);
}

public map[loc,Script] loadBinary(str product, str version) {
	parsedItem = parsedDir + "<product>-<version>.pt";
	println("Loading binary: <parsedItem>");
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

public tuple[int lineCount, int fileCount] loadCounts(str product, str version) {
	countItem = countsDir + "<toLowerCase(product)>-<version>";
	if (!exists(countItem))
		countItem = countsDir + "<toLowerCase(product)>_<version>";
	if (!exists(countItem))
		throw "Could not find counts file for <product>-<version>";
	lines = readFileLines(countItem);
	if(l <- lines, /PHP\s+<phpfiles:\d+>\s+\d+\s+\d+\s+<phploc:\d+>/ := l) return < toInt(phploc), toInt(phpfiles) >; 
	throw "Could not find PHP LOC counts for <product>-<version>";
}

public int loadCount(str product, str version) = loadCounts(product,version).lineCount;
public int loadFileCount(str product, str version) = loadCounts(product,version).fileCount;

public list[tuple[str p, str v, int count, int fileCount]] getSortedCounts() {
	return [ <p,v,lc,fc> | p <- sort(toList(getProducts())), v <- sort(toList(getVersions(p)),compareVersion), <lc,fc> := loadCounts(p,v) ];	
}

public void writeSortedCounts() {
	sc = getSortedCounts();
	scLines = [ "Product,Version,LoC,Files" ] + [ "<i.p>,<i.v>,<i.count>,<i.fileCount>" | i <- sc ];
	writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/linesOfCode.csv|, intercalate("\n",scLines));
}

public rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] loadVersionsCSV() {
	rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] res = readCSV(#rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments],|project://PHPAnalysis/src/lang/php/extract/csvs/Versions.csv|);
	return res;
	//return { <r.Product,r.Version,parseDate(r.ReleaseDate,"yyyy-MM-dd"),r.RequiredPHPVersion,r.Comments> | r <-res };  
}

public rel[str Product,str Version,int Count,int FileCount] loadCountsCSV() {
	rel[str Product,str Version,int Count,int FileCount] res = readCSV(#rel[str Product,str Version,int Count,int fileCount],|project://PHPAnalysis/src/lang/php/extract/csvs/linesOfCode.csv|);
	return res;
}

public map[str Product, str Version] getLatestVersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(vl)[0] | p <- versions<0>, vl := sort([ <v,d> | <v,d,pv,_> <- versions[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }) );
}

public map[str Product, str Version] getLatestPHP4VersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versions<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5VersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versions<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v5l) );
}

public map[str Product, str Version] getLatestVersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(vl)[0] | p <- versions<0>, vl := sort([ <v,d> | <v,d,pv,_> <- versions[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }) );
}

public map[str Product, str Version] getLatestPHP4VersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versions<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0], t2[0]); }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5VersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versions<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }), !isEmpty(v5l) );
}

public map[str Product, str Version] getLatestVersions() = getLatestVersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP4Versions() = getLatestPHP4VersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP5Versions() = getLatestPHP5VersionsByVersionNumber();


public str getPHPVersion(str product, str version) {
	versions = loadVersionsCSV();
	return getOneFrom(versions[product,version,_]<0>);
}

public str getReleaseDate(str product, str version) {
	versions = loadVersionsCSV();
	return getOneFrom(versions[product,version]<0>);
}

public map[tuple[str product, str version], map[loc l, Script scr]] getLatestTrees() {
	lv = getLatestVersions();
	return ( <p,lv[p]> : loadBinary(p,lv[p]) | p <- lv<0> );
}

public rel[str Product,str PlainText,str Description] loadProductInfoCSV() {
	rel[str Product,str PlainText,str Description] res = readCSV(#rel[str Product,str PlainText,str Description],|project://PHPAnalysis/src/lang/php/extract/csvs/ProductInfo.csv|);
	return res;
}
