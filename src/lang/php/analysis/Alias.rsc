@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::Alias

import IO;
import Node;
import List;
import Set;
import Relation;
import lang::php::analysis::BasicBlocks;
import lang::php::analysis::Split;
import lang::php::analysis::ProgramPoints;
import lang::php::pp::PrettyPrinter;
import lang::php::util::Constants;
import lang::php::analysis::InlineIncludes;
import lang::php::analysis::CFG;
import vis::Figure;
import vis::Render;

public void generateAliasModel(map[str,node] phpScripts, str scriptName) {
	inlinedScript = inlineIncludesForFile(mediawiki162, scriptName, phpScripts, mediawiki162Prefixes, mediawiki162Libs);
	generateAliasModel(inlinedScript);
}

public void generateAliasModel(node inlinedScript) {
	// Add program point information to the script; these points can be used to link back in computed
	// points-to information
	ss = addProgramPoints(splitScript(inlinedScript));
	
	// Generate the control flow graphs for the top level and for each function/method
	wpCFGs = { < owner, s, formCFG(getOneFrom(ss[owner,s])) > | < owner,s,_ > <- ss };

	// Get back the top-level CFG; we will build the alias information from here
	mainCFG = getOneFrom(wpCFGs[globalOwns(),"***toplevel"]);
}

data AliasItem = cell(str name) | globalcell(str name) | deref() | field() | index() | object();
alias AliasToken = list[AliasItem];
alias Alias = tuple[AliasToken left, AliasToken right];
alias AliasSet = set[Alias];

public set[&T] filterSet(set[&T] s, bool(&T) filterfun) {
	return { si | si <- s, filterfun(si) };
}

public bool tokenStartsWith(AliasToken atok, AliasItem aitem) {
	return [aItem,_*] := atok;
}

public bool tokenStartsWith(AliasToken atok, list[AliasItem] aitems) {
	return [aItems,_*] := atok;
}

public bool leftStartsWith(Alias a, AliasItem aitem) {
	return tokenStartsWith(a.left, aitem);
}

public bool leftStartsWith(Alias a, list[AliasItem] aitems) {
	return tokenStartsWith(a.left, aitems);
}

public bool rightStartsWith(Alias a, AliasItem aitem) {
	return tokenStartsWith(a.right, aitem);
}

public bool rightStartsWith(Alias a, list[AliasItem] aitems) {
	return tokenStartsWith(a.right, aitems);
}

public bool startsWith(Alias a, AliasItem aitem) {
	return leftStartsWith(a,aitem) || rightStartsWith(a,aitem);
}

public bool startsWith(Alias a, list[AliasItem] aitems) {
	return leftStartsWith(a,aitems) || rightStartsWith(a,aitems);
}

public AliasSet killStartsWith(AliasSet aset, str name) {
	bool doesNotStartWith(Alias a) {
		return !startsWith(a,cell(name));
	}
	return filterSet(aset, doesNotStartWith); 
}

public AliasSet killStartsWith(AliasSet aset, list[AliasItem] aitems) {
	bool doesNotStartWith(Alias a) {
		return !startsWith(a,aitems);
	}
	return filterSet(aset, doesNotStartWith); 
}

public AliasSet addAliasPairs(AliasSet aset, AliasToken left, AliasToken right) {
	;
}

//
// Taken, in slightly modified form, from Interprocedural Pointer Alias Analysis,
// by Michael Hind, Michael Burke, Paul Carini, and Jong-Deok Choi, ACM TOPLAS,
// Volume 21, Number 4, July 1999, page 852
//
public set[AliasToken] computeAliases(AliasSet aset, AliasToken atok, int derefLevel) {
	return expandAliases(aset, atok, derefLevel, { });
}

