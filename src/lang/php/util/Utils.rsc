@license{
  Copyright (c) 2009-2013 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::Utils

import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;

import IO;
import ValueIO;
import util::ValueUI;
import String;
import Set;
import List;
import Exception;
import DateTime;
import util::ShellExec;

import lang::php::pp::PrettyPrinter;


@javaClass{org.rascal.phpanalysis.PhpJarExtractor}
@memo
private java loc getPhpParserLocFromJar() throws IO(str msg);


private str executePHP(list[str] opts, loc cwd) {
	str phpBinLoc = usePhpParserJar ? "php" : phploc.path;

  	PID pid = createProcess(phpBinLoc, opts, cwd);
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	killProcess(pid);

	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) {
		return phcOutput;
	}
	
	throw IO("error calling php");
}

private Script parsePHPfile(loc f, list[str] opts, Script error) {
	loc parserLoc = usePhpParserJar ? getPhpParserLocFromJar() : lang::php::util::Config::parserLoc;

	str phpOut;
	try {
		phpOut = executePHP(["-d memory_limit=<parserMemLimit>", "-d short_open_tag=On", (parserLoc + astToRascal).path, "-f<f.path>"] + opts, parserWorkingDir);
	} catch RuntimeException: {
		return error;
	}

	res = errscript("Parser failed in unknown way");
	if (trim(phpOut) != "") {
		try { 
			res = readTextValueString(#Script, phpOut);
		} catch e : {
			res = errscript("Parser failed: <e>");
		}			
	}

	return res;
}

@doc{Test if a running version php is available on the path}
@memo
public bool testPHPInstallation() {
	str hello = "hello world";
	try {
		return hello == trim(executePHP(["-r echo \"<hello>\";"], |tmp:///|));
	}
	catch RuntimeException:
	 	return false;
}

@doc{Parse an individual PHP statement using the external parser, returning the associated AST.}
public Stmt parsePHPStatement(str s) {
	tempFile = parserLoc + "tmp/parseStmt.php";
	if (!exists(tempFile.parent)) {
		mkDirectory(tempFile.parent);
	}
	writeFile(tempFile, "\<?php\n<s>?\>");
	Script res = parsePHPfile(tempFile, [], errscript("Could not parse <s>"));
	if (errscript(re) := res) throw "Found error in PHP code to parse: <re>";
	if (script(sl) := res && size(sl) == 1) return head(sl);
	if (script(sl) := res) return block(sl);
	throw "Could not parse statement <s>";
}

@doc{Parse an individual PHP expression using the external parser, returning the associated AST.}
public Expr parsePHPExpression(str s) {
	if (exprstmt(e) := parsePHPStatement(s)) return e;
	throw "Could not parse expression <s>";
}

@doc{Load a single PHP file with location annotations.}
public Script loadPHPFile(loc l) throws AssertionFailed {
	return loadPHPFile(l, true, false);
}

@doc{Load a single PHP file, with options for location annotations and unique node ids.}
public Script loadPHPFile(loc l, bool addLocationAnnotations, bool addUniqueIds) throws AssertionFailed {
	if (!exists(l)) return errscript("Location <l> does not exist");
	if (l.scheme notin {"file","home"}) return errscript("Only file and home locations are supported");
	if (!isFile(l)) return errscript("Location <l> must be a file");

	logMessage("Loading file <l>", 2);
	
	list[str] opts = [ ];
	if (addLocationAnnotations) opts += "-l";
	if (includeLocationInfo) opts += "--addDecl";
	if (addUniqueIds) opts += "-i";
	if (l.scheme == "home") opts += "-r";
	if (includePhpDocs) opts += "--phpdocs";
	
	Script res = parsePHPfile(l, opts, errscript("Could not parse file <l.path>")); 
	if (errscript(err) := res) logMessage("Found error in file <l.path>. Error: <err>", 2);
	return res;
}

@doc{Load all PHP files at a given directory location, with options for location annotations and unique node ids.}
public System loadPHPFiles(loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) throws AssertionFailed {
	return loadPHPFiles(l, extensions, loadPHPFile, addLocationAnnotations, addUniqueIds);
}

@doc{Load all PHP files at a given directory location, with options for which loader to use, location annotations and unique node ids.}
public System loadPHPFiles(loc l, Script(loc,bool,bool) loader, bool addLocationAnnotations = true, bool addUniqueIds = false) throws AssertionFailed {
	return loadPHPFiles(l, {"php", "inc"}, loader, addLocationAnnotations, addUniqueIds);
}

@doc{Load all PHP files at a given directory location, with options for which extensions are PHP files, which loader to use, location annotations and unique node ids.}
public System loadPHPFiles(loc l, set[str] extensions, Script(loc,bool,bool) loader, bool addLocationAnnotations = true, bool addUniqueIds = false) throws AssertionFailed {
	return loadPHPFiles(l, extensions, loader, addLocationAnnotations, addUniqueIds);
}

@doc{Load all PHP files at a given directory location, with options for which extensions are PHP files, which loader to use, location annotations and unique node ids.}
private System loadPHPFiles(loc l, set[str] extensions, Script(loc,bool,bool) loader, bool addLocationAnnotations, bool addUniqueIds) throws AssertionFailed {

	if ((l.scheme == "file" || l.scheme == "home") && !exists(l)) throw AssertionFailed("Location <l> does not exist");
	if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");

	// regex filter exlucdes test/	
	list[loc] entries = [ l + e | e <- listEntries(l)];
	list[loc] dirEntries = [ e | e <- entries, isDirectory(e)];
	list[loc] phpEntries = [ e | e <- entries, e.extension in extensions];

	System phpNodes = ( );
	
	increaseFolderCounter();
	if (folderTotal == 0) setFolderTotal(l);
	
	if (size(phpEntries) > 0) {	
		logMessage("<((folderCounter * 100) / folderTotal)>% [<folderCounter>/<folderTotal>] Parsing <size(phpEntries)> files in directory: <l>", 2);
		for (e <- phpEntries) {
			try {
				Script scr = loader(e, addLocationAnnotations, addUniqueIds);
				phpNodes[e] = scr;
			} catch IO(msg) : {
				println("<msg>");
			} catch Java(msg) : {
				println("<msg>");
			}
		}
	}
	
	for (d <- dirEntries) phpNodes = phpNodes + loadPHPFiles(d, extensions, loader, addLocationAnnotations, addUniqueIds);
	resetCounters();
		
	return phpNodes;
}

@doc{Load a specific system from the corpus}
public System loadProduct(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	loc l = getCorpusItem(product,version);
	return loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Build the serialized ASTs for a specific system at a specific location}
public void buildBinaries(str product, str version, loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) {
	logMessage("Parsing <product>-<version>. \>\> Location: <l>.", 1);
	files = loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
	
	loc binLoc = parsedDir + "<product>-<version>.pt";
	logMessage("Now writing file: <binLoc>...", 2);
	if (!exists(parsedDir)) {
		mkDirectory(parsedDir);
	}
	writeBinaryValueFile(binLoc, files, compression=false);
	logMessage("... done.", 2);
}

@doc{Build the serialized ASTs for a specific system at the default location}
public void buildBinaries(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) {
	buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
}

@doc{Build the serialized ASTs for all versions of a specific product (e.g., WordPress)}
public void buildBinaries(str product, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) {
	for (version <- getVersions(product))
		buildBinaries(product, version, getCorpusItem(product, version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
}

@doc{Build the serialized ASTs for all product/version combos in the corpus}
public void buildBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) {
	for (product <- getProducts(), version <- getVersions(product))
		buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
}

@doc{Build the serialized ASTs for a specific system if they have not been built already}
public void buildMissingBinaries(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	loc l = getCorpusItem(product,version);
	loc binLoc = parsedDir + "<product>-<version>.pt";
	if (!exists(binLoc)) {
		buildBinaries(product, version, l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
	}
}

@doc{Build the serialized ASTs for all versions of a specific product (e.g., WordPress) where these serialized ASTs are missing}
public void buildMissingBinaries(str product, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (version <- getVersions(product))
		buildMissingBinaries(product, version, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Build the serialized ASTs for all product/version combos in the corpus where these serialized ASTs are missing }
public void buildMissingBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (product <- getProducts(), version <- getVersions(product))
		buildMissingBinaries(product, version, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Build the serialized ASTs only for the newest version of each system in the corpus.}
public void buildNewestBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false) {
	lv = getLatestVersions();
	for (product <- lv)
		buildBinaries(product, lv[product], getCorpusItem(product,version), addLocationAnnotations, addUniqueIds);
}

@doc{Load the serialized ASTs for a specific system in the corpus.}
public System loadBinary(str product, str version) {
	parsedItem = parsedDir + "<product>-<version>.pt";
	logMessage("Loading binary: <parsedItem>", 1);
	return readBinaryValueFile(#System,parsedItem);
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
	writeFile(|rascal://src/lang/php/extract/csvs/linesOfCode.csv|, intercalate("\n",scLines));
}

public map[tuple[str product, str version], map[loc l, Script scr]] getLatestTrees() {
	lv = getLatestVersions();
	return ( <p,lv[p]> : loadBinary(p,lv[p]) | p <- lv<0> );
}

@doc{ counter helper methods }
public int folderCounter = 0;
public int folderTotal = 0;
public void increaseFolderCounter() {
	folderCounter = folderCounter + 1;
}
public void resetCounters() {
	if (folderCounter == folderTotal) { 
		folderTotal = 0;
		folderCounter = 0;
	}
}
public void setFolderTotal(loc baseDir) {
	folderTotal = countFolders(baseDir);
}

public int countFolders(loc d) = (1 | it + countFolders(d+f) | str f <- listEntries(d), isDirectory(d+f));

@doc { 
	Log level 0 => no logging;
	Log level 1 => main logging;
	Log level 2 => debug logging;
}
public void logMessage(str message, int level) {
	if (level <= logLevel) {
		str date = printDate(now(), "Y-MM-dd HH:mm:ss");
		println("<date> :: <message>");
	}
}

public void checkConfiguration() {
	bool checkParse = true;
	
	println("Checking the configuration to ensure it is set correctly...");
	println("");
	println("parserLoc should be set to the directory containing the PHP-Parser project");
	
	if (!exists(parserLoc)) {
		println("Path <parserLoc> does not exist");
		checkParse = false;
	} else if (exists(parserLoc) && !isDirectory(parserLoc)) {
		println("Path <parserLoc> exists, but is not a directory");
		checkParse = false;
	} else {
		println("parserLoc appears to be fine");
	}
	
	println("astToRascal should be the location of file AST2Rascal inside PHP-Parser");
	
	if (!exists(parserLoc + astToRascal)) {
		println("Path <parserLoc+astToRascal> is not valid, file not found");
		checkParse = false;
	} else if (exists(parserLoc + astToRascal) && !(isFile(parserLoc + astToRascal))) {
		println("Path <parserLoc+astToRascal> is not a file");
		checkParse = false;
	} else {
		println("astToRascal appears to be fine");
	}
	
	println("phploc should contain the location of the php executable");

	if (!exists(phploc)) {
		println("Path <phploc> does not exist");
		checkParse = false;
	} else if (exists(phploc) && !isFile(phploc)) {
		println("Path <phploc> exists, but is not a file");
		checkParse = false;
	} else {
		println("phploc appears to be fine");
	}
	
	if (checkParse) {
		try {
			e = parsePHPExpression("1+2");
			if (binaryOperation(scalar(integer(1)),scalar(integer(2)),plus()) := e) {
				println("Test parse of 1+2 succeeded");
			} else {
				println("Test parse of 1+2 failed, got the following instead: <e>");
			}
		} catch re : {
			println("Test parse of 1+2 triggered the following exception: <re>");
		}
	}
}