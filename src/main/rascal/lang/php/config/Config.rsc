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
import Set;
import Exception;
import String;
import util::SystemAPI;
import lang::yaml::Model;
import lang::php::config::ConfigLoader;

public data Exception
	= configMissing(str key, str msg)
	;

@doc{Base configuration settings used by all parts of PHP AiR.}
public data ConfigBase
	= configBase(
		int logLevel = 0,
		loc phpLoc = |unknown:///|,
		loc clocLoc = |unknown:///|
	);

@doc{Config settings specifically related to parsing PHP code.}
public data ConfigParsing
	= configParsing(
		bool usePhpParserJar = false,
		loc parserLoc = |unknown:///|,
		str parserMemLimit = "1024M",
		str astToRascal = "AST2Rascal.php",
		loc parserWorkingDir = |unknown:///|
	);

@doc{Config settings specifically for the analysis framework.}
public data ConfigAnalysis
	= configAnalysis(
		loc baseLoc = |unknown:///|,
		loc analysisLoc = |unknown:///|,
		loc parsedDir = |unknown:///|,
		loc statsDir = |unknown:///|,
		loc countsDir = |unknown:///|,
		loc corpusRoot = |unknown:///|,
		bool useBinaries = false
	);

@doc{The overall configuration used by PHP AiR and child projects.}
public data Config 
	= config(
		ConfigBase base = configBase(), 
		ConfigParsing parsing = configParsing(), 
		ConfigAnalysis analysis = configAnalysis())
	| unloaded()
	;

@doc{A singleton to hold the loaded configuration.}
private Config c = unloaded();

@doc{Manage the singleton, loading the config if it hasn't been loaded yet.}
public Config getConfig() {
	if (c is unloaded) {
		c = loadConfig();
	}
	return c;
}

@doc{Force a reload of the configuration.}
public Config reloadConfig() {
	c = loadConfig();
	return c;
}

@doc{Load the YAML configuration file.}
private Config loadConfig() {

	set[loc] configFiles = findResources("config.yaml");
	if (size(configFiles) == 0) {
		throw configMissing("", "No config.yaml file found");
	} else if (size(configFiles) > 1) {
		throw configMissing("", "Found <size(configFiles)> config.yaml files, should only have 1");
	} else {
		configFile = getOneFrom(configFiles);
		if (!exists(configFile)) {
			throw configMissing("", "The file <configFile.path> does not exist");
		} else if (!isFile(configFile)) {
			throw configMissing("", "<configFile.path> is not a file");
		} else {
			try {
				yml = loadYAML(readFile(configFile));
				Config c = yaml2config(#Config, yml);
				return c;
			} catch Exception e: {
				throw configMissing("", "The config file did not load correctly: <e>");
			}			
		}
	}
}