//
// Taken, in slightly modified form, from Interprocedural Pointer Alias Analysis,
// by Michael Hind, Michael Burke, Paul Carini, and Jong-Deok Choi, ACM TOPLAS,
// Volume 21, Number 4, July 1999, page 852
//
public set[AliasToken] expandAliases(AliasSet aset, AliasToken atok, int derefLevel, set[AliasToken] newAliases) {
	if (derefLevel == 0)
		// NOTE: This struck me as being wrong in the paper. If we have an alias < a, b >, created using
		// a reference, like a &= b, the code would not return b, it would just add a to the result
		// set. However, b is an alias, and so we seemingly would want to include it. So, the code
		// here includes any direct aliases of atok, either of the form < atok, _ > or < _, atok >,
		// as well as including atok itself. So, given aliases < a, b >, < b , c >, < d, a >,
		// this would return { a, b, d }. It will not return c, but that is reachable from b.
		newAliases = newAliases + aset[atok] + invert(aset)[atok] + atok;
	else {
		for (<[atok,ai,_*],tgt> <- aset) newAliases = expandAliases(aset, tgt, derefLevel-1, newAliases);
		for (<tgt,[atok,ai,_*]> <- aset) newAliases = expandAliases(aset, tgt, derefLevel-1, newAliases);
	}
	return newAliases;
}

//
// Get the possible alias tokens for the given atok and deref level. For instance, starting
// with a and a deref level of 1, it is possible to get *a, a->f, or a[]. Only give those
// back that are there, we aren't calculating permutations.
//
public set[AliasToken] getDepthVariants(AliasSet aset, AliasToken atok, int derefLevel) {
	set[AliasToken] res = { };
	
	if (derefLevel == 0)
		res = { atok };
	else
		for ([atok,ai,_*] <- carrier(aset)) res = res + getDepthVariants(aset,[atok,ai],derefLevel - 1);
		
	return res; 
}

//
// Taken, in slightly modified form, from Interprocedural Pointer Alias Analysis,
// by Michael Hind, Michael Burke, Paul Carini, and Jong-Deok Choi, ACM TOPLAS,
// Volume 21, Number 4, July 1999, page 858
//
// This defines a must alias as follows. Given token atok and the deref
// level given, get back the tokens that are aliased to atok at that
// level. For instance, given alias token a and deref level 1, with alias
// set containing < *a, b >, we could get back { b }.
public AliasSet must(AliasSet aset, AliasToken atok, int derefLevel) {
	set[AliasToken] aliases = computeAliases(aset, atok, derefLevel);
	set[AliasToken] variants = getDepthVariants(aset, atok, derefLevel);
	if (size(aliases) == 1)
		return aliases * variants + variants * aliases;
	else if (size(aliases) == 0)
		// Monotonicity requirement, see the above for more details
		return aset;
	else
		return { }; 
}

//
// A simplified kill calculator
public AliasSet kills(AliasSet aset, AliasToken atok) {
	set[AliasToken] aliases = aset[atok] + invert(aset)[atok];
	if (size(aliases) == 1)
		return aliases * atok + atok * aliases;
	else
		return { };
}

