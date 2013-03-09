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
import lang::php::analysis::evaluators::MagicConstants;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import lang::php::analysis::evaluators::DefinedConstants;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::analysis::signatures::Signatures;
import Set;
import List;
import String;
import Exception;
import IO;

@doc{Perform all defined scalar evaluations.}
public map[loc fileloc, Script scr] evalAllScalars(map[loc fileloc, Script scr] scripts) {
	solve(scripts) {
		println("APPLYING SIMPLIFICATIONS");
		scripts = ( l : algebraicSimplification(simulateCalls(scripts[l])) | l <- scripts );
		println("APPLYING SIMPLIFICATIONS FINISHED");
	}			

	return scripts;
}

@doc{Perform all defined scalar evaluations and inline constants.}
public map[loc fileloc, Script scr] evalAllScalarsAndInline(map[loc fileloc, Script scr] scripts, loc baseLoc) {
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
public map[loc fileloc, Script scr] evalAllScalarsAndInlineUniques(map[loc fileloc, Script scr] scripts, loc baseLoc) {
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

		// Retrieve all defined constants and class constants		
		allConsts = getAllDefinedConstants(scripts);

		// Fill in the constant map. These are all constants that have a system-wide
		// unique definition.
		map[str, Expr] constMap = ( );
		constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
		constMap["PATH_SEPARATOR"] = scalar(string(":"));
		constsRel = { < cn, ce > | constSig([global(),const(cn)],ce) <- allConsts<0> }; 
		constMap += ( cn : ce | cn <- constsRel<0>, size(constsRel[cn]) == 1, ce:scalar(sv) := getOneFrom(constsRel[cn]), encapsed(_) !:= sv );

		// Fill in the class constant map. These are all constants that have a system-wide
		// unique definition.
		map[str, map[str, Expr]] classConstMap = ( );
		classConstsRel = { < cn, con, ce > | constSig([class(cn),const(con)],ce) <- allConsts<0> };
		for (cn <- classConstsRel<0>) {
			constsForCn = classConstsRel[cn];
			mapForCn = (con : ce | con <- constsForCn<0>, size(constsForCn[con]) == 1, ce:scalar(sv) := getOneFrom(constsForCn[con]), encapsed(_) != sv );
			classConstMap[cn] = mapForCn; 
		} 
		
		// Now, actually do the constant replacement for each script in the system.
		println("INLINING SCALAR REACHABLE CONSTANTS PLUS UNIQUES");
		scripts = ( l : evalConsts(scripts[l],constMap,classConstMap,igTrans[node4l],sigs) | l <- scripts, node4l := nodeForLoc(igraph, l) );
		println("INLINING SCALAR REACHABLE CONSTANTS PLUS UNIQUES FINISHED");
	}		

	return scripts;
}
