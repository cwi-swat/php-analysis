module lang::php::util::Utils

import util::ShellExec;
import IO;
import ValueIO;
import String;
import Set;
import Exception;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Config;

public Script loadPHPFile(loc l) {
	println("Loading PHP file <l>");
	loc rgenLoc = projroot + "PHP-Parser/lib/Rascal/AST2Rascal.php";
	PID pid = createProcess(phploc.path, [rgenLoc.path, "<l.path>"], projroot + "PHP-Parser/lib/Rascal");
	str phcOutput = readEntireStream(pid);
	str phcErr = readEntireErrStream(pid);
	Script res = script([exprstmt(scalar(string("Could not parse file: <phcErr>")))]);
	if (trim(phcErr) == "" || /Fatal error/ !:= phcErr) res = readTextValueString(#Script, phcOutput);
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

public rel[str product, str version, loc fileloc, Script scr] loadPlugin(str product, str version) {
	rel[str product, str version, loc fileloc, Script scr] corpusItems = { };

	loc l = getPlugin(product,version);
	files = loadPHPFiles(l);
	for (fl <- files<0>) corpusItems += < product, version, fl, files[fl] >;
	return corpusItems;
}