//
// Transfer function, working over individual statements. Given the IN set, the node,
// and some additional information, yield the OUT set.
//
public AliasSet transferAA(AliasSet aliases, node nd, bool returnsRef) {
	AliasSet res = aliases;
	
	switch(nd) {
		case \return(variable_name(vn)) :
			if (returnsRef)
				res = aliases - must(aliases, [cell("@return")], 0) + 
					< [cell("@return")], [cell(vn)] > ;
			else
				res = aliases - must(aliases, [cell("@return")], 1) + 
					computeAliases(aliases,[cell("@return")],1) * computeAliases(aliases,[cell(vn)],2);
		
		// Map any local instances of the returned result to the same location as vn.
		case \global(variable_name(vn)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [globalcell(vn)] > ; 

		// Various and sundry assignment cases...
		case assign_var(variable_name(vn),ref(false),cast(_,variable_name(cvn))) : 
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);

		case assign_var(variable_name(vn),ref(true),cast(_,variable_name(cvn))) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
		
		case assign_var(variable_name(vn),ref(b),invoke(target(), mn, actuals(al))) : 
			handleFunctionInvoke(vn,b,mn,al);
			
		case assign_var(variable_name(vn),ref(b),invoke(target(variable_name(t)), mn, actuals(al))) : 
			handleMethodInvoke(vn,b,t,mn,al);
			
		case assign_var(variable_name(vn),ref(b),invoke(target(class_name(t)), mn, actuals(al))) : 
			handleStaticInvoke(vn,b,t,mn,al);
			
		case assign_var(variable_name(vn),ref(b),new(cn, actuals(al))) : 
			handleConstructorInvoke(vn,b,cn,al);
			
		case assign_var(variable_name(vn),ref(false),variable_name(cvn)) :
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
		
		case assign_var(variable_name(vn),ref(true),variable_name(cvn)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
			
		case assign_var(variable_name(vn),ref(false),array_access(v,idx)) :
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
			
		case assign_var(variable_name(vn),ref(true),array_access(v,idx)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
			
		case assign_var(variable_name(vn),ref(false),field_access(t,f)) :
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
			
		case assign_var(variable_name(vn),ref(true),field_access(t,f)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
			
		case assign_var(variable_name(vn),ref(false),array_next(v)) : 
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
			
		case assign_var(variable_name(vn),ref(true),array_next(v)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
			
		case assign_var(variable_name(vn),ref(false),foreach_get_val(cvn,ht)) :
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
			
		case assign_var(variable_name(vn),ref(true),foreach_get_val(cvn,ht)) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;
			
		case assign_var(variable_name(vn),ref(false),_) :
			res = aliases - must(aliases, [cell(vn)], 1) +
				  { [cell(vn),deref()] } * computeAliases(aliases,[cell(cvn)],2);
			
		case assign_var(variable_name(vn),ref(true),_) :
			res = aliases - must(aliases, [cell(vn)], 0) + < [cell(vn)], [cell(cvn)] >;

		case assign_field(variable_name(vn),fn,ref(false),cast(_,variable_name(cvn))) : killAndPropagate(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(true),cast(_,variable_name(cvn))) : remap(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(b),invoke(target(), mn, actuals(al))) : handleFunctionInvoke(vn,b,mn,al);
		case assign_field(variable_name(vn),fn,ref(b),invoke(target(variable_name(t)), mn, actuals(al))) : handleMethodInvoke(vn,b,t,mn,al);
		case assign_field(variable_name(vn),fn,ref(b),invoke(target(class_name(t)), mn, actuals(al))) : handleStaticInvoke(vn,b,t,mn,al);
		case assign_field(variable_name(vn),fn,ref(b),new(cn, actuals(al))) : handleConstructorInvoke(vn,b,cn,al);
		case assign_field(variable_name(vn),fn,ref(false),variable_name(cvn)) : killAndPropagate(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(true),variable_name(cvn)) : remap(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(false),array_access(v,idx)) : killAndPropagate(vn, v);
		case assign_field(variable_name(vn),fn,ref(true),array_access(v,idx)) : remap(vn, v);
		case assign_field(variable_name(vn),fn,ref(false),field_access(t,f)) : killAndPropagate(vn, t, f);
		case assign_field(variable_name(vn),fn,ref(true),field_access(t,f)) : remap(vn, t, f);
		case assign_field(variable_name(vn),fn,ref(false),array_next(v)) : killAndPropagate(vn, v);
		case assign_field(variable_name(vn),fn,ref(true),array_next(v)) : remap(vn, v);
		case assign_field(variable_name(vn),fn,ref(false),foreach_get_val(cvn,ht)) : killAndPropagate(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(true),foreach_get_val(cvn,ht)) : remap(vn, cvn);
		case assign_field(variable_name(vn),fn,ref(false),_) : killTarget(vn);
		case assign_field(variable_name(vn),fn,ref(true),_) : remapNew(vn);

		case assign_array(variable_name(vn),rv,ref(false),cast(_,variable_name(cvn))) : killAndPropagate(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(true),cast(_,variable_name(cvn))) : remap(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(b),invoke(target(), mn, actuals(al))) : handleFunctionInvoke(vn,b,mn,al);
		case assign_array(variable_name(vn),rv,ref(b),invoke(target(variable_name(t)), mn, actuals(al))) : handleMethodInvoke(vn,b,t,mn,al);
		case assign_array(variable_name(vn),rv,ref(b),invoke(target(class_name(t)), mn, actuals(al))) : handleStaticInvoke(vn,b,t,mn,al);
		case assign_array(variable_name(vn),rv,ref(b),new(cn, actuals(al))) : handleConstructorInvoke(vn,b,cn,al);
		case assign_array(variable_name(vn),rv,ref(false),variable_name(cvn)) : killAndPropagate(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(true),variable_name(cvn)) : remap(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(false),array_access(v,idx)) : killAndPropagate(vn, v);
		case assign_array(variable_name(vn),rv,ref(true),array_access(v,idx)) : remap(vn, v);
		case assign_array(variable_name(vn),rv,ref(false),field_access(t,f)) : killAndPropagate(vn, t, f);
		case assign_array(variable_name(vn),rv,ref(true),field_access(t,f)) : remap(vn, t, f);
		case assign_array(variable_name(vn),rv,ref(false),array_next(v)) : killAndPropagate(vn, v);
		case assign_array(variable_name(vn),rv,ref(true),array_next(v)) : remap(vn, v);
		case assign_array(variable_name(vn),rv,ref(false),foreach_get_val(cvn,ht)) : killAndPropagate(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(true),foreach_get_val(cvn,ht)) : remap(vn, cvn);
		case assign_array(variable_name(vn),rv,ref(false),_) : killTarget(vn);
		case assign_array(variable_name(vn),rv,ref(true),_) : remapNew(vn);
		
		case assign_var_var(v,ref(r),e) :
			println("WARNING: We do not currently handle assignments through variable variables");
		
		case assign_next(variable_name(vn),ref(false),cast(_,variable_name(cvn))) : killAndPropagate(vn, cvn);
		case assign_next(variable_name(vn),ref(true),cast(_,variable_name(cvn))) : remap(vn, cvn);
		case assign_next(variable_name(vn),ref(b),invoke(target(), mn, actuals(al))) : handleFunctionInvoke(vn,b,mn,al);
		case assign_next(variable_name(vn),ref(b),invoke(target(variable_name(t)), mn, actuals(al))) : handleMethodInvoke(vn,b,t,mn,al);
		case assign_next(variable_name(vn),ref(b),invoke(target(class_name(t)), mn, actuals(al))) : handleStaticInvoke(vn,b,t,mn,al);
		case assign_next(variable_name(vn),ref(b),new(cn, actuals(al))) : handleConstructorInvoke(vn,b,cn,al);
		case assign_next(variable_name(vn),ref(false),variable_name(cvn)) : killAndPropagate(vn, cvn);
		case assign_next(variable_name(vn),ref(true),variable_name(cvn)) : remap(vn, cvn);
		case assign_next(variable_name(vn),ref(false),array_access(v,idx)) : killAndPropagate(vn, v);
		case assign_next(variable_name(vn),ref(true),array_access(v,idx)) : remap(vn, v);
		case assign_next(variable_name(vn),ref(false),field_access(t,f)) : killAndPropagate(vn, t, f);
		case assign_next(variable_name(vn),ref(true),field_access(t,f)) : remap(vn, t, f);
		case assign_next(variable_name(vn),ref(false),array_next(v)) : killAndPropagate(vn, v);
		case assign_next(variable_name(vn),ref(true),array_next(v)) : remap(vn, v);
		case assign_next(variable_name(vn),ref(false),foreach_get_val(cvn,ht)) : killAndPropagate(vn, cvn);
		case assign_next(variable_name(vn),ref(true),foreach_get_val(cvn,ht)) : remap(vn, cvn);
		case assign_next(variable_name(vn),ref(false),_) : killTarget(vn);
		case assign_next(variable_name(vn),ref(true),_) : remapNew(vn);

		case unset(target(),name(v),indices(idxs)) : {
			return "unset(<pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";
		}
		
		case unset(target(t),name(v),indices(idxs)) : {
			return "unset(<pp(t)>-\><pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";
		}
	}
}