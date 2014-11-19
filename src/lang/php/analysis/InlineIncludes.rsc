@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::InlineIncludes

import lang::php::analysis::ConstantProp;
import lang::php::pp::PrettyPrinter;
import String;
import Set;
import Node;
import IO;
import List;
import ValueIO;

//
// Given the file sname, include prefixes, libraries, and a function that can get the node
// representatino of a file, replace all include and require calls in the body of the
// given script with the contents of the included file.
//
public node inlineIncludesForFile(str sname, list[str] prefixes, set[str] libs, node(str) getFile, bool(str) fileExists) {
	int idx = 1;
	map[str,node] inlined = ( );
	< inlined, idx > = inlineIncludes(sname, prefixes, libs, getFile, fileExists, inlined, idx);
	return inlined[sname]; 
}

//
// Internal version of the above. This also keeps track of already-inlined files and of an index used
// for alpha-renaming temp vars.
//
private tuple[map[str,node],int] inlineIncludes(str sname, list[str] prefixes, set[str] libs, node(str) getFile, bool(str) fileExists, map[str,node] inlined, int idx) {
	println("Inlining required and included scripts for file <sname>");
	return inlineIncludes(sname, prefixes, libs, getFile, fileExists, inlined, idx, { sname });
}

//
// Internal version of the above. In addition to the above function, this also tracks a set of included file names. This is used for something
// terribly useful that I cannot fully remember.
//
private tuple[map[str,node],int] inlineIncludes(str sname, list[str] prefixes, set[str] libs, node(str) getFile, bool(str) fileExists, map[str,node] inlined, int idx, set[str] included) {
	// If we have already inlined this, just return it
	if (sname in inlined) return < inlined, idx >;
	
	// Do a simple constant propagation to move strings back into include and require calls
	scr = propIncludesRequires(getFile(sname));
	
	// Get back the strings in these calls; this gives us the files to load
	set[str] includes = getLiteralIncludes(scr);
	
	// Remove any of these that are libraries (i.e., that we cannot load the files of)
	for (i <- (includes & libs)) println("Script <sname>: using library <i>");
	includes = includes - libs;
	
	// Resolve these includes to the names of the actual files we have available. We first add the
	// base directory of the current script into the prefixes, so we will use it first to try
	// to resolve the file names.
	base = reverse(sname); if (/[^\/]+[\/]<rest:.*>/ := base) base = trim(rest); else base = ""; prefixes = reverse(base) + prefixes;
	map[str,str] resolvedIncludes = ( i : j | i <- includes, j := resolveInclude(i, prefixes, fileExists), j != "");
	prefixes = tail(prefixes);
	
	// For each include, get the related (inlined version of) the script, then divide it up into top-level components
	// and code that is inserted at the include or require call site.
	list[node] toplevelStuff = [ ];
	map[str,list[node]] inclusionInserts = ( );
	for (i <- includes, i in resolvedIncludes, resolvedIncludes[i] notin included) {
		included = included + resolvedIncludes[i];
		< inlined, idx > = inlineIncludes(resolvedIncludes[i], prefixes, libs, getFile, fileExists, inlined, idx, included);
		idx = idx + 1;
		
		if (script(sc) := inlined[resolvedIncludes[i]]) {
			// Rename any temp variables; uncomment if we don't want to rename the same var multiple times as it goes through the import chain
			sc = visit(sc) {
				case variable_name(vn) : if(/^<nm:[0-9]+><pre:[^\$]+>$/ := reverse(vn), startsWithTempPrefix(reverse(pre))/*, !startsWith(pre,"__")*/) insert("variable_name"(vn + "__<idx>"));
			}
			
			// Split the file into top-level and non-top-level items
			list[node] atTop = [ ]; list[node] atPoint = [ ];
			for (n <- sc) {
				if (getName(n) in { "class_def", "interface_def", "method" })
					atTop += n;
				else
					atPoint += n;
			}
			
			println("In Script <sname>, Include File <i> Adding <size(atTop)> Top-Level and <size(atPoint)> At-Point Lines"); 
			toplevelStuff = toplevelStuff + atTop;
			inclusionInserts[i] = atPoint;
		} else {
			throw "Unexpected script format";
		}
	}
	
	// Replace each invoke with the non-top-level contents of the related include or require
	scr = replaceInvokes(scr, inclusionInserts);
	
	// Tack the top-level stuff onto the end of the script so we can analyze it
	if (script(sc) := scr) 
		scr = "script"(sc + toplevelStuff);
	else
		throw "Unexpected script format";
	
	// Now, return the expanded version of the script.
	inlined[sname] = scr;
	return < inlined, idx >;
}

