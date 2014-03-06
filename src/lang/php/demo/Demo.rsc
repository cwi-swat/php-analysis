@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::demo::Demo

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::util::System;
import lang::php::stats::Stats;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::includes::QuickResolve;
import lang::php::analysis::includes::IncludesInfo;

import util::ValueUI;
import util::Editors;
import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Math;
import List;
import Set;
import String;

private real scaleFactor = 3.0;
private int bump = 1;

@doc{Calculate the size of the box we use to visualize the feature count.}
private tuple[real length, real width] calculateBoxSize(int sizer) {
	return < scaleFactor * nroot(sizer+bump,2), scaleFactor * nroot(sizer+bump,2) >;
}

@doc{Calculate the color of the box we use to visualize the feature count.}
private Color calculateBoxColor(int featureCount) {
	if (featureCount == 0) return color("green");
	if (featureCount < 2) return color("yellow");
	if (featureCount < 10) return color("orange");
	return color("red");
}

@doc{Calculate the color of the box we use to visualize the feature count. This is a relative coloring, based on the total number of features found.}
private Color calculateBoxColor(int featureCount, int totalCount) {
	if (totalCount > 0)
		return colorSteps(color("green"),color("red"),totalCount+1)[featureCount];
	else
		return color("green");
}

@doc{Calculate the number of occurrences in a given file}
private map[str file, int count] calculateFeatureCounts(System s, lrel[loc fileloc, Expr e] occurrences) {
	map[str file, int count] res = ( l.path : 0 | l <- s );
	for (<l,_> <- occurrences,l.path in res) res[l.path] += 1;
	return res;
}

@doc{Create a launch link.}
private FProperty createClicker(loc path) {
	return onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { loc l = path; edit(l,[]); return true;});
}

@doc{Create the label for the box.}
private FProperty createLabel(str filename, int featureCount) =
	mouseOver(box(text("  <filename> (<featureCount> uses of variable features)  ")));

@doc{Create the box with the appropriate label, color, and size.}
private Figure createBox(loc fileLoc, str filename, int fileSize, int featureCount, int totalCount) {
	boxSize = calculateBoxSize(fileSize);
	boxLabel = createLabel(filename, featureCount);
	boxColor = calculateBoxColor(featureCount); //, totalCount);
	//boxClick = createClicker(fileLoc);
	
	return box(size(boxSize.length,boxSize.width), fillColor(boxColor), boxLabel);
}

public map[str file, int count] calculateFileSizes(System sys) =
	( l.path : size({ s@at | /Stmt s := sys[l]}) | l <- sys );

@doc{Create the visualization for a specific feature using relative color ranges and direct includes.}
public Figure createFeatureViz(System sys, loc baseLoc, lrel[loc fileloc, Expr e] featureOccurrences) {
	fcounts = calculateFeatureCounts(sys, featureOccurrences);
	fsizes = calculateFileSizes(sys);
	totalCount = size(featureOccurrences);
	
	maxCount = 0;
	loclist = reverse(sort(toList(sys<0>), bool(loc l1, loc l2) { return fcounts[l1.path] < fcounts[l2.path]; })); 
	for (l <- fcounts, fcounts[l] > maxCount) maxCount = fcounts[l];
	boxes = [ createBox(ri, ri.path[size(baseLoc.path)..], fsizes[ri.path], fcounts[ri.path], totalCount) | ri <- loclist ];
	return hvcat(boxes, gap(10));
}

@doc{Get back all variable features in the system.}
public lrel[loc fileloc, Expr vf] findAllVarFeatures(System r) =
	gatherVarVarUses(r) + gatherVVCalls(r) +
	gatherMethodVVCalls(r) + gatherVVNews(r) +
	gatherPropertyFetchesWithVarNames(r) +
	gatherVVClassConsts(r) + gatherStaticVVCalls(r) +
	gatherStaticVVTargets(r) + gatherStaticPropertyVVNames(r) +
	gatherStaticPropertyVVTargets(r);

public void stuffToDo() {
	// Basic: parse a simple PHP expression
	parsePHPExpression("1+2");
	parsePHPExpression("f(3,4)");

	// Parse a file in WordPress using the external parser
	wpload = |home:///PHPAnalysis/systems/WordPress/wordpress-3.8.1/wp-load.php|;
	wpfile = loadPHPFile(wpload, true, false);
	
	// Load the most recent version of WordPress
	wp = loadBinary("WordPress","3.8.1");
	
	// Simple query: find all function calls
	allCalls = { < c@at, c > | /c:call(_,_) := wp };
	
	// More complex: all function calls to mysql functions
	mysqlCalls = { < c@at, c > | /c:call(name(name(fn)),_) := wp, /mysql/ := fn };
	
	// Just execs
	mysqleCalls = { < c@at, c > | /c:call(name(name("mysql_query")),_) := wp };
	
	// Get back all variable features
	vf = findAllVarFeatures(wp);
	
	// Visualize distribution of these features, this shows total
	// program size as well
	baseLoc = getCorpusItem("WordPress","3.8.1");
	fig = createFeatureViz(wp, baseLoc, vf);
	render(fig);
	
	// Perform "quick includes" resolve on wp-load
	iinfo = loadIncludesInfo("WordPress","3.8.1");
	dynamicIncludes = { <i@at,i> | /i:include(iexp,_) := wp[wpload], scalar(string(_)) !:= iexp };
	resolved = quickResolve(wp, "WordPress", "3.8.1", wpload, baseLoc);
	 	
}
