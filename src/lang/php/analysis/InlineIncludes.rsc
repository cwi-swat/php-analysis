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

//
// TODO: Should probably pass (and use!) include path as well, just in case there are files that we
// do not find otherwise...
//
public map[str,node] inlineAllIncludes(loc base, map[str,node] scripts, set[str] prefixes, set[str] libs) {
	int idx = 1;
	map[str,node] inlined = ( );
	for (s <- scripts<0>) < inlined, idx > = inlineIncludes(base, s, scripts, inlined, idx, prefixes, libs);
	return inlined; 
}

public node inlineIncludesForFile(loc base, str sname, map[str,node] scripts, set[str] prefixes, set[str] libs) {
	int idx = 1;
	map[str,node] inlined = ( );
	< inlined, idx > = inlineIncludes(base, sname, scripts, inlined, idx, prefixes, libs);
	return inlined[sname]; 
}

private tuple[map[str,node],int] inlineIncludes(loc base, str sname, map[str,node] scripts, map[str,node] inlined, int idx, set[str] prefixes, set[str] libs) {
	println("Inlining required and included scripts for file <sname>");
	return inlineIncludes(base, sname, scripts, inlined, idx, { sname }, prefixes, libs);
}

private tuple[map[str,node],int] inlineIncludes(loc base, str sname, map[str,node] scripts, map[str,node] inlined, int idx, set[str] included, set[str] prefixes, set[str] libs) {
	if (sname in inlined) return < inlined, idx >;
	
	println("Inlining <sname>");
	// First, get the paths for any includes we can find, in those cases where the include is a string literal
	scr = propIncludesRequires(scripts[sname]);
	set[str] includes = getLiteralIncludes(scr);
	for (i <- (includes & libs)) println("Script <sname>: using library <i>");
	includes = includes - libs; // TODO: Should not which includes are being included, so we can model them
	
	// Resolve the paths so they match actual files in the scripts map
	map[str,str] resolvedIncludes = ( i : resolveInclude(i, sname, base, |file:///| + (base + sname).parent, scripts, prefixes) | i <- includes, resolvableInclude(i, sname, base, |file:///| + (base + sname).parent, scripts, prefixes) );
						    
	// For each include, get the related script, then figure out what top-level components each has and what 
	// needs to be inserted in place of each include or require call.
	list[node] toplevelStuff = [ ];
	map[str,list[node]] inclusionInserts = ( );
	for (i <- includes, i in resolvedIncludes, resolvedIncludes[i] notin included) {
		included = included + resolvedIncludes[i];
		< inlined, idx > = inlineIncludes(base,resolvedIncludes[i],scripts,inlined,idx,included,prefixes,libs);
		idx = idx + 1;
		
		if (script(sc) := inlined[resolvedIncludes[i]]) {
			// Rename any temp variables; uncomment if we don't want to rename the same var multiple times as it goes through the import chain
			sc = visit(sc) {
				case variable_name(vn) : if(/^<nm:[0-9]+><pre:[^\$]+>$/ := reverse(vn), startsWithTempPrefix(reverse(pre))/*, !startsWith(pre,"__")*/) insert("variable_name"(vn + "__<idx>"));
			}
			// Grab out all the top-level stuff from the script, so we can make it top-level in the input script
			toplevelStuff = toplevelStuff + [ n | n <- sc, getName(n) in { "class_def", "interface_def", "method" } ];
			
			// Grab out all the stuff to insert, which is everything we didn't pull out in the last step
			list[node] toInsert = [ n | n <- sc, getName(n) notin { "class_def", "interface_def", "method" } ];
			inclusionInserts[i] = toInsert;
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

private str resolveInclude(str include, str toplevel, loc base, loc scriptBase, map[str,node] scripts, set[str] prefixes) {
	< s, b > = resolveIncludeInternal(include,toplevel,base,scriptBase,scripts,prefixes);
	return s;
}

private bool resolvableInclude(str include, str toplevel, loc base, loc scriptBase, map[str,node] scripts, set[str] prefixes) {
	< s, b > = resolveIncludeInternal(include,toplevel,base,scriptBase,scripts,prefixes);
	if (!b) println("WARNING: <include> not resolvable");
	return b;
}

private tuple[str,bool] resolveIncludeInternal(str include, str toplevel, loc base, loc scriptBase, map[str,node] scripts, set[str] prefixes) {
	// println("Trying to find <include>");
	// Is the include in the scripts map? If so, just return it
	if (include in scripts) return < include, true >;
	
	// Is the include in the scripts map if we stick the base onto it?
	//println("Script base <scriptBase.path>"); println("Base <base.path>");
	str basePart = (scriptBase.path == base.path) ? base.path : substring(scriptBase.path, endsWith(base.path,"/") ? size(base.path) : size(base.path)+1);
	if ( (basePart + "/" + include) in scripts ) return < basePart + "/" + include, true >;
	
	// Is the include in the scripts map if we stick any of the prefixes onto it?
	for (pre <- prefixes) if ( (pre + "/" + include) in scripts ) return < pre + "/" + include, true >;
	
	// Does the include start with "./"? Then, take that off and invoke recursively.
	if (size(include) > 2 && include[0] == "." && include[1] == "/") return resolveIncludeInternal(substring(include,2), toplevel, base, scriptBase, scripts, prefixes);
	
	// Does the include start with "../"? Then, take that off and invoke recursively, 
	// using the parent of the script path
	if (size(include) > 3 && include[0] == "." && include[1] == "." && include[2] == ".") return resolveIncludeInternal(substring(include,3), toplevel, base, ( |file:///| + (scriptBase.parent)), scripts, prefixes);
	
	return < "", false >;
}

private node replaceInvokes(node scr, map[str,list[node]] inclusionInserts) {
	switch(scr) {
		case eval_expr(invoke(target(),method_name("require_once"),actuals([actual(ref(false),str(s))]))) :
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("require"),actuals([actual(ref(false),str(s))]))) : 
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("include_once"),actuals([actual(ref(false),str(s))]))) : 
			if (s in inclusionInserts) return "unwrapme"(inclusionInserts[s]);
			
		case eval_expr(invoke(target(),method_name("include"),actuals([actual(ref(false),str(s))]))) : 
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
	return { s | /i:invoke(target(),method_name("require_once"),actuals([actual(ref(false),str(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("require"),actuals([actual(ref(false),str(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("include_once"),actuals([actual(ref(false),str(s))])) <- scr } +
		   { s | /i:invoke(target(),method_name("include"),actuals([actual(ref(false),str(s))])) <- scr };
}

public set[node] getIncludes(node scr) {
	return { i | /i:invoke(target(),method_name("require_once"),actuals(_)) <- scr } +
		   { i | /i:invoke(target(),method_name("require"),actuals(_)) <- scr } +
		   { i | /i:invoke(target(),method_name("include_once"),actuals(_)) <- scr } +
		   { i | /i:invoke(target(),method_name("include"),actuals(_)) <- scr };
}