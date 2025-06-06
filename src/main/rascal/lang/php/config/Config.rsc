@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::config::Config

import lang::php::util::Option;

import IO;
import Exception;
import lang::yaml::Model;

public data Exception
	= configMissing(str key, str msg)
	;

public data Config 
	= config(
		Option[bool] usePhpParserJar,
		Option[loc] phpLoc,
		Option[loc] parserLoc,
		Option[loc] analysisLoc,
		Option[str] parserMemLimit,
		Option[str] astToRascal,
		Option[loc] parserWorkingDir,
		Option[loc] baseLoc, 
		Option[loc] parsedDir, 
		Option[loc] statsDir, 
		Option[loc] corpusRoot, 
		Option[loc] countsDir, 
		Option[bool] useBinaries,
		Option[int] logLevel, 
		Option[loc] clocLoc)
	| emptyConfig()
	;

private Config c = emptyConfig();

public Config getConfig() {
	if (c is emptyConfig) {
		c = loadConfig();
	}
	return c;
}

private Config loadConfig() {
	bool usePhpParserJar = false;
	loc phpLoc = |file:///opt/homebrew/bin/php|;
	loc parserLoc = |file:///Users/hillsma/Projects/php-analysis/PHP-Parser|;
	loc analysisLoc = |file:///Users/hillsma/Projects/php-analysis/php-analysis/|;
	str parserMemLimit = "1024M";
	str astToRascal = "AST2Rascal.php";
	loc parserWorkingDir = (parserLoc + astToRascal).parent;
	loc baseLoc = |home:///PHPAnalysis|;
	loc parsedDir = baseLoc + "serialized/parsed";
	loc statsDir = baseLoc + "serialized/stats";
	loc corpusRoot = baseLoc + "systems";
	loc countsDir = baseLoc + "serialized/counts";
	bool useBinaries = false;
	int logLevel = 2;
	loc clocLoc = |file:///opt/homebrew/bin/cloc|;

	Config c = config(
		some(usePhpParserJar),
		some(phpLoc),
		some(parserLoc),
		some(analysisLoc),
		some(parserMemLimit),
		some(astToRascal),
		some(parserWorkingDir),
		some(baseLoc), 
		some(parsedDir), 
		some(statsDir), 
		some(corpusRoot), 
		some(countsDir), 
		some(useBinaries),
		some(logLevel), 
		some(clocLoc)
	);

	return c;
}

@doc{Indicates whether to use the parser contained in a distributed jar file or from the directory given below}
public bool usePhpParserJar() {
	c = getConfig();
	return (c has usePhpParserJar && some(bool b) := c.usePhpParserJar) ? b : false;
}

@doc{The location of the PHP executable}
public loc phpLoc() {
	c = getConfig();
	if (c has phpLoc && some(loc l) := c.phpLoc) {
		return l;
	}
	throw configMissing("phpLoc", "Make sure to set phpLoc to a valid location in your configuration file");
}

@doc{The base install location for the PHP-Parser project}
public loc parserLoc() {
	c = getConfig();
	if (c has parserLoc && some(loc l) := c.parserLoc) {
		return l;
	}
	throw configMissing("parserLoc", "Make sure to set parserLoc to a valid location in your configuration file");
}

@doc{The base install location for the php-analysis project}
public loc analysisLoc() {
	c = getConfig();
	if (c has analysisLoc && some(loc l) := c.analysisLoc) {
		return l;
	}
	throw configMissing("analysisLoc", "Make sure to set analysisLoc to a valid location in your configuration file");
}
	
@doc{The memory limit for PHP when the parser is run}
public str parserMemLimit() {
	c = getConfig();
	return (c has parserMemLimit && some(str s) := c.parserMemLimit) ? s : "1024M";
}

@doc{The location of the AST2Rascal.php file, inside the PHP-Parser directories}
public str astToRascal() {
	c = getConfig();
	return (c has astToRascal && some(str s) := c.astToRascal) ? s : "AST2Rascal.php";
}

@doc{The working directory for when the parser runs}
public loc parserWorkingDir() {
	c = getConfig();
	if (c has parserWorkingDir && some(loc l) := c.parserWorkingDir) {
		return l;
	}
	throw configMissing("parserWorkingDir", "Make sure to set parserWorkingDir to a valid location in your configuration file");
}

@doc{The base location for the corpus and any serialized files}
public loc baseLoc() {
	c = getConfig();
	if (c has baseLoc && some(loc l) := c.baseLoc) {
		return l;
	}
	throw configMissing("baseLoc", "Make sure to set baseLoc to a valid location in your configuration file");
}

@doc{Where to put the binary representations of parsed systems}
public loc parsedDir() {
	c = getConfig();
	if (c has parsedDir && some(loc l) := c.parsedDir) {
		return l;
	}
	throw configMissing("parsedDir", "Make sure to set parsedDir to a valid location in your configuration file");
}

@doc{Where to put the binary representations of extracted statistics}
public loc statsDir() {
	c = getConfig();
	if (c has statsDir && some(loc l) := c.statsDir) {
		return l;
	}
	throw configMissing("statsDir", "Make sure to set statsDir to a valid location in your configuration file");
}

@doc{Where the PHP sources for the corpus reside}
public loc corpusRoot() {
	c = getConfig();
	if (c has corpusRoot && some(loc l) := c.corpusRoot) {
		return l;
	}
	throw configMissing("corpusRoot", "Make sure to set corpusRoot to a valid location in your configuration file");
}

@doc{Where to put extracted counts (e.g., SLOC)}
public loc countsDir() {
	c = getConfig();
	if (c has countsDir && some(loc l) := c.countsDir) {
		return l;
	}
	throw configMissing("countsDir", "Make sure to set countsDir to a valid location in your configuration file");
}

@doc{This should only ever be true if we don't have source, we only have the extracted binaries for parsed systems}
public bool useBinaries() {
	c = getConfig();
	return (c has useBinaries && some(bool b) := c.useBinaries) ? b : false;
}

@doc{Debugging options
	@logLevel {
		Log level 0 => no logging;
		Log level 1 => main logging;
		Log level 2 => debug logging;
	}
}
public int logLevel() {
	c = getConfig();
	return (c has logLevel && some(int n) := c.logLevel) ? n : 2;
}

@doc{The location of the cloc tool}
public loc clocLoc() {
	c = getConfig();
	if (c has clocLoc && some(loc l) := c.clocLoc) {
		return l;
	}
	throw configMissing("clocLoc", "Make sure to set clocLoc to a valid location in your configuration file");
}