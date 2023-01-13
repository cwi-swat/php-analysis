module lang::php::experiments::wasdett2013::WASDETT2013

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::php::stats::Stats;
import lang::php::analysis::includes::ResolveIncludes;

import vis::Figure;
import util::Math;

private real scaleFactor = 10.0;
private int bump = 1;

@doc{Calculate the size of the box we use to visualize the include count.}
private tuple[real length, real width] calculateBoxSize(int includeCount) {
	return < scaleFactor * nroot(includeCount+bump,2), scaleFactor * nroot(includeCount+bump,2) >;
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

@doc{Count the number of times each file in included in another file.}
private map[str file, int count] calculateIncludedCounts(System s) {
	map[str file, int count] res = ( l.path : 0 | l <- s.files );
	// NOTE: This disregards includes we cannot resolve
	allIncludes = { < ipath, l.path > | l <- s.files, /i:include(scalar(string(ipath)),_) := s.files[l],  ipath in res};
	for (< ipath, _ > <- allIncludes) res[ipath] += 1;
	return res;
}

@doc{Count the number of times each file in included in another file, directly or indirectly.}
private map[str file, int count] calculateIncludedCountsTrans(System s) {
	map[str file, int count] res = ( l.path : 0 | l <- s.files );
	// NOTE: This disregards includes we cannot resolve
	allIncludes = { < ipath, l.path > | l <- s.files, /i:include(scalar(string(ipath)),_) := s.files[l],  ipath in res};
	for (< ipath, _ > <- allIncludes+) res[ipath] += 1;
	return res;
}

@doc{Calculate the number of occurrences in a given file}
private map[str file, int count] calculateFeatureCounts(System s, lrel[loc fileloc, Expr e] occurrences) {
	map[str file, int count] res = ( l.path : 0 | l <- s.files );
	for (<l,_> <- occurrences,l.path in res) res[l.path] += 1;
	return res;
}

@doc{Create the label for the box.}
private FProperty createLabel(str filename) {
	return mouseOver(box(text("File: <filename>")));
}

private FProperty createLabel(str filename, int includeCount, int featureCount) {
	return mouseOver(box(text("File: <filename>\nIncluded in <includeCount> files\nIncludes <featureCount> occurrences")));
}

@doc{Create the box with the appropriate label, color, and size.}
private Figure createBox(str filename, int includeCount, int featureCount) {
	boxSize = calculateBoxSize(includeCount);
	boxLabel = createLabel(filename, includeCount, featureCount);
	boxColor = calculateBoxColor(featureCount);
	
	return box(size(boxSize.length,boxSize.width), fillColor(boxColor), boxLabel);
}

@doc{Create the box with the appropriate label, color, and size.}
private Figure createBox(str filename, int includeCount, int featureCount, int totalCount) {
	boxSize = calculateBoxSize(includeCount);
	boxLabel = createLabel(filename, includeCount, featureCount);
	boxColor = calculateBoxColor(featureCount, totalCount);
	
	return box(size(boxSize.length,boxSize.width), fillColor(boxColor), boxLabel);
}

@doc{Create the visualization for a specific feature using fixed color ranges and direct includes.}
public Figure createFeatureViz(System r, lrel[loc fileloc, Expr e] featureOccurrences) {
	icounts = calculateIncludedCounts(r);
	fcounts = calculateFeatureCounts(r, featureOccurrences);
	boxes = [ createBox(ri.path, icounts[ri.path], fcounts[ri.path]) | ri <- r.files ];
	return hvcat(boxes, gap(5));
}

@doc{Create the visualization for a specific feature using fixed color ranges and transitive includes.}
public Figure createFeatureVizTrans(System r, lrel[loc fileloc, Expr e] featureOccurrences) {
	icounts = calculateIncludedCountsTrans(r);
	fcounts = calculateFeatureCounts(r, featureOccurrences);
	boxes = [ createBox(ri.path, icounts[ri.path], fcounts[ri.path]) | ri <- r.files ];
	return hvcat(boxes, gap(5));
}

@doc{Create the visualization for a specific feature using relative color ranges and direct includes.}
public Figure createFeatureVizRelColors(System r, lrel[loc fileloc, Expr e] featureOccurrences) {
	icounts = calculateIncludedCounts(r);
	fcounts = calculateFeatureCounts(r, featureOccurrences);
	maxCount = 0;
	for (l <- fcounts, fcounts[l] > maxCount) maxCount = fcounts[l];
	boxes = [ createBox(ri.path, icounts[ri.path], fcounts[ri.path], maxCount) | ri <- r.files ];
	return hvcat(boxes, gap(5));
}

@doc{Create the visualization for a specific feature using relative color ranges and transitive includes.}
public Figure createFeatureVizTransRelColors(System r, lrel[loc fileloc, Expr e] featureOccurrences) {
	icounts = calculateIncludedCountsTrans(r);
	fcounts = calculateFeatureCounts(r, featureOccurrences);
	maxCount = 0;
	for (l <- fcounts, fcounts[l] > maxCount) maxCount = fcounts[l];
	boxes = [ createBox(ri.path, icounts[ri.path], fcounts[ri.path], maxCount) | ri <- r.files ];
	return hvcat(boxes, gap(5));
}

@doc{Create the visualization specifically for uses of variable features.}
public Figure allVarFeatures(System r, bool relativize = true) {
	vvFeatures = gatherVarVarUses(r) + gatherVVCalls(r) +
				 gatherMethodVVCalls(r) + gatherVVNews(r) +
				 gatherPropertyFetchesWithVarNames(r) +
				 gatherVVClassConsts(r) + gatherStaticVVCalls(r) +
				 gatherStaticVVTargets(r) + gatherStaticPropertyVVNames(r) +
				 gatherStaticPropertyVVTargets(r);
	if (relativize)
		return createFeatureVizTransRelColors(r, vvFeatures);
	else
		return createFeatureVizTrans(r, vvFeatures);
}

public void stuffToDo() {
	wp1 = loadPHPFile(|file:///Users/mhills/Projects/phpsa/corpus/WordPress/wordpress-3.4/wp-mail.php|,false,false);
	wp2 = loadPHPFile(|file:///Users/mhills/Projects/phpsa/corpus/WordPress/wordpress-3.4/wp-mail.php|,true,false);
	wp3 = loadPHPFile(|file:///Users/mhills/Projects/phpsa/corpus/WordPress/wordpress-3.4/wp-mail.php|,false,true);
	wp4 = loadPHPFile(|file:///Users/mhills/Projects/phpsa/corpus/WordPress/wordpress-3.4/wp-mail.php|,true,true);
	parsePHPExpression("1+2");
	allCalls = [ c | /c:call(_,_) := wordpressResolved ];
}