private str resolveInclude(str include, list[str] prefixes, bool(str) fileExists) {
	// Does the include start with "./"? Then, take that off and invoke recursively.
	if (size(include) > 2 && include[0] == "." && include[1] == "/") return resolveInclude(substring(include,2), prefixes, fileExists);
	
	// Does the include start with "../"? Then, take that off and invoke recursively, 
	// using the parent of the script path
	if (size(include) > 3 && include[0] == "." && include[1] == "." && include[2] == ".") {
		base = reverse(prefixes[0]);
		if (/[^\/]+[\/]<rest:.*>/ := base) base = rest;
		prefixes[0] = reverse(base);
		return resolveInclude(substring(include,3), prefixes, fileExists);
	}

	// Check to see if we can find the file after attaching one of the prefixes. The first is the
	// working directory (if that was not empty), the rest are library paths.
	for (pre <- prefixes) if (fileExists(pre + "/" + include)) {
		return pre + "/" + include;
	}

	println("failed to resolve <include>");
	return "";
}

private node replaceInvokes(node scr, map[str,list[node]] inclusionInserts) {
	switch(scr) {
		case eval_expr(invoke(target(),method_name("require_once"),actuals([actual(ref(false),string(s))]))) :
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("require"),actuals([actual(ref(false),string(s))]))) : 
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("include_once"),actuals([actual(ref(false),string(s))]))) : 
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("include"),actuals([actual(ref(false),string(s))]))) : 
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case invoke(target(), method_name(_), actuals(_)) :
			println("Invoke: <prettyPrinter(scr)>");
		
		case script(l) : 
			return "script"(replaceInvokes(l,inclusionInserts));
		
		case class_def(abstract(a),final(f),cn,extends(),implements(il),members(ml)) : 
			return "class_def"("abstract"(a),"final"(f),cn,"extends"(),"implements"(il),"members"(replaceInvokes(ml,inclusionInserts)));
		
		case class_def(abstract(a),final(f),cn,extends(en),implements(il),members(ml)) :
			return "class_def"("abstract"(a),"final"(f),cn,"extends"(en),"implements"(il),"members"(replaceInvokes(ml,inclusionInserts)));
		
		case interface_def(inm,extends(el),members(ml)) :
			return "interface_def"(inm,"extends"(el),"members"(replaceInvokes(ml,inclusionInserts)));
		
		case method(signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)),body(b)) :
			return "method"("signature"("public"(pb),"protected"(pr),"private"(pv),"static"(st),"abstract"(a),"final"(f),"pass_rest_by_ref"(pbr),"return_by_ref"(rr),mn,"parameters"(fpl)),"body"(replaceInvokes(b,inclusionInserts)));
		
		case \try(body(tb),catches(cs)) :
			return "try"("body"(replaceInvokes(tb,inclusionInserts)),"catches"(replaceInvokes(cs,inclusionInserts)));
		
		case \catch(catch_type(ct),catch_name(cn),body(cb)) :
			return "catch"("catch_type"(ct),"catch_name"(cn),"body"(replaceInvokes(cb,inclusionInserts)));
	}

	return scr;
}

private list[node] replaceInvokes(list[node] scrs, map[str,list[node]] inclusionInserts) {
	list[node] result = [ ];
	for (s <- scrs) {
		nr = replaceInvokes(s,inclusionInserts);
		if (unwrapme(nrw) := nr)
			result = result + nrw;
		else
			result = result + nr;
	}
	return result;
}

private set[str] phcTempPrefixes = { "TLE", "TSr", "TSt", "TSi", "TSa", "Toa", "TSie", "Elcfv", "Elfck", "ElcfPD", "ElcfPF",
									 "TEL", "TSM", "TL", "PLA", "TEF", "LF", "THK", "LCF_KEY_", "TB", "TMIr", "TMIt", "TMIi",
									 "Tpuf", "Tpup", "Tpui", "Tpuo", "Tpum" };
 
private bool startsWithTempPrefix(str s) {
	return true in { startsWith(s,p) | p <- phcTempPrefixes };
}

private set[str] getLiteralIncludes(node scr) {
	return { s | /i:invoke(target(),method_name("require_once"),actuals([actual(ref(false),string(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("require"),actuals([actual(ref(false),string(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("include_once"),actuals([actual(ref(false),string(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("include"),actuals([actual(ref(false),string(s))])) <- scr };
}
