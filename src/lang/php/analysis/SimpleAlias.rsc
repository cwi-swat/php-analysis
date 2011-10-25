@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::SimpleAlias

import Node;
import List;
import Set;
import Relation;
import Integer;
import IO;
import String;

import lang::php::pp::PrettyPrinter;
import lang::php::analysis::Inheritance;
import lang::php::analysis::FunctionSummaries;

//
// TODO
//
// 1. Handle varargs functions appropriately. We currently assign the inputs correctly, but
//    need to watch for the functions that get these values back out.
//
// 2. Properly handle functions which can create aliases which are in the library: currently,
//    the only one that does this that we use from the library is mysql_fetch_object, and it
//    does not do this in mediawiki. 
//
// 3. Properly handle functions that allocate new objects. Currently, we only have one,
//    mysql_fetch_object, and, at least for mediawiki, it only creates one type of object,
//    stdClass.
//
// 4. Handle accesses to globals through the GLOBALS array. It does not appear that this is
//    used in mediawiki. Addendum: They are being used (see, for instance, extractGlobal,
//    which sets a global based on an input parameter). We will need to see where this
//    is being used and see if we can account for it; if not, a call to this will set
//    all globals, destroying the analysis precision.
//
// 5. I believe all scalar exps are included. Make sure of this, though, as this is useful
//    initialization information.
//

//
// Abstract memory items. For objects, we track the instantiated class and the allocation site,
// which we use as a shorthand to keep track of unique objects. This is part of the flow
// insensitivity of this analysis -- all objects allocated at a given allocation site are considered
// to be the same object, which could lead to bigger points-to sets.
//
data MemItem = scalarVal() | arrayVal() | objectVal(str className, int allocationSite);

//
// The difference versions of this type represent the different "stages" of the analysis. The first is when we have the needed information
// to start, but have not computed anything yet. The second is when we have all the signatures and the (very) abstract store, which holds
// the mappings from the various names found in the code to abstract values.
//
data AAInfo 
	= aainfo(set[str] definedClasses, InheritanceGraph ig, FieldsRel definedFields, MethodsRel definedMethods, rel[str,str] classAliases, rel[str,str] methodAliases)
	| aainfo(set[str] definedClasses, InheritanceGraph ig, FieldsRel definedFields, MethodsRel definedMethods, rel[str,MemItem] abstractStore, map[str,node] signatures, rel[str,str] referencePairs, set[str] unknownMethods, rel[str,str] classAliases, rel[str,str] methodAliases)
	;

//
// Allocation sites, represented as ints. Each allocation site will be given a unique id.
//
anno int node@asite;

//
// Top-level driver for performing the simple alias analysis on this script.
//
public AAInfo calculateAliases(node scr) {
	scr = markAllocationSites(scr);
	
	ig = calculateInheritance(scr);
	AAInfo aaInfo = aainfo(getDefinedClasses(scr), ig, calculateFieldsRel(scr, ig), calculateMethodsRel(scr, ig), { }, { });
	rel[str,MemItem] res = { };
	map[str,node] signatures = ( );
	
	if (script(bs) := scr) {
		aaInfo.classAliases = { <f,t> | /ca:class_alias(\alias(class_name(f)),class_name(t)) <- bs };
		aaInfo.methodAliases = { <f,t> | /ma:method_alias(\alias(method_name(f)),method_name(t)) <- bs };
		
		println("Calculating initial allocations");
		
		// First pass: get allocations in the global scope
		gbody = [ b | b <- bs, getName(b) notin { "class_def", "interface_def", "method" }];
		set[str] vars = { vn | b <- gbody, /variable_name(vn) <- b };
		res = getInitializingAssignments(aaInfo, "global", vars, gbody);
		
		// Also get allocations in each global function
		for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- bs) {
			vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
			res = res + getInitializingAssignments(aaInfo, "global::<mn>", vars, b);
			signatures["global::<mn>"] = sig;
		}
		
		// And, get allocations in each method
		for (class_def(_,_,class_name(cn),_,_,members(ml)) <- bs, f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml) {
			vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
			res = res + getInitializingAssignments(aaInfo, "<cn>::<mn>", vars, b);
			signatures["<cn>::<mn>"] = sig;
		}
		
		// We now have the initial abstract store, with all allocations, and the signatures, keyed by function or class::method name.
		// Extend aaInfo with this new information.
		aaInfo = aainfo(aaInfo.definedClasses, aaInfo.ig, aaInfo.definedFields, aaInfo.definedMethods, res, signatures, { }, { }, aaInfo.classAliases, aaInfo.methodAliases);
		
		// Continue propagation until the abstact store stabilizes
		solve(aaInfo) {
			println("Propagating alias information within procedures and along call graphs");
			
			vars = { vn | b <- gbody, /variable_name(vn) <- b };
			aaInfo = propagate(aaInfo, "global", vars, gbody);

			for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- bs) {
				vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
				aaInfo = propagate(aaInfo, "global::<mn>", vars, b);
			}

			for (class_def(_,_,class_name(cn),_,_,members(ml)) <- bs, f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml) {
				vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
				aaInfo = propagate(aaInfo, "<cn>::<mn>", vars, b);
			}
			
			println("Propagating information between class methods");
			for (class_def(_,_,class_name(cn),_,_,members(ml)) <- bs)
				aaInfo = propagateClassInfo(aaInfo, cn, { mn | f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml });

			println("Propagating information across reference pairs");
			aaInfo = propagatePairs(aaInfo);
		}
		
		// TODO: Should perform a sanity check here. Do we have any calls that we could not calculate results for? This is especially important for
		// method invocations off objects.
	} else {
		throw "Expected script, got <prettyPrinter(scr)>";
	}
	
	return aaInfo;
}

//
// Add a tag onto sites we consider to be allocation sites so we can differentiate them inside
// the analysis.
//
public node markAllocationSites(node n) {
	int asiteCounter = 0;
	
	int incme() { asiteCounter = asiteCounter + 1; return asiteCounter; }
	
	return visit(n) {
		case nd:new(cn, actuals(al)) => nd[@asite = incme()]
		
		case nd:cast(c,v) => nd[@asite = incme()]
		
		case nd:assign_field(t,fn,ref(r),e) => nd[@asite = incme()]
		
		case nd:invoke(_,_,_) => nd[@asite = incme()]
		
		case nd:static_array(_) => nd[@asite = incme()]
	};
}


