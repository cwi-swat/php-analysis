module lang::php::experiments::icse2013::ICSE2013

import lang::php::util::Utils;
import lang::php::stats::Overall;
import lang::php::stats::Unfriendly;

import IO;

import lang::csv::IO;
import Sizes = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|;

public str generateTable1() {
	return generateCorpusInfoTable();
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
	return groupsTable(fByPer[80],fByPer[90],fByPer[100]);
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
	ncm = notCoveredBySystem(fl, coverageMap);
	return coverageComparison(ncm);
}

public str generateTable4() {
	// As above, the following is quite expensive, so the result
	// has been serialized. Just uncomment the following line, and
	// comment out the line below it, to run the analysis from scratch.
	//icl = includesAnalysis();
	
	icl = reload();
	icr = calculateIncludeCounts(icl);
	return generateIncludeCountsTable(icr);
}

public str generateTable5() {
	< vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets > = getAllVV();
	trans = calculateVVTransIncludes(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets);
	return showVVInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops,
		vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls +
		vvstargets + vvsprops + vvsptargets, trans);
}

public str generateTable6() {
	return vvUsagePatternsTable();
}

public str generateTable7() {
	mmr = magicMethodUses();
	trans = calculateMMTransIncludes(mmr);
	return magicMethodCounts(mmr, trans);
}

// This generates all the tables and figures, but doesn't
// currently do anything with them. If you want to see them,
// the best way to do this is to run each of these lines in
// the console, then print the result, e.g.:
//		table1 = generateTable1();
//  	println(table1);
public void main() {
	// Generate all the tables
	table1 = generateTable1();
	table2 = generateTable2();
	table3 = generateTable3();
	table4 = generateTable4();
	table5 = generateTable5();
	table6 = generateTable6();
	table7 = generateTable7();
	
	// Generate all the figures
	figure1 = generateFigure1();
	figure2 = generateFigure2();
	figure3 = generateFigure3();
}

