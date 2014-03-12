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
import lang::php::util::System;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;

import IO;
import ValueIO;
import String;
import Set;
import List;
import Exception;
import DateTime;
import util::ShellExec;

@doc{Parse an individual PHP statement using the external parser, returning the associated AST.}
public Stmt parsePHPStatement(str s) {
	tempFile = |file:///tmp/parseStmt.php|;
	writeFile(tempFile, "\<?php\n<s>?\>");
	PID pid = createProcess(phploc.path, ["-d memory_limit=512M", rgenLoc.path, "-f<tempFile.path>"], rgenCwd);
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	Script res = errscript("Could not parse <s>");
	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) {
		if (trim(phcOutput) == "")
			throw "Parser failed in unknown way";
		else
			res = readTextValueString(#Script, phcOutput);
	}
	if (errscript(_) := res) throw "Found error in PHP code to parse";
	killProcess(pid);
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
	return loadPHPFile(l, true, false, true);
}

@doc{Load a single PHP file, with options for location annotations and unique node ids.}
public Script loadPHPFile(loc l, bool addLocationAnnotations, bool addUniqueIds) throws AssertionFailed {
	if (!exists(l)) return errscript("Location <l> does not exist");
	if (l.scheme notin {"file","home"}) return errscript("Only file and home locations are supported");
	if (!isFile(l)) return errscript("Location <l> must be a file");

	list[str] opts = [ ];
	if (addLocationAnnotations) opts += "-l";
	if (addUniqueIds) opts += "-i";
	if (l.scheme == "home") opts += "-r";
	
	PID pid = createProcess(phploc.path, ["-d memory_limit=512M", rgenLoc.path, "-f<l.path>"] + opts, rgenCwd);
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

@doc{Load all PHP files at a given directory location, with options for location annotations and unique node ids.}
public System loadPHPFiles(loc l, bool addLocationAnnotations = true, bool addUniqueIds = false) throws AssertionFailed {
	return loadPHPFiles(l, {"php", "inc"}, loadPHPFile, addLocationAnnotations, addUniqueIds);
}

@doc{Load all PHP files at a given directory location, with options for which extensions are PHP files, location annotations and unique node ids.}
public System loadPHPFiles(loc l, set[str] extensions, bool addLocationAnnotations = true, bool addUniqueIds = false) throws AssertionFailed {
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
	
	list[loc] entries = [ l + e | e <- listEntries(l) ];
	list[loc] dirEntries = [ e | e <- entries, isDirectory(e) ];
	list[loc] phpEntries = [ e | e <- entries, e.extension in extensions ];

	System phpNodes = ( );
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
	for (d <- dirEntries) phpNodes = phpNodes + loadPHPFiles(d, extensions, loader, addLocationAnnotations, addUniqueIds);
	
	return phpNodes;
}

@doc{Load a specific system from the corpus}
public System loadProduct(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	loc l = getCorpusItem(product,version);
	return loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
}

@doc{Build the serialized ASTs for a specific system at a specific location}
public void buildBinaries(str product, str version, loc l, bool addLocationAnnotations, bool addUniqueIds) {
	println("Parsing <product>-<version>");
	files = loadPHPFiles(l, addLocationAnnotations=addLocationAnnotations, addUniqueIds=addUniqueIds);
	loc binLoc = parsedDir + "<product>-<version>.pt";
	writeBinaryValueFile(binLoc, files);
}

@doc{Build the serialized ASTs for a specific system at the default location}
public void buildBinaries(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations, addUniqueIds);
}

@doc{Build the serialized ASTs for a specific system if they have not been built already}
public void buildMissingBinaries(str product, str version, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	loc l = getCorpusItem(product,version);
	loc binLoc = parsedDir + "<product>-<version>.pt";
	if (!exists(binLoc)) {
		buildBinaries(product, version, l, addLocationAnnotations, addUniqueIds);
	}
}

@doc{Build the serialized ASTs for all versions of a specific product (e.g., WordPress)}
public void buildBinaries(str product, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (version <- getVersions(product))
		buildBinaries(product, version, getCorpusItem(product, version), addLocationAnnotations, addUniqueIds);
}

@doc{Build the serialized ASTs for all versions of a specific product (e.g., WordPress) where these serialized ASTs are missing}
public void buildMissingBinaries(str product, bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (version <- getVersions(product))
		buildMissingBinaries(product, version, getCorpusItem(product, version), addLocationAnnotations, addUniqueIds);
}

@doc{Build the serialized ASTs for all product/version combos in the corpus}
public void buildBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (product <- getProducts(), version <- getVersions(product))
		buildBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations, addUniqueIds);
}

@doc{Build the serialized ASTs for all product/version combos in the corpus where these serialized ASTs are missing }
public void buildMissingBinaries(bool addLocationAnnotations = true, bool addUniqueIds = false) {
	for (product <- getProducts(), version <- getVersions(product))
		buildMissingBinaries(product, version, getCorpusItem(product,version), addLocationAnnotations, addUniqueIds);
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
	println("Loading binary: <parsedItem>");
	return readBinaryValueFile(#System,parsedItem);
}
