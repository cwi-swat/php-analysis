@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::experiments::issta2013::ISSTA2013

import lang::php::util::Utils;
import lang::php::stats::Overall;
import lang::php::stats::Unfriendly;
import lang::rascal::types::AbstractType;
import lang::php::util::Corpus;

import IO;
import Type;
import List;
import Set;

import lang::csv::IO;
import Sizes = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|;

private Corpus issta13Corpus = (
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

public Corpus getISSTA2013Corpus() = issta13Corpus;

public str generateTable1() {
	return generateCorpusInfoTable(getISSTA2013Corpus());
}

public str generateFigure1() {
	return fileSizesHistogram(getLines());
}

public str generateTable2() {
	// NOTE: The computations performed by the following two
	// computations are quite expensive, so the results have
	// been serialized. To actually run the computations, just
	// uncomment the following two lines and comment out the
	// two below.
	//fmap = getFMap();
	//fl = calculateFeatureLattice(fmap);
	
	fmap = readFeatsMap();
	fl = loadFeatureLattice();

	fByPer = featuresForPercents(fmap,fl,[80,90,100]);
	labels = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];

	notIn80 = toSet(labels) - fByPer[80];
	notIn90 = toSet(labels) - fByPer[90];
	notIn100 = toSet(labels) - fByPer[100];
	
	return groupsTable(notIn80, notIn90, notIn100);
}

public str generateFigure2() {
	// The call to calculate this is shown above in the code to
	// generate table 2; this just loads the serialized data.
	fmap = readFeatsMap();
	
	return generalFeatureSquiglies(fmap);
}

public str generateFigure3() {
	// The feature lattice and feature map are both serialized;
	// see above for code that will calculate them from scratch.
	//fmap = getFMap();
	//fl = calculateFeatureLattice(fmap);
	fmap = readFeatsMap();
	fl = loadFeatureLattice();

	// The coverage map is also serialized, uncomment the following
	// and comment out the line after to recompute it.	
	//coverageMap = featuresForAllPercents(fmap, fl);
	coverageMap = loadCoverageMap();

	return coverageGraph(coverageMap);
}

public str generateTable3() {
	// The feature lattice and coverage map are both serialized;
	// see above for code that will calculate them from scratch.
	fl = loadFeatureLattice();
	coverageMap = loadCoverageMap();
	ncm = notCoveredBySystem(getISSTA2013Corpus(), fl, coverageMap);
	return coverageComparison(getISSTA2013Corpus(),ncm);
}

public str generateTable4() {
	// As above, the following is quite expensive, so the result
	// has been serialized. Just uncomment the following line, and
	// comment out the line below it, to run the analysis from scratch.
	//icl = includesAnalysis(getISSTA2013Corpus());
	
	icl = reload();
	icr = calculateIncludeCounts(icl);
	icounts = includeCounts(getISSTA2013Corpus());
	return generateIncludeCountsTable(icr, icounts);
}

public str generateTable5() {
	< vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets > = getAllVV(getISSTA2013Corpus());
	trans = calculateVVTransIncludes(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets, getISSTA2013Corpus());
	return showVVInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops,
		vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls +
		vvstargets + vvsprops + vvsptargets, trans, getISSTA2013Corpus());
}

public str generateTable6() {
	return vvUsagePatternsTable(getISSTA2013Corpus());
}

public str generateTable7() {
	mmr = magicMethodUses(getISSTA2013Corpus());
	trans = calculateMMTransIncludes(getISSTA2013Corpus(),mmr);
	return magicMethodCounts(getISSTA2013Corpus(), mmr, trans);
}

public str generateTable8() {
	evalUses = corpusEvalUses(getISSTA2013Corpus());
	transUses = calculateEvalTransIncludes(getISSTA2013Corpus(), evalUses);
	fuses = createFunctionUses(corpusFunctionUses(getISSTA2013Corpus()));
	ftransUses = calculateFunctionTransIncludes(getISSTA2013Corpus(), fuses);
	
	return evalCounts(getISSTA2013Corpus(), evalUses, fuses, transUses, ftransUses);
}

public str generateTable9() {
	allcalls = allCalls(getISSTA2013Corpus());
	vcalls = varargsCalls(getISSTA2013Corpus());
	vdefs = varargsFunctionsAndMethods(getISSTA2013Corpus());
	vcallsTrans = calculateFunctionTransIncludes(getISSTA2013Corpus, vcalls<0,1,2,3>);
	return showVarArgsUses(getISSTA2013Corpus(), vdefs, vcalls, allcalls, vcallsTrans);
}

public str generateTable10() {

}

// This generates all the tables and figures, but doesn't
// currently do anything with them. If you want to see them,
// the best way to do this is to run each of these lines in
// the console, then print the result, e.g.:
//		table1 = generateTable1();
//  	println(table1);
// or write it to a file, e.g.:
//      table1 = generateTable1();
//      writeFile(|file:///tmp/table1.txt|, table1);
public void main() {
	// Generate all the tables
	table1 = generateTable1();
	table2 = generateTable2();
	table3 = generateTable3();
	table4 = generateTable4();
	table5 = generateTable5();
	table6 = generateTable6();
	table7 = generateTable7();
	table8 = generateTable8();
	table9 = generateTable9();
	table10 = generateTable10();
	
	// Generate all the figures
	figure1 = generateFigure1();
	figure2 = generateFigure2();
	figure3 = generateFigure3();
}

