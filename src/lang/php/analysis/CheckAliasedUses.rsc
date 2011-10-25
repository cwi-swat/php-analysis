@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::CheckAliasedUses

import List;
import Set;
import Relation;
import IO;
import String;

import lang::php::analysis::SimpleAlias;

public set[MemItem] reachableObjects(AAInfo aaInfo, str item) {
	set[str] allFieldsOf(AAInfo aaInfo, str vn) {
		return { s | s <- aaInfo.abstractStore<0>, startsWith(s, "<vn>."), isFieldName(s) } + (("<vn>.@anyfield" in aaInfo.abstractStore<0>) ? { "<vn>.@anyfield" } : { });
	}

	set[str] allFieldNamesOf(AAInfo aaInfo, str vn) {
		return { justFieldNameOf(s) | s <- allFieldsOf(aaInfo, vn) };
	}

	set[MemItem] res = { i | i:objectVal(_,_) <- aaInfo.abstractStore[item] };
	if ("<item>[]" in aaInfo.abstractStore<0>) res = res + reachableObjects(aaInfo, "<item>[]");
	for (fn <- allFieldNamesOf(aaInfo,item)) res = res + reachableObjects(aaInfo, "<item>.<fn>");
		
	return res;
}

public rel[str,str] assignmentChains(list[node] body, set[str] params) {
	rel[str,str] res = { <p,p> | p <- params } + { < p, t > | /assign_var(variable_name(t),ref(r),variable_name(p)) <- body, p in params };
	solve(res) {
		res = res + { < p, t > | /assign_var(variable_name(t),ref(r),variable_name(p)) <- body, p in res<0> };
	}
	return res;
}

public void processBody(AAInfo aaInfo, str base, set[str] paramNames, list[node] b) {
	set[MemItem] paramObjs = { reachableObjects(aaInfo, "<base>::<item>") | item <- paramNames };

	// Get all reads and writes to fields made through variables. These are listed as < target, fieldname >
	rel[str,str,str] writtenFields = 
		{ < "<base>::<vn>", vn, fn > | /assign_field(variable_name(vn),field_name(fn),ref(r),e) <- b, vn in paramNames} + 
		{ < "<base>::<vn>", vn, "@anyfield" > | /assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),e) <- b, vn in paramNames };
	rel[str,str,str] readFields = 
		{ < "<base>::<vn>", vn, fn > | /field_access(variable_name(vn),field_name(fn)) <- b, vn in paramNames } + 
		{ < "<base>::<vn>", vn, "@anyfield" > | /field_(variable_name(vn),variable_field(variable_name(fn)),ref(r),e) <- b, vn in paramNames };
				 
	// Pare these down to only be writes and reads that effect the param objects. These will
	// be given as < target, object >.
	rel[str,MemItem] writtenFieldTargets = { < wf, mi > | wf <- writtenFields<0>, mi <- (reachableObjects(aaInfo,wf) & paramObjs) };
	rel[str,MemItem] readFieldTargets = { < rf, mi > | rf <- readFields<0>, mi <- (reachableObjects(aaInfo,rf) & paramObjs) };
	
	// Invert, which gives us the param objects, plus the targets which represent them, i.e,
	// tuples of < object, target >.
	rel[MemItem,str] writtenObjectFields = invert(writtenFieldTargets);
	rel[MemItem,str] readObjectFields = invert(readFieldTargets);
	
	// Get the assignment chains, we only want to find errors through different parameters, not through
	// temps created as part of the three-address form conversion. We take the reflexive/transitive
	// closure to make searches easier. So, assignment chains give back tuples like <a, t1>, <t1, t2>,
	// for t1 = a, t2 = t1, with the closure then giving < a, t1>, <a, t2>, <t1, t2>. Inverted we
	// get < t1, a>, <t2, a>, <t2, t1>, which lets us tell that (for instance) t1 and t2 both
	// lead back to a.
	rel[str,str] chains = assignmentChains(b, paramNames)*;
	rel[str,str] ichains = invert(chains);
	
	// For writes, just get those objects written through multiple targets, since only these writes
	// can be sources of write/write errors.
	set[MemItem] writtenWithMultipleTargets = { wf | wf <- writtenObjectFields<0>, size(writtenObjectFields[wf]) > 1 };
	
	// Write/write problems, where we write through two different params into the same object
	// NOTE: We do not differentiate between fields here, but maybe should to improve precision.
	problemPairs = { };
	for (wf <- writtenWithMultipleTargets) {
		writingFields = writtenObjectFields[wf];
		// Get back each pair of targets that have not already been processed and that are assigned
		// from a parameter.
		for ({f1,f2,_*} := writingFields, <f1,f2> notin problemPairs, size(ichains[getOneFrom(writtenFields[f1]<0>)] & paramNames) > 0, size(ichains[getOneFrom(writtenFields[f2]<0>)] & paramNames) > 0) {
			f1params = ichains[getOneFrom(writtenFields[f1]<0>)] & paramNames; // Which parameters assign into f1?
			f2params = ichains[getOneFrom(writtenFields[f2]<0>)] & paramNames; // Which parameters assign into f2?
			paramPaths = f1params + f2params;
			// If the union has size > 1, this means multiple parameters reach a write to object wf.
			if (size(paramPaths) > 1) {
				println("WARNING: Writes to the same object can occur through variables <f1> (parameter(s) <f1params>) and <f2> (parameter(s) <f2params>");
				problemPairs = problemPairs + { < f1, f2 > , < f2, f1 > };
			}
		}
	}
	
	// Read/write problems, where we read through one param and write through another
	// NOTE: We do not differentiate between fields here, but maybe should
	for (wf <- writtenObjectFields<0>, wf in readObjectFields<0>, f1 <- writtenObjectFields[wf], f2 <- readObjectFields[wf], <f1, f2> notin problemPairs, size(ichains[f1] & paramNames) > 0, size(ichains[f2] & paramNames) > 0) {
		f1params = ichains[f1] & paramNames;
		f2params = ichains[f2] & paramNames;
		paramPaths = f1params & f2params;
		if (size(paramPaths) > 1) {
			println("WARNING: Writes to the same object can occur through variables <f1> (parameter(s) <f1params>) and <f2> (parameter(s) <f2params>)");
			problemPairs = problemPairs + { < f1, f2 > , < f2, f1 > };
		}
	}
}

public void simpleCheck(AAInfo aaInfo, node scr) {
	if (script(bs) := scr) {
		//gbody = [ b | b <- bs, getName(b) notin { "class_def", "interface_def", "method" }];
		
		for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- bs) {
			set[str] paramNames = { fpn | formal_parameter(_,_,name(variable_name(fpn),_)) <- fpl } + { "@varargs" };
			processBody(aaInfo, "global::<mn>", paramNames, b);
		}
		
		for (class_def(_,_,class_name(cn),_,_,members(ml)) <- bs, f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml) {
			set[str] paramNames = { fpn | formal_parameter(_,_,name(variable_name(fpn),_)) <- fpl } + { "@varargs" };
			processBody(aaInfo, "<cn>::<mn>", paramNames, b);
		}
	}
}