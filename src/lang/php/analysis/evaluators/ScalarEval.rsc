@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::ScalarEval

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::evaluators::MagicConstants;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import lang::php::analysis::evaluators::DefinedConstants;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::analysis::signatures::Signatures;
import lang::php::util::System;
import Set;
import List;
import String;
import Exception;
import IO;

@doc{Perform all defined scalar evaluations.}
public System evalAllScalars(System scripts) {
	solve(scripts) {
		println("APPLYING SIMPLIFICATIONS");
		scripts = ( l : algebraicSimplification(simulateCalls(scripts[l])) | l <- scripts );
		println("APPLYING SIMPLIFICATIONS FINISHED");
	}			

	return scripts;
}

@doc{Perform all defined scalar evaluations and inline constants.}
public System evalAllScalarsAndInline(System scripts, loc baseLoc) {
	solve(scripts) {
		println("APPLYING SIMPLIFICATIONS");
		scripts = ( l : algebraicSimplification(simulateCalls(scripts[l])) | l <- scripts );
		println("APPLYING SIMPLIFICATIONS FINISHED");

		// Calculate the includes graph. We do this inside the solve since the information on
		// reachable includes could change as we further resolve information.
		println("REBUILDING INCLUDES GRAPH");
		igraph = extractIncludeGraph(scripts, baseLoc.path);
		//ig = collapseToNodeGraph(igraph);
		igTrans = (collapseToNodeGraph(igraph))*;
		println("REBUILDING INCLUDES GRAPH FINISHED");
		
		// Extract out the signatures. Again, we do this here because the information in the
		// signatures for constants could change (we could resolve a constant, defined in terms
		// of another constant, to a specific literal, for instance)
		println("EXTRACTING FILE SIGNATURES");
		sigs = getSystemSignatures(scripts);		
		println("EXTRACTING FILE SIGNATURES FINISHED");
		
		// Add in some predefined constants as well. These are from the Directories extension.
		// TODO: We should factor these out somehow.
		map[str, Expr] constMap = ( );
		constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
		constMap["PATH_SEPARATOR"] = scalar(string(":"));

		// Now, actually do the constant replacement for each script in the system.
		println("INLINING SCALAR REACHABLE CONSTANTS");
		scripts = ( l : evalConsts(scripts[l],constMap,igTrans[node4l],sigs) | l <- scripts, node4l := nodeForLoc(igraph, l) );
		println("INLINING SCALAR REACHABLE CONSTANTS FINISHED");
	}			

	return scripts;
}

@doc{Perform all defined scalar evaluations and inline constants.}
public System evalAllScalarsAndInlineUniques(System scripts, loc baseLoc) {
	solve(scripts) {
		println("APPLYING SIMPLIFICATIONS");
		scripts = ( l : algebraicSimplification(simulateCalls(scripts[l])) | l <- scripts );
		println("APPLYING SIMPLIFICATIONS FINISHED");

		// Calculate the includes graph. We do this inside the solve since the information on
		// reachable includes could change as we further resolve information.
		println("REBUILDING INCLUDES GRAPH");
		igraph = extractIncludeGraph(scripts, baseLoc.path);
		//ig = collapseToNodeGraph(igraph);
		igTrans = (collapseToNodeGraph(igraph))*;
		println("REBUILDING INCLUDES GRAPH FINISHED");
		
		// Extract out the signatures. Again, we do this here because the information in the
		// signatures for constants could change (we could resolve a constant, defined in terms
		// of another constant, to a specific literal, for instance)
		println("EXTRACTING SCRIPT CONSTANTS");
		sigs = getConstantSignatures(scripts);		
		println("EXTRACTING SCRIPT CONSTANTS FINISHED");

		// Get back information on the constants defined in the system, based on the signatures
		systemConstDefs = getSystemConstDefs(sigs);
		constDefLocs = getConstDefLocs(systemConstDefs);
		classConstDefLocs = getClassConstDefLocs(systemConstDefs);
		constDefExprs = getConstDefExprs(systemConstDefs);
		classConstDefExprs = getClassConstDefExprs(systemConstDefs);

		// Get back information on the constants used in the system: this directly queries the scripts
		systemConstUses = getSystemConstUses(scripts);
		constUseLocs = getConstUseLocs(systemConstUses);
		classConstUseLocs = getClassConstUseLocs(systemConstUses);
		
		// Fill in the constant map. These are all constants that have a system-wide
		// unique definition.
		map[str, Expr] constMap = ( );
		if ("DIRECTORY_SEPARATOR" notin systemConstDefs)
			constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
		if ("PATH_SEPARATOR" notin systemConstDefs)
			constMap["PATH_SEPARATOR"] = scalar(string(":"));
		constMap += ( cn : ce | cn <- constDefExprs, size(constDefExprs[cn]) == 1, ce:scalar(sv) := getOneFrom(constDefExprs[cn]), encapsed(_) !:= sv );  

		// Fill in the class constant map. These are all constants that have a system-wide
		// unique definition.
		map[str, map[str, Expr]] classConstMap = ( );
		for (cln <- classConstDefExprs) {
			constsForCln = classConstDefExprs[cln];
			mapForCn = ( cn : ce | cn <- constsForCln, size(constsForCln[cn]) == 1, ce:scalar(sv) := getOneFrom(constsForCln[cn]), encapsed(_) !:= sv );
			classConstMap[cln] = mapForCn; 
		} 
		
		// Now, actually do the constant replacement for each script in the system.
		println("INLINING SCALAR REACHABLE CONSTANTS PLUS UNIQUES");
		scripts = ( l : evalConsts(scripts[l],constMap,classConstMap,igTrans[node4l],sigs) | l <- scripts, node4l := nodeForLoc(igraph, l) );
		println("INLINING SCALAR REACHABLE CONSTANTS PLUS UNIQUES FINISHED");
	}		

	return scripts;
}
