@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::Utils

import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::php::ast::AbstractSyntax;
import lang::php::config::Config;

import IO;
import ValueIO;
// import util::ValueUI;
import String;
import Set;
import List;
import Exception;
import DateTime;
import util::ShellExec;
// import util::Resources;
import Map;

import lang::php::pp::PrettyPrinter;


//@javaClass{org.rascal.phpanalysis.PhpJarExtractor}
//@memo
//private java loc getPhpParserLocFromJar() throws IO(str msg);


public str executePHP(list[str] opts, loc cwd) {
	str phpBinLoc = usePhpParserJar ? "php" : phpLoc.path;
	// logMessage(phpBinLoc,2);
	// logMessage("<opts>", 2);
	// logMessage("<cwd>", 2);
  	PID pid = createProcess(phpBinLoc, args=opts, workingDir=cwd);
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	// logMessage(phcOutput,2);
	// logMessage(phcErr,2);
	killProcess(pid);

	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) {
		return phcOutput;
	}
	
	throw IO("error calling php");
}

private Script parsePHPfile(loc f, list[str] opts, Script error) {
	//loc parserLoc = usePhpParserJar ? getPhpParserLocFromJar() : lang::php::config::Config::parserLoc;
	loc parserLoc = lang::php::config::Config::parserLoc;
	str phpOut = "";
	try {
		str filePath = f.path;
		if (f.authority != "") {
			filePath = f.authority + "/" + filePath;
		}
		phpOut = executePHP(["-d memory_limit=<parserMemLimit>", "-d short_open_tag=On", "-d error_reporting=\"E_ALL & ~E_DEPRECATED & ~E_STRICT\"", (parserLoc + astToRascal).path, "-f<filePath>"] + opts, parserWorkingDir);
	} catch _: {
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
	catch _:
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
	if (l.scheme notin {"file","home","project"}) return errscript("Only file, home, and project locations are supported");
	if (!isFile(l)) return errscript("Location <l> must be a file");

	logMessage("Loading file <l>", 2);
	
	list[str] opts = [ ];
	if (addLocationAnnotations) opts += "-l";
	if (includeLocationInfo) opts += "--addDecl";
	if (addUniqueIds) opts += "-i";
	if (l.scheme == "home") opts += "-r";
	// NOTE: For Eclipse project locations, remove for now since we generally
	// use this on files that are not in an Eclipse project.
	// if (l.scheme == "project") {
	// 	opts += "-n<l.authority>";
	// 	opts += "-d<location(|project://<l.authority>|).path>";
	// }
	if (includePhpDocs) opts += "--phpdocs";
	
	Script res = parsePHPfile(l, opts, errscript("Could not parse file <l.path>")); 
	if (errscript(err) := res) logMessage("Found error in file <l.path>. Error: <err>", 2);
	return res;
}

@doc{Load all PHP files at a given directory location, with options for which extensions are PHP files, location annotations, and unique node ids.}
public System loadPHPFiles(loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }) throws AssertionFailed {

	if ((l.scheme == "file" || l.scheme == "home") && !exists(l)) throw AssertionFailed("Location <l> does not exist");
	if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");

	// regex filter exlucdes test/	
	list[loc] entries = [ l + e | e <- listEntries(l)];
	list[loc] dirEntries = [ e | e <- entries, isDirectory(e)];
	list[loc] phpEntries = [ e | e <- entries, e.extension in extensions, isFile(e)];

	System phpNodes = createEmptySystem();
	
	increaseFolderCounter();
	if (folderTotal == 0) setFolderTotal(l);
	
	if (size(phpEntries) > 0) {	
		logMessage("<((folderCounter * 100) / folderTotal)>% [<folderCounter>/<folderTotal>] Parsing <size(phpEntries)> files in directory: <l>", 2);
		for (e <- phpEntries) {
			try {
				Script scr = loadPHPFile(e, addLocationAnnotations, addUniqueIds);
				phpNodes.files[e] = scr;
			} catch IO(msg) : {
				println("<msg>");
			} catch Java(cls, msg) : {
				println("<cls>:<msg>");
			}
		}
	}
	
	for (d <- dirEntries) {
		newNodes = loadPHPFiles(d, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
		phpNodes.files = phpNodes.files + newNodes.files;
	}
	
	resetCounters();
		
	return phpNodes;
}

@doc{Load a specific system from the corpus}
public System loadProduct(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	loc l = getCorpusItem(product,version);
	return loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Build the serialized ASTs for a specific system at a specific location}
public void buildBinaries(str product, str version, loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	loc binLoc = parsedDir + "<product>-<version>.pt";
	if (overwrite || (!overwrite && !exists(binLoc))) {
		logMessage("Parsing <product>-<version>. \>\> Location: <l>.", 1);
		System files = loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
		files = namedVersionedSystem(product, version, l, files.files);
		logMessage("Now writing file: <binLoc>...", 2);
		if (!exists(parsedDir)) {
			mkDirectory(parsedDir);
		}
		writeBinaryValueFile(binLoc, files, compression=false);
		logMessage("... done.", 2);
	} else {
		logMessage("Parsed representation for <product>-<version> already exists, skipping...", 1);
	}
}

@doc{Build the serialized ASTs for a specific system at a specific location}
public void buildAndCheckBinaries(str product, str version, loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	loc binLoc = parsedDir + "<product>-<version>.pt";
	if (overwrite || (!overwrite && !exists(binLoc))) {
		logMessage("Parsing <product>-<version>. \>\> Location: <l>.", 1);
		System files = loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions);
		files = namedVersionedSystem(product, version, l, files.files);
		logMessage("Now writing file: <binLoc>...", 2);
		if (!exists(parsedDir)) {
			mkDirectory(parsedDir);
		}
		writeBinaryValueFile(binLoc, files, compression=false);
		logMessage("... done.", 2);
		logMessage("Checking individual files", 2);
		for (li <- files.files) {
			logMessage("Writing file: <li> to /tmp/test.bin",2);
			writeBinaryValueFile(|file:///tmp/test.bin|, files.files[li], compression=false);
			logMessage("Attempting to read back in file: <li> from /tmp/test.bin",2);
			readBinaryValueFile(#Script, |file:///tmp/test.bin|);
			logMessage("Read complete",2);
		}
		logMessage("Checking entire system",2);
		readBinaryValueFile(#System, binLoc);
		logMessage("Check complete",2);
	} else {
		logMessage("Parsed representation for <product>-<version> already exists, skipping...", 1);
	}
}

@doc{Build the serialized ASTs for a specific system at the default location}
public void buildBinaries(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions, overwrite=overwrite);
}

@doc{Build the serialized ASTs for all versions of a specific product (e.g., WordPress)}
public void buildBinaries(str product, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	for (version <- getVersions(product)) {
		buildBinaries(product, version, getCorpusItem(product, version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions, overwrite=overwrite);
	}
}

@doc{Build the serialized ASTs for all product/version combos in the corpus}
public void buildBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	for (product <- getProducts(), version <- getVersions(product)) {
		buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions, overwrite=overwrite);
	}
}

@doc{Build the serialized ASTs for the current version specific system at a specific location}
public void buildCurrent(str product, loc l, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	str version = "current";
	buildBinaries(product, version, l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions, overwrite=overwrite);
}

@doc{Build the serialized ASTs for all product/version combos in the corpus}
public void buildCurrent(loc systemLoc, bool addLocationAnnotations = true, bool addUniqueIds = false, set[str] extensions = { "php", "inc" }, bool overwrite = true) {
	buildCurrent(systemLoc.file, systemLoc, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds, extensions=extensions, overwrite=overwrite);
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
		buildBinaries(product, lv[product], getCorpusItem(product,lv[product]), addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Load the serialized ASTs for a specific system in the corpus.}
public System loadBinary(str product, str version) = loadBinary("<product>-<version>");

@doc{Load the serialized ASTs for the named system in the corpus.}
public System loadBinary(str name) {
	parsedItem = parsedDir + "<name>.pt";
	logMessage("Loading binary: <parsedItem>", 1);
	return readBinaryValueFile(#System,parsedItem);
}

public bool binaryExists(str product, str version) = exists(parsedDir + "<product>-<version>.pt");

public map[tuple[str product, str version], System] getLatestTrees() {
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
		//str date = printDate(now(), "Y-MM-dd HH:mm:ss");
		//println("<date> :: <message>");
		println("<now()> :: <message>");
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
	
	println("phpLoc should contain the location of the php executable");

	if (!exists(phpLoc)) {
		println("Path <phpLoc> does not exist");
		checkParse = false;
	} else if (exists(phpLoc) && !isFile(phpLoc)) {
		println("Path <phpLoc> exists, but is not a file");
		checkParse = false;
	} else {
		println("phpLoc appears to be fine");
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

public void convertCorpusItemToNamedSystem(str product, str version) {
	parsedItem = parsedDir + "<product>-<version>.pt";
	logMessage("Converting binary: <parsedItem>", 1);
	if (exists(parsedItem)) {
		try {
			ptAsValue = readBinaryValueFile(#value, parsedItem);
			if (map[loc fileloc, Script scr] pt := ptAsValue) {
				corpusItemLoc = getCorpusItem(product,version);
				System sys = namedVersionedSystem(product, version, corpusItemLoc, pt);
				writeBinaryValueFile(parsedItem, sys, compression=false);
			}
		} catch v : {
			logMessage("Could not convert system: <v>", 1);
		}
	}
}

public void convertCorpusToNamedSystems() {
	for (product <- getProducts(), version <- getVersions(product)) {
		convertCorpusItemToNamedSystem(product, version);
	}
}

public rel[str systemName, str systemVersion, loc fileLoc] unparsedFiles() {
	rel[str systemName, str systemVersion, loc fileLoc] res = { };
	
	for (systemName <- getProducts(), systemVersion <- getVersions(systemName)) {
		pt = loadBinary(systemName, systemVersion);
		for (l <- pt.files, pt.files[l] is errscript) {
			res = res + < systemName, systemVersion, l >;		
		}
	}
	
	return res;
}

public void reparseLocations(str systemName, str systemVersion, set[loc] locs) {
	pt = loadBinary(systemName, systemVersion);

	for (l <- locs) {
		logMessage("Reparsing file at location <l>",2);
		Script reparsedScript = loadPHPFile(l);
		pt.files[l] = reparsedScript;
	}

	loc binLoc = parsedDir + "<systemName>-<systemVersion>.pt";
	logMessage("Writing binary for <systemName>, version <systemVersion>",2);
	writeBinaryValueFile(binLoc, pt, compression=false);
}

public void removeNonFileLocs(str systemName, str systemVersion) {
	pt = loadBinary(systemName, systemVersion);
	nonFileLocs = { l | l <- pt.files, !isFile(l) };
	if (!isEmpty(nonFileLocs)) {
		logMessage("Found <size(nonFileLocs)> non-file locations, removing from system", 2);
		pt.files = domainX(pt.files, nonFileLocs);

		loc binLoc = parsedDir + "<systemName>-<systemVersion>.pt";
		logMessage("Writing binary for <systemName>, version <systemVersion>",2);
		writeBinaryValueFile(binLoc, pt, compression=false);
	}
}

public void patchBinaries() {
	for (systemName <- getProducts(), systemVersion <- getVersions(systemName)) {
		patchBinaries(systemName, systemVersion);
	}
}

public void patchBinaries(str systemName) {
	for (systemVersion <- getVersions(systemName)) {
		patchBinaries(systemName, systemVersion);
	}
}

public void patchBinaries(str systemName, str systemVersion) {
	pt = loadBinary(systemName, systemVersion);
	
	// Find any locations of files that did not parse correctly
	errorLocs = { l | l <- pt.files, pt.files[l] is errscript };
	
	if (size(errorLocs) == 0) {
		logMessage("No errored locations found for <systemName>, version <systemVersion>", 2);
		return;
	}
	
	fixedLocs = { };
	
	for (l <- errorLocs) {
		s = loadPHPFile(l);
		if (s is errscript) {
			logMessage("Unable to fix script at location <l> for <systemName>, version <systemVersion>", 2);
		} else {
			fixedLocs += l;
			pt.files[l] = s;
			logMessage("Fixed script at location <l> for <systemName>, version <systemVersion>", 2);
		}
	}

	if (size(fixedLocs) > 0) {
		loc binLoc = parsedDir + "<systemName>-<systemVersion>.pt";
		writeBinaryValueFile(binLoc, pt, compression=false);		
	}
}

private str testString = "test";