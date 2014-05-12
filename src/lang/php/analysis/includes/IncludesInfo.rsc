module lang::php::analysis::includes::IncludesInfo

import lang::php::ast::AbstractSyntax;
import lang::php::util::System;
import lang::php::util::Config;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import lang::php::analysis::evaluators::MagicConstants;
import lang::php::analysis::includes::NormalizeConstCase;
import lang::php::analysis::evaluators::DefinedConstants;
import lang::php::util::Utils;

import Set;
import IO;
import ValueIO;

private loc infoLoc = baseLoc + "serialized/includeInfo";

public Expr normalizeExpr(Expr e, loc baseloc) {
	e = normalizeConstCase(inlineMagicConstants(e, baseloc));
	solve(e) {
		e = algebraicSimplification(simulateCalls(e));
	}
	return e;
}

public void buildIncludesInfo(str p, str v, loc baseloc) {
	if (exists(infoLoc + "<p>-<v>-l2c.bin")) return;
	sys = loadBinary(p,v);
	buildIncludesInfo(sys, p, v, baseloc);
}

public void buildIncludesInfo(System sys, str p, str v, loc baseloc) {
	if (!exists(infoLoc)) mkDirectory(infoLoc);
	if (exists(infoLoc + "<p>-<v>-l2c.bin")) return;
	
	map[loc,set[ConstItemExp]] loc2consts = ( l : { cdef[e=normalizeExpr(cdef.e, baseloc)]  | cdef <- getScriptConstDefs(sys[l]) } | l <- sys);
	rel[ConstItem,loc,Expr] constrel = { < (classConst(cln,cn,ce) := ci) ? classConst(cln,cn) : normalConst(ci.constName), l, ci.e > | l <- loc2consts, ci <- loc2consts[l] };

	map[str, Expr] constMap = ( cn : ce | ci:normalConst(cn) <- constrel<0>, csub := constrel[ci,_], size(csub) == 1, ce:scalar(sv) := getOneFrom(csub), encapsed(_) !:= sv );  
	if ("DIRECTORY_SEPARATOR" notin constMap)
		constMap["DIRECTORY_SEPARATOR"] = scalar(string("/"));
	if ("PATH_SEPARATOR" notin constMap)
		constMap["PATH_SEPARATOR"] = scalar(string(":"));

	map[str, map[str, Expr]] classConstMap = ( );
	for (ci:classConst(cln,cn) <- constrel<0>, csub := constrel[ci,_], size(csub) == 1, ce:scalar(sv) := getOneFrom(csub), encapsed(_) !:= sv) {
		if (cln in classConstMap) {
			classConstMap[cln][cn] = ce;
		} else {
			classConstMap[cln] = ( cn : ce );
		}
	}
	
	writeBinaryValueFile(infoLoc + "<p>-<v>-l2c.bin", loc2consts);
	writeBinaryValueFile(infoLoc + "<p>-<v>-crel.bin", constrel);
	writeBinaryValueFile(infoLoc + "<p>-<v>-cmap.bin", constMap);
	writeBinaryValueFile(infoLoc + "<p>-<v>-ccmap.bin", classConstMap);
}

data IncludesInfo 
	= includesInfo(map[loc,set[ConstItemExp]] loc2consts,
				   rel[ConstItem,loc,Expr] constRel,
				   map[str, Expr] constMap,
				   map[str, map[str, Expr]] classConstMap);
				   

public bool includesInfoExists(str p, str v) {
	return exists(infoLoc + "<p>-<v>-l2c.bin") && exists(infoLoc + "<p>-<v>-crel.bin") && exists(infoLoc + "<p>-<v>-cmap.bin") && exists(infoLoc + "<p>-<v>-ccmap.bin");
}
				  
public IncludesInfo loadIncludesInfo(str p, str v) {
	map[loc,set[ConstItemExp]] loc2consts = readBinaryValueFile(#map[loc,set[ConstItemExp]], infoLoc + "<p>-<v>-l2c.bin");
	rel[ConstItem,loc,Expr] constRel = readBinaryValueFile(#rel[ConstItem,loc,Expr], infoLoc + "<p>-<v>-crel.bin");
	map[str, Expr] constMap = readBinaryValueFile(#map[str, Expr], infoLoc + "<p>-<v>-cmap.bin");
	map[str, map[str, Expr]] classConstMap = readBinaryValueFile(#map[str, map[str, Expr]], infoLoc + "<p>-<v>-ccmap.bin");
	
	return includesInfo(loc2consts, constRel, constMap, classConstMap);
}