//
// Gather initial assignments which we consider to be "initializers", ones that can create
// new values that are assigned into variables/fields/array locations/etc. At this stage we
// do not reason across method boundaries.
//
public rel[str,MemItem] getInitializingAssignments(AAInfo aaInfo, str namePrefix, set[str] vars, list[node] body) {
	set[str] definedClassesForCast = aaInfo.definedClasses + "stdClass";
	set[str] scalarExprs = { "unary_op", "bin_op", "constant", "instance_of", "int", "str", "bool", "real", "nil", "isset", "foreach_has_key", "foreach_get_key", "param_is_ref" };
	rel[str,MemItem] fiStore = { };
	
	str unaliasClass(str cn) {
		if (size(aaInfo.classAliases[cn]) == 1) return getOneFrom(aaInfo.classAliases[cn]);
		return cn;
	}
	
	visit(body) {
		// Standard assignments. If we are assigning the result of a new expression, keep track
		// of this. If the new expression uses a variable for the class name instead of a literal,
		// we could be creating any defined class. If we are casting, we treat casts as allocations.
		// Casts to object can yield any class as well as "stdClass", which is what happens when
		// you cast a non-object into an object. Invocations can yield allocations of objects
		// or arrays, or can yield scalars. NOTE: these same rules are used below as well
		// for assignments into arrays, fields, etc.
		case assign_var(variable_name(vn),ref(b),nd:new(class_name(cn), actuals(al))) : 
			fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),nd@asite) >;

		case assign_var(variable_name(vn),ref(b),nd:new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),nd@asite) >;
		
		case assign_var(variable_name(vn),ref(b),nd:cast(cast("object"),_)) :			
			for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),nd@asite) >;

		case assign_var(variable_name(vn),ref(b),nd:cast(cast("array"),_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;			

		case assign_var(variable_name(vn),ref(b),nd:cast(_,_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>", scalarVal() >;			

		case assign_var(variable_name(vn),ref(b),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vn>"}, mn, al, nd@asite);

		case assign_var(variable_name(vn),ref(b),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + < "<namePrefix>::<vn>", scalarVal() >;

		case assign_var(variable_name(vn),ref(b),e) :
			if (getName(e) in { "static_array" }) 
				fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", scalarVal() >;
			else if (getName(e) in scalarExprs) 
				fiStore = fiStore + < "<namePrefix>::<vn>", scalarVal() >;

		// Assignments into fields. If the field name is known, we presume that vn must be one
		// of the classes that implements this field (including extenders) or an instance of
		// stdClass, which could contain theoretically a field of any name. This is overly
		// conservative, a type inferencer would provide more precise results.
		//
		// NOTE: Turning off the assumptions. This gives us multiple allocation sites for the same
		// name, which is actually wrong. Instead, we assume nothing about the variable, just recording
		// the information about the field. If nothing is ever really assigned into the variable, we just
		// don't know what it is. We are doing a "whole-program" check, though, so this shouldn't be an
		// issue -- we have to assign something, somewhere before we can invoke on it.
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:new(class_name(cnf), actuals(al))) : {
			//if (fn in invert(aaInfo.definedFields)<0>) {
			//	for (cn <- (invert(aaInfo.definedFields)[fn] + "stdClass")) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//} else { 
			//	for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//}
			fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", objectVal(unaliasClass(cnf),nd@asite) >;
		}

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:new(variable_class(_), actuals(al))) : { 
			//if (fn in invert(aaInfo.definedFields)<0>) {
			//	for (cn <- (invert(aaInfo.definedFields)[fn] + "stdClass")) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//} else { 
			//	for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//}
			for (cnf <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", objectVal(unaliasClass(cnf),nd@asite) >;
		}
		
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:cast(cast("object"),_)) : {			
			//if (fn in invert(aaInfo.definedFields)<0>) {
			//	for (cn <- (invert(aaInfo.definedFields)[fn] + "stdClass")) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//} else { 
			//	for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//}
			for (cnf <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", objectVal(unaliasClass(cnf),nd@asite) >;
		}
			
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:cast(cast("array"),_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", arrayVal() >;			

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:cast(_,_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", scalarVal() >;			

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vn>.<fn>"}, mn, al, nd@asite);

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", scalarVal() >;

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),e) : {
			//if (fn in invert(aaInfo.definedFields)<0>) {
			//	for (cn <- (invert(aaInfo.definedFields)[fn] + "stdClass")) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//} else { 
			//	for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			//}
			if (getName(e) in { "static_array" })
				fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", arrayVal() > + < "<namePrefix>::<vn>.<fn>[]", scalarVal() >;
			else if (getName(e) in scalarExprs)
				fiStore = fiStore + < "<namePrefix>::<vn>.<fn>", scalarVal() >;
		}

		// Assignments into variable fields. We assign into an "@anyfield" field, which we can
		// then use to propagate through to the other fields.
		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:new(class_name(cn), actuals(al))) : { 
			//for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", objectVal(unaliasClass(cnf),nd@asite) >;
		}

		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:new(variable_class(_), actuals(al))) : { 
			//for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			for (cnf <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", objectVal(unaliasClass(cnf),nd@asite) >;
		}
		
		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:cast(cast("object"),_)) : { 
			//for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			for (cnf <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", objectVal(unaliasClass(cnf),nd@asite) >;
		}
			
		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:cast(cast("array"),_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", arrayVal() >;			

		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:cast(_,_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", scalarVal() >;			

		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vn>.@anyfield"}, mn, al, nd@asite);

		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + < "<namePrefix>::<vn>.<fn>.@anyfield", scalarVal() >;

		case af:assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),nd:e) : { 
			//for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>", objectVal(unaliasClass(cn),af@asite) >;
			if (getName(e) in { "static_array" })
				fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", arrayVal() > + < "<namePrefix>::<vn>.@anyfield[]", scalarVal() >;
			else if (getName(e) in scalarExprs)
				fiStore = fiStore + < "<namePrefix>::<vn>.@anyfield", scalarVal() >;
		}

		// If we treat a name like an array, assume it is one. All elements in the array are assumed to have
		// the same value.
		case assign_array(variable_name(vn),rv,ref(r),nd:new(class_name(cn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}

		case assign_array(variable_name(vn),rv,ref(r),nd:new(variable_class(_), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;
			for (cn <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}
		
		case assign_array(variable_name(vn),rv,ref(r),nd:cast(cast("object"),_)) : {			
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;
			for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}
			
		case assign_array(variable_name(vn),rv,ref(r),nd:cast(cast("array"),_)) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", arrayVal() >;			
		}

		case assign_array(variable_name(vn),rv,ref(r),nd:cast(_,_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", scalarVal() >;			

		case assign_array(variable_name(vn),rv,ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > ;
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vn>[]"}, mn, al, nd@asite);
		}

		case assign_array(variable_name(vn),rv,ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > ;
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + < "<namePrefix>::<vn>[]", scalarVal() >;
		}

		case assign_array(variable_name(vn),rv,ref(r),e) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;
			if (getName(e) in { "static_array" }) 
				fiStore = fiStore + < "<namePrefix>::<vn>[]", arrayVal() > + < "<namePrefix>::<vn>[][]", scalarVal() >;
			else if (getName(e) in scalarExprs) 
				fiStore = fiStore + < "<namePrefix>::<vn>[]", scalarVal() >;
		}

		// If we have variable variables we are sunk -- they could assign to any name in scope. To remain
		// conservative, we need to add a mapping from all vars in scope to whatever the type is, all the
		// while cursing whoever added this stupid feature.
		case assign_var_var(variable_name(vn),ref(r),nd:new(class_name(cn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			for (vni <- vars) fiStore = fiStore + < "<namePrefix>::<vni>", objectVal(unaliasClass(cn),nd@asite) >;
		}

		case assign_var_var(variable_name(vn),ref(r),nd:new(variable_class(_), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			for (vni <- vars, cn <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vni>", objectVal(unaliasClass(cn),nd@asite) >;
		} 
		
		case assign_var_var(variable_name(vn),ref(r),nd:cast(cast("object"),_)) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			for (vni <- vars, cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vni>", objectVal(unaliasClass(cn),nd@asite) >;
		}			

		case assign_var_var(variable_name(vn),ref(r),nd:cast(cast("array"),_)) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			for (vni <- vars, cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vni>", arrayVal() >;
		}
			
		case assign_var_var(variable_name(vn),ref(r),nd:cast(_,_)) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			for (vni <- vars, cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vni>", scalarVal() >;
		}

		case assign_var_var(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vni>" | vni <- vars}, mn, al, nd@asite);
		}

		case assign_var_var(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + { < "<namePrefix>::<vni>", scalarVal() > | vni <- vars };
		}

		case assign_var_var(variable_name(vn),ref(r),e) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", scalar() >; // since it is a string, if it is used as a varvar 
			if (getName(e) in { "static_array" }) 
				for (vni <- vars) fiStore = fiStore + < "<namePrefix>::<vni>", arrayVal() > + < "<namePrefix>::<vni>[]", scalarVal() >;
			else if (getName(e) in scalarExprs) 
				for (vni <- vars) fiStore = fiStore + < "<namePrefix>::<vni>", scalarVal() >;
		}
			
		// Assign next is treated just like assign array, above. 
		case assign_next(variable_name(vn),ref(r),nd:new(class_name(cn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}

		case assign_next(variable_name(vn),ref(r),nd:new(variable_class(_), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;
			for (cn <- definedClasses) fiStore = fiStore + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}
		
		case assign_next(variable_name(vn),ref(r),nd:cast(cast("object"),_)) : {			
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() >;
			for (cn <- definedClassesForCast) fiStore = fiStore + < "<namePrefix>::<vn>[]", objectVal(unaliasClass(cn),nd@asite) >;
		}
			
		case assign_next(variable_name(vn),ref(r),nd:cast(cast("array"),_)) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", arrayVal() >;			
		}

		case assign_next(variable_name(vn),ref(r),nd:cast(_,_)) :
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > + < "<namePrefix>::<vn>[]", scalarVal() >;			

		case assign_next(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > ;
			if (hasSummary(mn), allocatorFun(mn))
				fiStore = fiStore + initLibraryAllocators({"<namePrefix>::<vn>[]"}, mn, al, nd@asite);
		}

		case assign_next(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			fiStore = fiStore + < "<namePrefix>::<vn>", arrayVal() > ;
			if (hasSummary(mn), !allocatorFun(mn), !returnsVoid(mn))
				fiStore = fiStore + < "<namePrefix>::<vn>[]", scalarVal() >;
		}

		case assign_next(variable_name(vn),ref(r),e) : {
			fiStore = fiStore + < vn, arrayVal() >;
			if (getName(e) in { "static_array" }) 
				fiStore = fiStore + < "<namePrefix>::<vn>[]", arrayVal() > + < "<namePrefix>::<vn>[][]", scalarVal() >;
			else if (getName(e) in scalarExprs) 
				fiStore = fiStore + < "<namePrefix>::<vn>[]", scalarVal() >;
		}
	}
	
	return fiStore;
}

//
// Propagate the assignments within a single function body
//
public AAInfo propagate(AAInfo aaInfo, str namePrefix, set[str] vars, list[node] body) {

	set[str] fieldNameSet(str vn, str fn) {
		return ({ "<namePrefix>::<vn>.<fn>" } + (("<namePrefix>::<vn>.@anyfield" in aaInfo.abstractStore<0>) ? { "<namePrefix>::<vn>.@anyfield" } : { }));
	}
	
	set[str] allFieldsOf(str base, str vn) {
		return { s | s <- aaInfo.abstractStore<0>, startsWith(s, "<base>::<vn>."), isFieldName(s) } + (("<base>::<vn>.@anyfield" in aaInfo.abstractStore<0>) ? { "<base>::<vn>.@anyfield" } : { });
	}

	set[str] allFieldNamesOf(str base, str vn) {
		return { justFieldNameOf(s) | s <- allFieldsOf(base,vn) };
	}

	rel[str,MemItem] deepAssign(str target, str base, str item) {
		rel[str,MemItem] res = { };
		
		// First, assign directly from the target to the base
		res = res + { target } * aaInfo.abstractStore["<base>::<item>"];
		
		// Now, attempt to do the same for arrays
		if ("<base>::<item>[]" in aaInfo.abstractStore<0>) res = res + deepAssign("<target>[]", base, "<item>[]");
		
		// Now, do so for any fields
		for (fn <- allFieldNamesOf(base, item)) res = res + deepAssign("<target>.<fn>", base, "<item>.<fn>");
		
		return res;
	}

	rel[str,MemItem] deepAssign(set[str] targets, str base, str item) {
		rel[str,MemItem] res = { };
		for (t <- targets) res = res + deepAssign(t, base, item);
		return res;
	}
	
	rel[str,MemItem] deepAssign(set[str] targets, str base, set[str] item) {
		rel[str,MemItem] res = { };
		for (t <- targets, i <- item) res = res + deepAssign(t, base, i);
		return res;
	}

	//
	// Handle mapping the actuals onto the formals in a function/method call. Targets is the name being assigned into with
	// the call's return result, base is the calling context, fname is the name of the function or method being invoked,
	// and actuals are the actual parameters being passed into the function.
	//
	rel[str,MemItem] mapParams(set[str] targets, bool refTarget, str base, str fname, list[node] actuals) {
		if (signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)) := aaInfo.signatures[fname]) {
			list[str] paramNames = [ fpn | formal_parameter(_,_,name(variable_name(fpn),_)) <- fpl ];
			list[bool] paramIsRef = [ iref | formal_parameter(_,ref(iref),_) <- fpl ];
			int idx = 0;
			rel[str,MemItem] res = { };
			
			// First, map between formals and actuals while we have both formals and actuals to process
			// TODO: See if we need to do anything about pass_rest_by_ref, probably only for varargs...
			while (idx < min(size(paramNames),size(actuals))) {
				if (actual(ref(b), variable_name(vn)) := actuals[idx]) {
					res = res + deepAssign("<fname>::<paramNames[idx]>", base, vn);
					if (b || paramIsRef[idx]) {
						aaInfo.referencePairs = aaInfo.referencePairs + < "<base>::<vn>", "<fname>::<paramNames[idx]>" >; 
					}
				}
				idx = idx + 1;
			}
			// Second, if we have more actuals than formals, map them all to a variable called @varargs
			while (idx < size(actuals)) {
				if (variable_name(vn) := actuals[idx])
					res = res + deepAssign("<fname>::@varargs", base, vn);
				idx = idx + 1;
			}
			// Third, if we have more formals than actuals, we may want to add a check to see if
			// all these formals have defaults. If not, this would be a good place to give a warning.
			// For now, though, do nothing.
			while (idx < size(paramNames)) {
				// TODO: Warning code here
				idx = idx + 1;
			}
			
			// Fourth, map the return value for the function into the return targets. 
			res = res + deepAssign(targets, fname, "@return");

			// If we return by reference, add that into the pairs here... 
			if (rr && refTarget) aaInfo.referencePairs = aaInfo.referencePairs + targets * "<fname>::@return";
			
			return res;
		} else {
			throw "Invalid signature for <fname>: <aaInfo.signatures["fname"]>";
		}
	}
	
	rel[str,MemItem] mapParams(set[str] targets, bool refTarget, str base, str fname, list[str] actuals) {
		if (signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)) := aaInfo.signatures[fname]) {
			list[str] paramNames = [ fpn | formal_parameter(_,_,name(variable_name(fpn),_)) <- fpl ];
			list[bool] paramIsRef = [ iref | formal_parameter(_,ref(iref),_) <- fpl ];
			int idx = 0;
			rel[str,MemItem] res = { };
			
			// First, map between formals and actuals while we have both formals and actuals to process
			// TODO: See if we need to do anything about pass_rest_by_ref, probably only for varargs...
			while (idx < min(size(paramNames),size(actuals))) {
				res = res + deepAssign("<fname>::<paramNames[idx]>", base, actuals[idx]);
				if (paramIsRef[idx]) {
					aaInfo.referencePairs = aaInfo.referencePairs + < "<base>::<vn>", "<fname>::<paramNames[idx]>" >; 
				}
				idx = idx + 1;
			}
			// Second, if we have more actuals than formals, map them all to a variable called @varargs
			while (idx < size(actuals)) {
				res = res + deepAssign("<fname>::@varargs", base, actuals[idx]);
				idx = idx + 1;
			}
			// Third, if we have more formals than actuals, we may want to add a check to see if
			// all these formals have defaults. If not, this would be a good place to give a warning.
			// For now, though, do nothing.
			while (idx < size(paramNames)) {
				// TODO: Warning code here
				idx = idx + 1;
			}
			
			// Fourth, map the return value for the function into the return targets. 
			res = res + deepAssign(targets, fname, "@return");

			// If we return by reference, add that into the pairs here... 
			if (rr && refTarget) aaInfo.referencePairs = aaInfo.referencePairs + targets * "<fname>::@return";
			
			return res;
		} else {
			throw "Invalid signature for <fname>: <aaInfo.signatures["fname"]>";
		}
	}
	
	//
	// Handle propagation of alias information along the call/return edges associated with a call
	// to a top-level (i.e., global) function.
	//
	rel[str,MemItem] handleFunctionInvoke(set[str] targets, bool refTarget, str base, str fname, list[node] actuals) {
		rel[str,MemItem] res = { };
		
		// First, see if this is a library function. If so, we return the effects of this function
		// directly.
		if (hasSummary(fname)) {
			// First, if this function propagates allocation information, do so
			if (allocatorFun(fname)) res = res + propagateLibraryAllocators(aaInfo, targets, base, fname, actuals); 
			
			// Next, handle the effects of function pointers (basically, names passed into functions which are then
			// used to select the function to invoke). This logic is coded for each function that accepts function
			// pointers and that is part of the library; functions in the code that do this are handled correctly
			// already, although using very conservative assumptions (allowing room for improvement later...)
			// TODO: Extract this implementation code out
			if (usesFunPointers(fname)) {
				if (fname == "usort", size(actuals) == 2, actual(_,variable_name(avar)) := actuals[0], actual(_,variable_name(funptr)) := actuals[1]) {
					funptrs = { s | /n:assign_var(variable_name(funptr),_,\str(s)) <- body }; // find the literal assigned to the var used in the call
					println("INFO: const props = <funptrs>");
					if (size(funptrs) == 1) {
						// This should be the function we are invoking
						// TODO: Need to make sure this works properly for nested arrays (arrays of arrays of objects, etc)
						println("INFO: Resolved function pointer in call to <fname> in scope <base> using function <getOneFrom(funptrs)>, getting array values for <avar>");
						if ("<base>::<avar>[]" in aaInfo.abstractStore<0>, "global::<getOneFrom(funptrs)>" in aaInfo.signatures) {
							println("INFO: Handling invoke of global::<getOneFrom(funptrs)> with values pointed to by <base>::<avar>[]");
							res = res + mapParams({}, false, base, "global::<getOneFrom(funptrs)>", ["<avar>[]","<avar>[]"]);
						} else if ("<base>::<avar>[]" in aaInfo.abstractStore<0>) {
							println("WARNING: Could not find function global::<getOneFrom(funptrs)> to invoke");
						}
					}
				} else {
					println("Could not process use of function pointer in function <fname>");
				}
			}
			
			if (createsAliases(fname)) {
				// TODO: Handle this
				println("WARNING: We do not yet handle library functions that create aliases");
			}
			
			return res;
		}
		
		str fnameFull = "global::<fname>";
		if (fnameFull in aaInfo.signatures)
			res = mapParams(targets,refTarget,base,fnameFull,actuals);
		else
			println("WARNING: Function <fnameFull> not known, assuming this creates and returns no aliases");
		return res;
	}
	
	rel[str,MemItem] handleFunctionInvoke(str target, bool refTarget, str base, str fname, list[node] actuals) = handleFunctionInvoke({target},refTarget,base,fname,actuals);

	//
	// Get the class that defines a method
	//
	str getDefiningClass(str cname, str mname) {
		fnameFull = "<cname>::<mname>";
		if (fnameFull in aaInfo.signatures)
			return cname;
		if (cname in (aaInfo.ig<1> - cname))
			return getDefiningClass(getOneFrom(invert(aaInfo.ig)[cname]), mname);
		return "";
	}
	
	//
	// Handle propagation of alias information along the call/return edges associated with a call
	// to a method.
	//
	rel[str,MemItem] handleMethodInvoke(set[str] targets, bool refTarget, str base, str tname, str fname, list[node] actuals) {
		rel[str,MemItem] res = { };
		
		// First, get the possible concrete classes assigned to the variable
		set[str] possibleClasses = { cn | objectVal(cn,_) <- aaInfo.abstractStore["<base>::<tname>"] };
		
		// Next, get the possible methods. This has to take inheritance into account. We do not look at
		// public, private, etc, so this is an over-approximation.
		set[str] possibleMethods = { "<dc>::<fname>" | cn <- possibleClasses, dc := getDefiningClass(cn,fname), dc != ""};

		if (size(possibleMethods) == 0) {
			//println("WARNING: No possible methods found for call $<tname>-\><fname> in context <base>");
			aaInfo.unknownMethods = aaInfo.unknownMethods + "<base>::<tname>-\><fname>";
		} else {
			if ("<base>::<tname>-\><fname>" in aaInfo.unknownMethods) aaInfo.unknownMethods = aaInfo.unknownMethods - "<base>::<tname>-\><fname>";
		}
		
		// Now, for each possible method, map the actuals and return value
		for (pm <- possibleMethods) res = res + mapParams(targets, refTarget, base, pm, actuals);

		return res;
	}

	rel[str,MemItem] handleMethodInvoke(str target, bool refTarget, str base, str tname, str fname, list[node] actuals) = handleMethodInvoke({target},refTarget,base,tname,fname,actuals);
	
	//
	// Handle propagation of alias information along the call/return edges associated with a call
	// to a constructor method.
	//
	rel[str,MemItem] handleConstructorInvoke(set[str] targets, str base, str cname, list[node] actuals) {
		rel[str,MemItem] res = { };
		
		if (size(aaInfo.classAliases[cname]) == 1) cname = getOneFrom(aaInfo.classAliases[cname]);
	
		// Here we set a value for $this. For each method visible in the class
		igInvTrans = invert(aaInfo.ig)*;
		//println("INFO: targets = <targets>");
		//println("INFO: looking for class <cname>");
		//println("INFO: all object vals = <{ov | t <- targets, ov:objectVal(_,_) <- aaInfo.abstractStore[t]}>");
		//println("INFO: object vals = <{ov | t <- targets, ov:objectVal(cname,_) <- aaInfo.abstractStore[t]}>");
		//println("INFO: classes = <{c | t <- targets, ov:objectVal(cname,_) <- aaInfo.abstractStore[t], c <- igInvTrans[cname]}>");
		//println("INFO: methods = <{<c,m> | t <- targets, ov:objectVal(cname,_) <- aaInfo.abstractStore[t], c <- igInvTrans[cname], m <- aaInfo.definedMethods[c]}>");
		//println("INFO: in sigs? = <{"<c>::<m>" in aaInfo.signatures | t <- targets, ov:objectVal(cname,_) <- aaInfo.abstractStore[t], c <- igInvTrans[cname], m <- aaInfo.definedMethods[c]}>");
		for (t <- targets, ov:objectVal(cname,_) <- aaInfo.abstractStore[t], c <- igInvTrans[cname], m <- aaInfo.definedMethods[c], "<c>::<m>" in aaInfo.signatures) res = res + < "<c>::<m>::this", ov >;
		 
		// This step handles mapping the return values across. Note that there should be no return in the constructor, at least
		// not of a value, but that doesn't matter -- in the allocation step, we already set the target to have a value
		// of this type.
		if (getDefiningClass(cname,cname) != "") 
			res = res + mapParams(targets, false, base, "<cname>::<cname>", actuals);
		else {
			println("INFO: No constructor found for class <cname>, targets <targets>");
			//println("INFO: Targets = <targets>");
		}
		
		//println("INFO: Added <res>");			
		return res;
	}

	rel[str,MemItem] handleConstructorInvoke(str target, str base, str cname, list[node] actuals) = handleConstructorInvoke({target},base,cname,actuals);

	//
	// Handle propagation of alias information along the call/return edges associated with a call
	// to a top-level (i.e., global) function, where the call could be to any function.
	//
	rel[str,MemItem] handleAnyFunctionInvoke(set[str] targets, bool refTarget, str base, list[node] actuals) {
		rel[str,MemItem] res = { };
		int matched = 0;
		for (fnameFull <- aaInfo.signatures<0>, /global[:][:]/ := fnameFull) {
			if (signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)) := aaInfo.signatures[fnameFull]) {
				// number of params with no defaults -- at least this many actuals need to be present to make this a valid function call
				int minParams = size({ fpi:formal_parameter(_,_,name(_,\default())) <- fpl });
				if (size(actuals) >= minParams) {
					matched = matched + 1;
					res = mapParams(targets,refTarget,base,fnameFull,actuals);
				}
			} else {
				throw "Invalid signature for <fnameFull>: <aaInfo.signatures[fnameFull]>";
			}
		}
		if (matched == 0)
			println("WARNING: No viable functions found, assuming this creates and returns no aliases");
		return res;
	}
	
	rel[str,MemItem] handleAnyFunctionInvoke(str target, bool refTarget, str base, list[node] actuals) = handleAnyFunctionInvoke({target},refTarget,base,actuals);
	
	//
	// Handle propagation of alias information along the call/return edges associated with a call
	// to a top-level (i.e., global) function, where the call could be to any function.
	//
	rel[str,MemItem] handleAnyMethodInvoke(set[str] targets, bool refTarget, str base, str tname, list[node] actuals) {
		rel[str,MemItem] res = { };
		int matched = 0;

		// First, get the possible concrete classes assigned to the variable
		set[str] possibleClasses = { cn | objectVal(cn,_) <- aaInfo.abstractStore["<base>::<tname>"] };

		// Next, get the possible methods. This has to take inheritance into account. We do not look at
		// public, private, etc, so this is an over-approximation.
		set[str] possibleMethods = { "<dc>::<fname>" | cn <- possibleClasses, fname <- aaInfo.definedMethods[cn], dc := getDefiningClass(cn,fname), dc != ""};

		for (fnameFull <- possibleMethods) {
			if (signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)) := aaInfo.signatures[fnameFull]) {
				// number of params with no defaults -- at least this many actuals need to be present to make this a valid function call
				int minParams = size({ fpi:formal_parameter(_,_,name(_,\default())) <- fpl });
				if (size(actuals) >= minParams) {
					matched = matched + 1;
					res = mapParams(targets,refTarget,base,fnameFull,actuals);
				}
			} else {
				throw "Invalid signature for <fnameFull>: <aaInfo.signatures[fnameFull]>";
			}
		}
		if (matched == 0)
			println("WARNING: No viable functions found, assuming this creates and returns no aliases");
		return res;
	}
	
	rel[str,MemItem] handleAnyMethodInvoke(str target, bool refTarget, str base, str tname, list[node] actuals) = handleAnyMethodInvoke({target},refTarget,base,tname,actuals);

	visit(body) {
		// For a return, propagate the type through the return value into the special name @return
		case \return(variable_name(vn)) :
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::@return", namePrefix, vn);
		
		// For a global statement, we propagate changes back and forth between this name and the global
		// version of the name.
		case global(variable_name(vn)) :
			aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "global::<vn>" >;
			
		// Method/function calls that do not assign a return value
		case eval_expr(invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke({}, false, namePrefix, mn, al);

		case eval_expr(invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke({}, false, namePrefix, al);

		case eval_expr(invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke({}, false, namePrefix, tvn, mn, al);

		case eval_expr(invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke({}, false, namePrefix, tvn, al);

		case eval_expr(invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case eval_expr(invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case eval_expr(new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke({}, namePrefix, cn, al); 

		case eval_expr(new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke({}, namePrefix, cn, al);

		// For assignments into var vn, we propagate the memory items assigned to the right-hand-side
		// items into the variable on the left-hand side. For fields, we need to remember to also take
		// from @anyfield, uses in cases where the field name is chosen using indirection.
		case assign_var(variable_name(vn),ref(b),variable_name(vn2)) : { 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, vn2);
			if (b) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "<namePrefix>::<vn2>" >;
		}

		case assign_var(variable_name(vn),ref(b),field_access(variable_name(vn2),field_name(fn2))) : {
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>.<fn2>") + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>.@anyfield");
			if (b) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "<namePrefix>::<vn2>.<fn2>" >;
		}

		case assign_var(variable_name(vn),ref(b),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : {
			for (fn <- allFieldNamesOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>.<fn>");
			if (b) for (fn <- allFieldsOf(namePrefix,vn2)) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", fn >;
		}

		case assign_var(variable_name(vn),ref(b),array_access(variable_name(vn2),idx)) : {
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>[]");
			if (b) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "<namePrefix>::<vn2>[]" >;
		}

		case assign_var(variable_name(vn),ref(b),array_next(variable_name(vn2))) : { 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>[]");
			if (b) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "<namePrefix>::<vn2>[]" >;
		}

		case assign_var(variable_name(vn),ref(b),foreach_get_val(variable_name(vn2),_)) : { 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>", namePrefix, "<vn2>[]");
			if (b) aaInfo.referencePairs = aaInfo.referencePairs + < "<namePrefix>::<vn>", "<namePrefix>::<vn2>[]" >;
		}

		case assign_var(variable_name(vn),ref(b),nd:new(class_name(cn), actuals(al))) : { 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>", namePrefix, cn, al);
		} 

		case assign_var(variable_name(vn),ref(b),nd:new(variable_class(_), actuals(al))) : { 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>", namePrefix, cn, al);
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(), method_name(mn), actuals(al))) : {
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke("<namePrefix>::<vn>", b, namePrefix, mn, al);
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(), variable_method(_), actuals(al))) : {
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke("<namePrefix>::<vn>", b, namePrefix, al);
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) : {
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke("<namePrefix>::<vn>", b, namePrefix, tvn, mn, al);
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) : {
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke("<namePrefix>::<vn>", b, namePrefix, tvn, al);
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) : {
			println("WARNING: We do not currently handle invokes of static methods");
		}

		case assign_var(variable_name(vn),ref(b),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) : {
			println("WARNING: We do not currently handle invokes of static methods");
		}

		// Assignments into variable vn, field fn, e.g., $vn->fn. If vn includes @anyfield, then we also
		// want to assign into that, since @anyfield could also be fn. This essentially makes the analysis
		// field-insensitive worst-case, since this has the effect of merging all the fields, but this
		// PHP feature, using variable variables to determine the field, is rarely used. 
		case assign_field(variable_name(vn),field_name(fn),ref(r),variable_name(vn2)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, vn2);

		case assign_field(variable_name(vn),field_name(fn),ref(r),field_access(variable_name(vn2),field_name(fn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, { "<vn2>.<fn2>", "<vn2>.@anyfield" });

		case assign_field(variable_name(vn),field_name(fn),ref(r),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : 
			for (fn <- allFieldsOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, "<vn2>.<fn>");

		case assign_field(variable_name(vn),field_name(fn),ref(r),array_access(variable_name(vn2),idx)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),field_name(fn),ref(r),array_next(variable_name(vn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),field_name(fn),ref(r),foreach_get_val(variable_name(vn2),_)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(fieldNameSet(vn,fn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),field_name(fn),ref(r),new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke(fieldNameSet(vn,fn), namePrefix, cn, al); 

		case assign_field(variable_name(vn),field_name(fn),ref(r),new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke(fieldNameSet(vn,fn), namePrefix, cn, al);

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke(fieldNameSet(vn,fn), r, namePrefix, mn, al);

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke(fieldNameSet(vn,fn), r, namePrefix, al);

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke(fieldNameSet(vn,fn), r, namePrefix, tvn, mn, al);

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke(fieldNameSet(vn,fn), r, namePrefix, tvn, al);

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case assign_field(variable_name(vn),field_name(fn),ref(r),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		// Same as above, but we need to assign to all fields in variable vn, plus @anyfield.
		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),variable_name(vn2)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, vn2);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),field_access(variable_name(vn2),field_name(fn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, { "<vn2>.<fn>", "<vn2>.@anyfield" });

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : 
			for (fni <- allFieldNamesOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, "<vn2>.<fni>");

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),array_access(variable_name(vn2),idx)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),array_next(variable_name(vn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),foreach_get_val(variable_name(vn2),_)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(allFieldsOf(namePrefix,vn), namePrefix, "<vn2>[]");

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke(allFieldsOf(namePrefix,vn), namePrefix, cn, al); 

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke(allFieldsOf(namePrefix,vn), namePrefix, cn, al);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke(allFieldsOf(namePrefix,vn), r, namePrefix, mn, al);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke(allFieldsOf(namePrefix,vn), r, namePrefix, al);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke(allFieldsOf(namePrefix,vn), r, namePrefix, tvn, mn, al);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke(allFieldsOf(namePrefix,vn), r, namePrefix, tvn, al);

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case assign_field(variable_name(vn),variable_field(variable_name(fn)),ref(r),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		// Assign into the array represented by this name
		case assign_array(variable_name(vn),rv,ref(r),variable_name(vn2)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, vn2);

		case assign_array(variable_name(vn),rv,ref(r),field_access(variable_name(vn2),field_name(fn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, { "<vn2>.<fn2>", "<vn2>.@anyfield" });

		case assign_array(variable_name(vn),rv,ref(r),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : 
			for (fni <- allFieldNamesOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>.<fni>");

		case assign_array(variable_name(vn),rv,ref(r),array_access(variable_name(vn2),idx)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_array(variable_name(vn),rv,ref(r),array_next(variable_name(vn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_array(variable_name(vn),rv,ref(r),foreach_get_val(variable_name(vn2),_)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_array(variable_name(vn),rv,ref(r),new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>[]", namePrefix, cn, al); 

		case assign_array(variable_name(vn),rv,ref(r),new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>[]", namePrefix, cn, al);

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke("<namePrefix>::<vn>[]", r, namePrefix, mn, al);

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke("<namePrefix>::<vn>[]", r, namePrefix, al);

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke("<namePrefix>::<vn>[]", r, namePrefix, tvn, mn, al);

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke("<namePrefix>::<vn>[]", r, namePrefix, tvn, al);

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case assign_array(variable_name(vn),rv,ref(r),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		// If we have variable variables we are sunk -- they could assign to any name in scope. To remain
		// conservative, we need to add a mapping from all vars in scope to whatever the type is, all the
		// while cursing whoever added this stupid feature.
		case assign_var_var(variable_name(_),ref(r),variable_name(vn2)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, vn2);

		case assign_var_var(variable_name(_),ref(r),field_access(variable_name(vn2),field_name(fn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, { "<vn2>.<fn2>", "<vn2>.@anyfield" });

		case assign_var_var(variable_name(_),ref(r),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : 
			for (fni <- allFieldNamesOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, "<vn2>.<fni>");

		case assign_var_var(variable_name(_),ref(r),array_access(variable_name(vn2),idx)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, "<vn2>[]");

		case assign_var_var(variable_name(_),ref(r),array_next(variable_name(vn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, "<vn2>[]");

		case assign_var_var(variable_name(_),ref(r),foreach_get_val(variable_name(vn2),_)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, "<vn2>[]");

		case assign_var_var(variable_name(_),ref(r),new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, cn, al); 

		case assign_var_var(variable_name(_),ref(r),new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke({ "<namePrefix>::<vn>" | vn <- vars }, namePrefix, cn, al);

		case assign_var_var(variable_name(_),ref(r),invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke({ "<namePrefix>::<vn>" | vn <- vars }, r, namePrefix, mn, al);

		case assign_var_var(variable_name(_),ref(r),invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke({ "<namePrefix>::<vn>" | vn <- vars }, r, namePrefix, al);

		case assign_var_var(variable_name(_),ref(r),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke({ "<namePrefix>::<vn>" | vn <- vars }, r, namePrefix, tvn, mn, al);

		case assign_var_var(variable_name(_),ref(r),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke({ "<namePrefix>::<vn>" | vn <- vars }, r, namePrefix, tvn, al);

		case assign_var_var(variable_name(_),ref(r),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case assign_var_var(variable_name(_),ref(r),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		// Assign next is treated just like assign array, above. vn must represent an array,
		// and we record the type assigned into the array as the type of "vn[]". It would
		// probably be best to make this some algebraic data type later, but for now strings
		// are easy...
		case assign_next(variable_name(vn),ref(r),variable_name(vn2)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, vn2);

		case assign_next(variable_name(vn),ref(r),field_access(variable_name(vn2),field_name(fn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, {"<vn2>.<fn2>","<vn2>.@anyfield"});

		case assign_next(variable_name(vn),ref(r),field_access(variable_name(vn2),variable_field(variable_name(fn2)))) : 
			for (fni <- allFieldNamesOf(namePrefix,vn2)) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>.<fni>");

		case assign_next(variable_name(vn),ref(r),array_access(variable_name(vn2),idx)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_next(variable_name(vn),ref(r),array_next(variable_name(vn2))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_next(variable_name(vn),ref(r),foreach_get_val(variable_name(vn2),_)) : 
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<namePrefix>::<vn>[]", namePrefix, "<vn2>[]");

		case assign_array(variable_name(vn),rv,ref(r),new(class_name(cn), actuals(al))) : 
			aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>[]", namePrefix, cn, al); 

		case assign_array(variable_name(vn),rv,ref(r),new(variable_class(_), actuals(al))) : 
			for (cn <- definedClasses) aaInfo.abstractStore = aaInfo.abstractStore + handleConstructorInvoke("<namePrefix>::<vn>[]", namePrefix, cn, al);

		case assign_next(variable_name(vn),ref(r),invoke(target(), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleFunctionInvoke("<namePrefix>::<vn>[]", r, namePrefix, mn, al);

		case assign_next(variable_name(vn),ref(r),invoke(target(), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyFunctionInvoke("<namePrefix>::<vn>[]", r, namePrefix, al);

		case assign_next(variable_name(vn),ref(r),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleMethodInvoke("<namePrefix>::<vn>[]", r, namePrefix, tvn, mn, al);

		case assign_next(variable_name(vn),ref(r),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			aaInfo.abstractStore = aaInfo.abstractStore + handleAnyMethodInvoke("<namePrefix>::<vn>[]", r, namePrefix, tvn, al);

		case assign_next(variable_name(vn),ref(r),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");

		case assign_next(variable_name(vn),ref(r),invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			println("WARNING: We do not currently handle invokes of static methods");
	}
	
	return aaInfo;
}

public AAInfo propagateClassInfo(AAInfo aaInfo, str className, set[str] methodNames) {
	set[str] allFieldsOf(str base, str vn) {
		return { s | s <- aaInfo.abstractStore<0>, startsWith(s, "<base>::<vn>."), isFieldName(s) } + (("<base>::<vn>.@anyfield" in aaInfo.abstractStore<0>) ? { "<base>::<vn>.@anyfield" } : { });
	}

	set[str] allFieldNamesOf(str base, str vn) {
		return { justFieldNameOf(s) | s <- allFieldsOf(base,vn) };
	}

	rel[str,MemItem] deepAssign(str target, str base, str item) {
		rel[str,MemItem] res = { };
		
		// First, assign directly from the target to the base
		res = res + { target } * aaInfo.abstractStore["<base>::<item>"];
		
		// Now, attempt to do the same for arrays
		if ("<base>::<item>[]" in aaInfo.abstractStore<0>) res = res + deepAssign("<target>[]", base, "<item>[]");
		
		// Now, do so for any fields
		for (fn <- allFieldNamesOf(base, item)) res = res + deepAssign("<target>.<fn>", base, "<item>.<fn>");
		
		return res;
	}

	rel[str,MemItem] deepAssign(set[str] targets, str base, str item) {
		rel[str,MemItem] res = { };
		for (t <- targets) res = res + deepAssign(t, base, item);
		return res;
	}
	
	rel[str,MemItem] deepAssign(set[str] targets, str base, set[str] item) {
		rel[str,MemItem] res = { };
		for (t <- targets, i <- item) res = res + deepAssign(t, base, i);
		return res;
	}

	solve(aaInfo) {
		for (mn1 <- methodNames, mn2 <- methodNames, mn1 != mn2) {
			aaInfo.abstractStore = aaInfo.abstractStore + deepAssign("<className>::<mn1>::this", "<className>::<mn2>", "this");
		}
	}
	
	return aaInfo;
}

public AAInfo propagatePairs(AAInfo aaInfo) {
	set[str] allFieldsOf(AAInfo aaInfo, str vn) {
		return { s | s <- aaInfo.abstractStore<0>, startsWith(s, "<vn>."), isFieldName(s) } + (("<vn>.@anyfield" in aaInfo.abstractStore<0>) ? { "<vn>.@anyfield" } : { });
	}

	set[str] allFieldNamesOf(AAInfo aaInfo, str vn) {
		return { justFieldNameOf(s) | s <- allFieldsOf(aaInfo, vn) };
	}

	rel[str,MemItem] deepAssign(AAInfo aaInfo, str target, str item) {
		rel[str,MemItem] res = { };
		
		// First, assign directly from the target to the base
		res = res + { target } * aaInfo.abstractStore[item];
		
		// Now, attempt to do the same for arrays
		if ("<item>[]" in aaInfo.abstractStore<0>) res = res + deepAssign(aaInfo, "<target>[]", "<item>[]");
		
		// Now, do so for any fields
		for (fn <- allFieldNamesOf(aaInfo,item)) res = res + deepAssign(aaInfo, "<target>.<fn>", "<item>.<fn>");
		
		return res;
	}

	solve(aaInfo) {
		for ( < i1, i2 > <- aaInfo.referencePairs ) aaInfo.abstractStore = aaInfo.abstractStore + deepAssign(aaInfo, i1, i2) + deepAssign(aaInfo, i2, i1);
	}
	
	return aaInfo;
}
//
// Handle initializers. These initialize each of the targets to a specific value that does not
// depend on the actuals provided in the call (and thus will be invariant during propagation).
// NOTE: We should handle all allocation here (i.e., any new objVals should be created here),
// but can wire up the constructors, etc below.
//
public rel[str,MemItem] initLibraryAllocators(set[str] targets, str fname, list[node] actuals, int allocationSite) {
	rel[str,MemItem] res = { };
	switch(fname) {
		case "mysql_fetch_object" :
			if (size(actuals) == 1)
				res = res + { < t, objectVal("stdClass", allocationSite) > | t <- targets };
		case "array_keys" :
			// The keys are always scalars, so we can assume that here. This acts as an allocation.
			res = res + { < t, arrayVal() >, < "<t>[]", scalarVal() > | t <- targets };
		case "explode" :
			// The result is always a newly allocated array of strings.
			res = res + { < t, arrayVal() >, < "<t>[]", scalarVal() > | t <- targets };
	}
	return res;
}

//
// Handle allocations that depend on values propagated through the actuals. We need to do this
// during propagation, not during initial allocation, since we don't have any information during
// the latter about what the actuals could hold. Note that the actual object should be created
// in initLibraryAllocators, this should just wire up the constructors, etc, that are used.
//
public rel[str,MemItem] propagateLibraryAllocators(AAInfo aaInfo, set[str] targets, str base, str fname, list[node] actuals) {
	rel[str,MemItem] res = { };
	switch(fname) {
		case "mysql_fetch_object" :
			if (size(actuals) > 1)
				println("WARNING: We do not yet handle mysql_fetch_object with an explicit class name");
		case "str_replace" :
			// The result is of the same type as the third parameter, but this is returned
			// as a new array. So, the allocation site lets us allocate the new array, but
			// the values for each t[] (array contents) are the same as the values for
			// parameter-3[] (array contents of third parameter).
			// TODO: Verify that the replacement is not in-place.
			if (size(actuals) >= 3, actual(_,variable_name(vn)) := actuals[2]) {
				res = res + { < t, arrayVal() > | t <- targets } + 
							{ < "<t>[]", v > | t <- targets, v <- aaInfo.abstractStore["<base>::<vn>[]"] };
			} else if (size(actuals) >= 3) {
				println("WARNING: In call to str_replace, cannot handle a non-variable parameter for $subject");
			} else {
				println("WARNING: In call to str_replace, cannot handle calls with fewer than 3 parameters");
			}
	}
	return res;
}

public bool isFieldName(str s) {
	return /^([^:]+[:][:])+[^\.]+[\.][^\.\[]+$/ := s;
}

public str justFieldNameOf(str s) {
	if (/^[^.]+\.<fname:[^\.\[]+>$/ := s) return fname;
	throw "WARNING: Cannot extract field name from <s>";
}

public bool isFieldNameOf(str target, str s) {
	return startsWith(s, target) && (/^([^:]+[:][:])+[^\.]+[\.][^\.\[]+$/ := s);
}

