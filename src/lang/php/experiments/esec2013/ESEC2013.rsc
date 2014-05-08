module lang::php::experiments::esec2013::ESEC2013

import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::php::stats::Stats;
import lang::php::analysis::includes::ResolveIncludes;
import IO;
import Set;
import ValueIO;

@doc{The base corpus used in the paper, matching that used for ISSTA}
private Corpus esec13BaseCorpus = (
	"osCommerce":"2.3.1",
	"ZendFramework":"1.11.12",
	"CodeIgniter":"2.1.2",
	"Symfony":"2.0.12",
	"SilverStripe":"2.4.7",
	"WordPress":"3.4",
	"Joomla":"2.5.4",
	"phpBB":"3",
	"Drupal":"7.14",
	"MediaWiki":"1.19.1",
	"Gallery":"3.0.4",
	"SquirrelMail":"1.4.22",
	"Moodle":"2.3",
	"Smarty":"3.1.11",
	"Kohana":"3.2",
	"phpMyAdmin":"3.5.0-english",
	"PEAR":"1.9.4",
	"CakePHP":"2.2.0-0",
	"DoctrineORM":"2.2.2");

@doc{The location of the corpus extension, change to your location!}
private loc includesSystemsLoc = |file:///Users/mhills/Projects/phpsa/includes/systems|;

@doc{Retrieve the base corpus}
public Corpus getBaseCorpus() = esec13BaseCorpus;

@doc{Retrieve information on the extension; in this case we do not have
     version information, so we just go from name to location}
alias SysMap = map[str sysname, loc sysloc];
public SysMap getIncludesSystems() = getIncludesSystems(includesSystemsLoc);
public SysMap getIncludesSystems(loc base) = (l.file : l | l <- base.ls, isDirectory(l));

@doc{Get the extension as a name/version corpus, with version always "HEAD"
     since this was the head version of whatever was in the github repo}
public Corpus getIncludesSystemsCorpus() = getIncludesSystemsCorpus(getIncludesSystems());
public Corpus getIncludesSystemsCorpus(SysMap smap) = ( s : "HEAD" | s <- smap );

@doc{Build binaries of parsed systems for the extension}
public void buildESECBinaries(SysMap smap) {
	for (p <- smap) {
		buildBinaries(p,"HEAD",smap[p]);
	}
}

@doc{Load a binary for an extension system}
public System loadESECBinary(str sys) {
	return loadBinary(sys, "HEAD");
}

@doc{Build binaries, with resolved includes, for the extension}
public void buildESECBinariesWithIncludes(SysMap smap) {
	for (s <- smap) {
		pt = loadESECBinary(s);
		pt2 = resolveIncludes(pt,smap[s]);
		parsedItem = parsedDir + "<s>-HEAD-icp.pt";
		println("Writing binary: <parsedItem>");
		writeBinaryValueFile(parsedItem, pt2);
	}	
}

@doc{Load a binary, with resolved includes, for the extension system}
public map[loc,Script] loadESECBinaryWithIncludes(str product) {
	parsedItem = parsedDir + "<product>-HEAD-icp.pt";
	println("Loading binary: <parsedItem>");
	return readBinaryValueFile(#map[loc,Script],parsedItem);
}

@doc{Get back all the dynamic includes in the extension, organized by system}
public map[str sysname, lrel[loc fileloc, Expr call] dincs] fetchAllDynamicIncludes(SysMap smap) {
	map[str sysname, lrel[loc fileloc, Expr call] dincs] res = ( );
	for (sys <- smap) {
		pt = loadESECBinary(sys);
		incs = gatherIncludesWithVarPaths(pt);
		res[sys] = incs;
	}
	return res;
}

//public void buildExperimentalESECBinariesWithIncludes(SysMap smap) {
//	for (s <- smap) {
//		pt = loadESECBinary(s);
//		pt2 = resolveIncludesWithVars(pt,smap[s]);
//		parsedItem = parsedDir + "<s>-HEAD-icpe.pt";
//		println("Writing binary: <parsedItem>");
//		writeBinaryValueFile(parsedItem, pt2);
//	}	
//}

@doc{Get back all dynamic includes in the extension that remain after the
     includes resolution algorithm completes}
public map[str sysname, lrel[loc fileloc, Expr call] dincs] fetchAllUnresolvedDynamicIncludes(SysMap smap) {
	map[str sysname, lrel[loc fileloc, Expr call] dincs] res = ( );
	for (sys <- smap) {
		pt = loadESECBinaryWithIncludes(sys);
		incs = gatherIncludesWithVarPaths(pt);
		res[sys] = incs;
	}
	return res;
}
