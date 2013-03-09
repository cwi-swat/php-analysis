module lang::php::experiments::esec2013::ESEC2013

import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::util::System;
import lang::php::stats::Stats;
import lang::php::analysis::includes::ResolveIncludes;
import IO;
import Set;
import ValueIO;

private loc testCorpus = |file:///export/scratch2/hills/includes/systems|;

alias SysMap = map[str sysname, loc sysloc];
public SysMap getIncludesSystems() = getIncludesSystems(testCorpus);
public SysMap getIncludesSystems(loc base) = (l.file : l | l <- base.ls, isDirectory(l));

public Corpus getIncludesSystemsCorpus() = getIncludesSystemsCorpus(getIncludesSystems());
public Corpus getIncludesSystemsCorpus(SysMap smap) = ( s : "HEAD" | s <- smap );

public void buildESECBinaries(SysMap smap) {
	for (p <- smap) {
		buildBinaries(p,"HEAD",smap[p]);
	}
}

public System loadESECBinary(str sys) {
	return loadBinary(sys, "HEAD");
}

public map[loc,Script] loadESECBinaryWithIncludes(str product) {
	parsedItem = parsedDir + "<product>-HEAD-icp.pt";
	println("Loading binary: <parsedItem>");
	return readBinaryValueFile(#map[loc,Script],parsedItem);
}

public map[str sysname, lrel[loc fileloc, Expr call] dincs] fetchAllDynamicIncludes(SysMap smap) {
	map[str sysname, lrel[loc fileloc, Expr call] dincs] res = ( );
	for (sys <- smap) {
		pt = loadESECBinary(sys);
		incs = gatherIncludesWithVarPaths(pt);
		res[sys] = incs;
	}
	return res;
}

public void buildESECBinariesWithIncludes(SysMap smap) {
	for (s <- smap) {
		pt = loadESECBinary(s);
		pt2 = resolveIncludes(pt,smap[s]);
		parsedItem = parsedDir + "<s>-HEAD-icp.pt";
		println("Writing binary: <parsedItem>");
		writeBinaryValueFile(parsedItem, pt2);
	}	
}

public void buildExperimentalESECBinariesWithIncludes(SysMap smap) {
	for (s <- smap) {
		pt = loadESECBinary(s);
		pt2 = resolveIncludesWithVars(pt,smap[s]);
		parsedItem = parsedDir + "<s>-HEAD-icpe.pt";
		println("Writing binary: <parsedItem>");
		writeBinaryValueFile(parsedItem, pt2);
	}	
}

public map[str sysname, lrel[loc fileloc, Expr call] dincs] fetchAllUnresolvedDynamicIncludes(SysMap smap) {
	map[str sysname, lrel[loc fileloc, Expr call] dincs] res = ( );
	for (sys <- smap) {
		pt = loadESECBinaryWithIncludes(sys);
		incs = gatherIncludesWithVarPaths(pt);
		res[sys] = incs;
	}
	return res;
}
