@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::AliasGraph

import Node;
import List;
import Set;
import Relation;
import Integer;
import IO;
import String;
import Graph;
import DateTime;

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
// 6. $this could take on the value of an object that is not of the current class because
//    of the way the constraint flow works (for instance, $a = new C1; $a = new C2; now
//    $a can be either, and this means that $this in both C1 and C2 can be either). We
//    should specifically constrain $this to not work in this way, which should lead to
//    a better behavioral approximation.
// 

//
// Abstract memory items. For objects, we track the instantiated class and the allocation site,
// which we use as a shorthand to keep track of unique objects. This is part of the flow
// insensitivity of this analysis -- all objects allocated at a given allocation site are considered
// to be the same object, which could lead to bigger points-to sets.
//
data MemItem = scalarVal() | arrayVal() | objectVal(str className, int allocationSite);

data NamePart = root() | global() | class(str className) | method(str methodName) | field(str fieldName) | var(str varName) | arrayContents() ;
alias NamePath = list[NamePart];

data MemoryNode = mnode(set[MemItem] memItems, map[NamePart, MemoryNode] childNodes);

public MemoryNode makeRootNode() { return mnode({ }, ( ) ); }

public MemoryNode addItems(MemoryNode mNode, NamePath npath, NamePart np, set[MemItem] items) {
	if (size(npath) == 0) {
		if (np in mNode.childNodes) {
			mNode.childNodes[np].memItems += items;
		} else {
			mNode.childNodes[np] = mnode(items, ( ) );
		}
	} else {
		headPart = head(npath);
		if (headPart notin mNode.childNodes) mNode.childNodes[headPart] = mnode({ }, ( ) );
		mNode.childNodes[headPart] = addItems(mNode.childNodes[headPart], tail(npath), np, items);
	}
	return mNode;
}

public MemoryNode addItems(MemoryNode mNode, NamePath npath, NamePart np, MemItem item) = addItems(mNode,npath,np,{ item });

public MemoryNode addItems(MemoryNode mNode, NamePath npath, set[MemItem] items) = addItems(mNode,take(size(npath)-1,npath),last(npath),items);

public MemoryNode addItems(MemoryNode mNode, NamePath npath, MemItem item) = addItems(mNode,take(size(npath)-1,npath),last(npath),{ item });

public set[MemItem] getItems(MemoryNode mNode, NamePath npath) {
	if (size(npath) == 0) throw "Need a valid path";
	
	if (size(npath) == 1, head(npath) in mNode.childNodes) return mNode.childNodes[head(npath)].memItems;
	
	if (size(npath) > 1, head(npath) in mNode.childNodes) return getItems(mNode.childNodes[head(npath)], tail(npath));
	
	return { };
}

public MemoryNode getNode(MemoryNode mNode, NamePath npath) {
	if (size(npath) == 0) throw "Need a valid path";
	
	if (size(npath) == 1, head(npath) in mNode.childNodes) return mNode.childNodes[head(npath)];
	
	if (size(npath) > 1, head(npath) in mNode.childNodes) return getNode(mNode.childNodes[head(npath)], tail(npath));
	
	return { };
}

public bool hasNode(MemoryNode mNode, NamePath npath) {
	if (size(npath) == 1, head(npath) in mNode.childNodes) return true;
	
	if (size(npath) > 1, head(npath) in mNode.childNodes) return hasNode(mNode.childNodes[head(npath)], tail(npath));
	
	return false;
}

public MemoryNode copyItems(MemoryNode mNode, NamePath from, NamePath to) {
	return addItems(mNode, to, getItems(mNode, from));
}

// NOTE: We assume that fromTop exists. We make no assumptions on toTop.
public tuple[MemoryNode,bool] mergeNodes(MemoryNode mNodeTop, NamePath fromTop, NamePath toTop) {
	bool modified = false;
	
	MemoryNode mergeTwoNodes(MemoryNode sourceNode, MemoryNode targetNode) {
		if (!isEmpty(sourceNode.memItems - targetNode.memItems)) {
			targetNode.memItems += sourceNode.memItems;
			modified = true;
		}
		for (ci <- sourceNode.childNodes<0>) {
			if (ci notin targetNode.childNodes) {
				targetNode.childNodes[ci] = mnode({ }, ( ) );
				modified = true;
			}
			targetNode.childNodes[ci] = mergeTwoNodes(sourceNode.childNodes[ci],targetNode.childNodes[ci]);
		}
		return targetNode;
	}
	
	MemoryNode mergeInternal(MemoryNode mNode, NamePath to) {
		if (size(to) == 1) {
			np = head(to);
			if (np notin mNode.childNodes) {
				mNode.childNodes[np] = mnode({ }, ( ) );
				modified = true;
			}
			targetNode = mNode.childNodes[np];
			sourceNode = getNode(mNodeTop, fromTop);
			targetNode = mergeTwoNodes(sourceNode, targetNode);
			mNode.childNodes[np] = targetNode;
	 	} else {
			headPart = head(to);
			if (headPart notin mNode.childNodes) {
				mNode.childNodes[headPart] = mnode({ }, ( ) );
				modified = true;
			}
			mNode.childNodes[headPart] = mergeInternal(mNode.childNodes[headPart], tail(to));
		}
		return mNode;
	}
	
	return < mergeInternal(mNodeTop, toTop), modified >;
}

alias AssignmentFlow = Graph[NamePath];

data CallNode 
	= funcall(str funName, list[node] actuals, NamePath assignTo, bool refCall)
	| funcall(str funName, list[node] actuals, bool refCall)
	
	| funcall(list[node] actuals, NamePath assignTo, bool refCall)
	| funcall(list[node] actuals, bool refCall)
	
	| mcall(NamePath target, str methodName, list[node] actuals, NamePath assignTo, bool refCall)
	| mcall(NamePath target, str methodName, list[node] actuals, bool refCall)

	| mcall(NamePath target, list[node] actuals, NamePath assignTo, bool refCall)
	| mcall(NamePath target, list[node] actuals, bool refCall)

	| smcall(str className, str methodName, list[node] actuals, NamePath assignTo, bool refCall)
	| smcall(str className, str methodName, list[node] actuals, bool refCall)

	| smcall(str classNameName, list[node] actuals, NamePath assignTo, bool refCall)
	| smcall(str classNameName, list[node] actuals, bool refCall)

	| ccall(str className, list[node] actuals, NamePath assignTo, bool refCall)
	| ccall(str className, list[node] actuals, bool refCall)

	| ccall(list[node] actuals, NamePath assignTo, bool refCall)
	| ccall(list[node] actuals, bool refCall)
	;
	
alias CallNodes = set[CallNode];
alias UsedGlobals = rel[NamePath,NamePath];

//
// The difference versions of this type represent the different "stages" of the analysis. The first is when we have the needed information
// to start, but have not computed anything yet. The second is when we have all the signatures and the (very) abstract store, which holds
// the mappings from the various names found in the code to abstract values.
//
data AAInfo 
	= aainfo(set[str] definedClasses, InheritanceGraph ig, FieldsRel definedFields, MethodsRel definedMethods, 
	         rel[NamePath,NamePart] targetFields, rel[str,str] classAliases, rel[str,str] methodAliases)
	| aainfo(set[str] definedClasses, InheritanceGraph ig, FieldsRel definedFields, MethodsRel definedMethods, 
	         MemoryNode abstractStore, map[NamePath,node] signatures, set[str] unknownMethods, 
	         rel[NamePath,NamePart] targetFields, rel[str,str] classAliases, rel[str,str] methodAliases,
	         map[NamePath,CallNodes] callNodes, map[NamePath,AssignmentFlow] assignmentFlows,
	         UsedGlobals globals)
	;

//
// Allocation sites, represented as ints. Each allocation site will be given a unique id.
//
anno int node@asite;

//
// Top-level driver for performing the simple alias analysis on this script.
//
public AAInfo calculateAliases(node scr) {
	dt1 = now();
	
	println("INFO: Marking allocation sites");
	scr = markAllocationSites(scr);

	println("INFO: Calculating the inheritance relation");	
	ig = calculateInheritance(scr);
	
	println("INFO: Calculating the fields relation");	
	frel = calculateFieldsRel(scr, ig);

	println("INFO: Calculating the methods relation");	
	mrel = calculateMethodsRel(scr, ig);
	
	AAInfo aaInfo = aainfo(getDefinedClasses(scr), ig, frel, mrel, { }, { }, { });
	rel[NamePath,MemItem] res = { };
	map[NamePath,node] signatures = ( );
	MemoryNode mNode = makeRootNode();
	map[NamePath,CallNodes] callNodes = ( );
	map[NamePath,AssignmentFlow] assignmentFlows = ( );
	rel[NamePath,NamePath] globals = { };
	
	if (script(bs) := scr) {
		println("INFO: Calculating class aliases");
		aaInfo.classAliases = { <f,t> | /ca:class_alias(\alias(class_name(f)),class_name(t)) <- bs };
		println("INFO: Calculating method aliases");
		aaInfo.methodAliases = { <f,t> | /ma:method_alias(\alias(method_name(f)),method_name(t)) <- bs };
		println("INFO: Calculating variable/field relationships");
		aaInfo.targetFields = aaInfo.targetFields + { < namePrefix + var(vn), (field_name(n) := fn) ? field(n) : field("@anyfield") > | /assign_field(variable_name(vn),fn,_,_,_) <- bs};
				
		// Get allocations and assignment flow from the global scope
		println("INFO: Calculating initial allocations for the global scope");
		gbody = [ b | b <- bs, getName(b) notin { "class_def", "interface_def", "method" }];
		set[str] vars = { vn | b <- gbody, /variable_name(vn) <- b };
		mNode = getInitializingAssignments(aaInfo, mNode, [global()], vars, gbody);
		println("INFO: Calculating assignment flow for the global scope");
		< aflow, cnodes, gs > = extractAssignmentFlow(aaInfo,[global()], gbody);
		callNodes[[global()]] = cnodes;
		assignmentFlows[[global()]] = aflow;
		globals = gs;
		
		// Also get allocations in each global function
		for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- bs) {
			println("INFO: Calculating initial allocations for function <mn>");
			vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
			mNode = getInitializingAssignments(aaInfo, mNode, [global(),method(mn)], vars, b);
			signatures[[global(),method(mn)]] = sig;
			println("INFO: Calculating assignment flow for function <mn>");
			< aflow, cnodes, gs > = extractAssignmentFlow(aaInfo,[global(),method(mn)], b);
			callNodes[[global(),method(mn)]] = cnodes;
			assignmentFlows[[global(),method(mn)]] = aflow;
			if (size(gs) > 0) globals += gs;
		}
		
		// And, get allocations in each method
		for (class_def(_,_,class_name(cn),_,_,members(ml)) <- bs) {
			println("INFO: Processing class <cn>");
			set[NamePart] methodParts = { method(mn) | method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml };
			for (f:method(sig:signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- ml) {
				println("INFO: Calculating initial allocations for method <cn>::<mn>");
				vars = { vn | bi <- b, /variable_name(vn) <- bi } + { vn | name(variable_name(vn),_) <- fpl };
				mNode = getInitializingAssignments(aaInfo, mNode, [class(cn),method(mn)], vars, b);
				signatures[[class(cn),method(mn)]] = sig;
				println("INFO: Calculating assignment flow for method <cn>::<mn>");
				< aflow, cnodes, gs > = extractAssignmentFlow(aaInfo,[class(cn),method(mn)], b);
				callNodes[[class(cn),method(mn)]] = cnodes;
				assignmentFlows[[class(cn),method(mn)]] = aflow;
				if (size(gs) > 0) globals += gs;
			}
		}
		
//		// We now have the initial abstract store, with all allocations, and the signatures, keyed by function or class::method name.
//		// Extend aaInfo with this new information.
		aaInfo = aainfo(aaInfo.definedClasses, aaInfo.ig, aaInfo.definedFields, aaInfo.definedMethods, mNode, signatures, { }, aaInfo.targetFields, aaInfo.classAliases, aaInfo.methodAliases, callNodes, assignmentFlows, globals);

		// First, try a simple propagation. We can make this more exact later...
		println("INFO: Performing context-insensitive alias propagation");
		//aaInfo = contextInsensitivePropagation(aaInfo);
	} else {
		throw "Expected script, got <prettyPrinter(scr)>";
	}
	
	dt2 = now();
	println("INFO: Finished, running time <createDuration(dt1,dt2)>");
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
public MemoryNode getInitializingAssignments(AAInfo aaInfo, MemoryNode mNode, NamePath namePrefix, set[str] vars, list[node] body) {
	set[str] definedClassesForCast = aaInfo.definedClasses + "stdClass";
	
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
			mNode = addItems(mNode, namePrefix + var(vn), objectVal(unaliasClass(cn),nd@asite));

		case assign_var(variable_name(vn),ref(b),nd:new(variable_class(_), actuals(al))) : 
			for (cn <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vn), objectVal(unaliasClass(cn),nd@asite));

		// TODO: We may want to move this into the propagation code, since we will have more information
		// about what we are casting from at that point. 
		case assign_var(variable_name(vn),ref(b),nd:cast(cast("object"),_)) :			
			for (cn <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vn), objectVal(unaliasClass(cn),nd@asite));

		case assign_var(variable_name(vn),ref(b),nd:cast(cast("array"),_)) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());			

		case assign_var(variable_name(vn),ref(b),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, namePrefix + var(vn), mn, al, nd@asite);

		case assign_var(variable_name(vn),ref(b),static_array(_)) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());

		// Assignments into fields. If the field name is known, we presume that vn must be one
		// of the classes that implements this field (including extenders) or an instance of
		// stdClass, which could contain theoretically a field of any name. This is overly
		// conservative, a type inferencer would provide more precise results.
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:new(class_name(cnf), actuals(al))) :
			mNode = addItems(mNode, namePrefix + var(vn) + field(fn), objectVal(unaliasClass(cnf),nd@asite));

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:new(variable_class(_), actuals(al))) : 
			for (cnf <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vn) + field(fn), objectVal(unaliasClass(cnf),nd@asite));
		
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:cast(cast("object"),_)) :			
			for (cnf <- definedClassesForCast) mNode  = addItems(mNode, namePrefix + var(vn) + field(fn), objectVal(unaliasClass(cnf),nd@asite));
			
		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:cast(cast("array"),_)) :
			mNode = addItems(mNode, namePrefix + var(vn) + field(fn), arrayVal());

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, namePrefix + var(vn) + field(fn), mn, al, nd@asite);

		case af:assign_field(variable_name(vn),field_name(fn),ref(r),static_array(_)) :
			mNode = addItems(mNode, namePrefix + var(vn) + field(fn), arrayVal());

		// Assignments into variable fields. We assign into an "@anyfield" field, which we can
		// then use to propagate through to the other fields.
		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:new(class_name(cn), actuals(al))) : 
			mNode = addItems(mNode, namePrefix + var(vn) + field("@anyfield"), objectVal(unaliasClass(cnf),nd@asite));

		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:new(variable_class(_), actuals(al))) :
			for (cnf <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vn) + field("@anyfield"), objectVal(unaliasClass(cnf),nd@asite));
		
		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:cast(cast("object"),_)) : 
			for (cnf <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vn) + field("@anyfield"), objectVal(unaliasClass(cnf),nd@asite));
			
		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:cast(cast("array"),_)) :
			mNode = addItems(mNode, namePrefix + var(vn) + field("@anyfield"), arrayVal());			
		
		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, namePrefix + var(vn) + field("@anyfield"), mn, al, nd@asite);
		
		case af:assign_field(variable_name(vn),variable_field(_),ref(r),nd:static_array(_)) : 
			mNode = addItems(mNode, namePrefix + var(vn) + field("@anyfield"), arrayVal());

		// If we treat a name like an array, assume it is one. All elements in the array are assumed to have
		// the same value.
		case assign_array(variable_name(vn),rv,ref(r),nd:new(class_name(cn), actuals(al))) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));

		case assign_array(variable_name(vn),rv,ref(r),nd:new(variable_class(_), actuals(al))) : {
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());
			for (cn <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));
		}
		
		case assign_array(variable_name(vn),rv,ref(r),nd:cast(cast("object"),_)) : {			
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());
			for (cn <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));
		}
			
		case assign_array(variable_name(vn),rv,ref(r),nd:cast(cast("array"),_)) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), arrayVal());

		case assign_array(variable_name(vn),rv,ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			mNode = addItems(namePrefix + var(vn), arrayVal());
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, namePrefix + var(vn) + arrayContents(), mn, al, nd@asite);
		}

		case assign_array(variable_name(vn),rv,ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());

		case assign_array(variable_name(vn),rv,ref(r),static_array(_)) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), arrayVal());

		case assign_array(variable_name(vn),rv,ref(r),_) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());

		// If we have variable variables we are sunk -- they could assign to any name in scope. To remain
		// conservative, we need to add a mapping from all vars in scope to whatever the type is, all the
		// while cursing whoever added this stupid feature.
		case assign_var_var(variable_name(vn),ref(r),nd:new(class_name(cn), actuals(al))) : {
			for (vni <- vars) mNode = addItems(mNode, namePrefix + var(vni), objectVal(unaliasClass(cn),nd@asite));
		}

		case assign_var_var(variable_name(vn),ref(r),nd:new(variable_class(_), actuals(al))) : {
			for (vni <- vars, cn <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vni), objectVal(unaliasClass(cn),nd@asite));
		} 
		
		case assign_var_var(variable_name(vn),ref(r),nd:cast(cast("object"),_)) : {
			for (vni <- vars, cn <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vni), objectVal(unaliasClass(cn),nd@asite));
		}			

		case assign_var_var(variable_name(vn),ref(r),nd:cast(cast("array"),_)) : {
			for (vni <- vars, cn <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vni), arrayVal());
		}
			
		case assign_var_var(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, {namePrefix + var(vni) | vni <- vars}, mn, al, nd@asite);
		}

		case assign_var_var(variable_name(vn),ref(r),static_array(_)) : {
			for (vni <- vars) mNode = addItems(mNode, namePrefix + var(vni), arrayVal());
		}
			
		// Assign next is treated just like assign array, above. 
		case assign_next(variable_name(vn),ref(r),nd:new(class_name(cn), actuals(al))) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));

		case assign_next(variable_name(vn),ref(r),nd:new(variable_class(_), actuals(al))) : {
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());
			for (cn <- aaInfo.definedClasses) mNode = addItems(mNode, namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));
		}
		
		case assign_next(variable_name(vn),ref(r),nd:cast(cast("object"),_)) : {			
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());
			for (cn <- definedClassesForCast) mNode = addItems(mNode, namePrefix + var(vn) + arrayContents(), objectVal(unaliasClass(cn),nd@asite));
		}
			
		case assign_next(variable_name(vn),ref(r),nd:cast(cast("array"),_)) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), arrayVal());

		case assign_next(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) : {
			mNode = addItems(namePrefix + var(vn), arrayVal());
			if (hasSummary(mn), allocatorFun(mn))
				mNode = initLibraryAllocators(mNode, namePrefix + var(vn) + arrayContents(), mn, al, nd@asite);
		}

		case assign_next(variable_name(vn),ref(r),nd:invoke(target(), method_name(mn), actuals(al))) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());

		case assign_next(variable_name(vn),ref(r),static_array(_)) :
			mNode = addItems(addItems(mNode, namePrefix + var(vn), arrayVal()), namePrefix + var(vn) + arrayContents(), arrayVal());

		case assign_next(variable_name(vn),ref(r),_) :
			mNode = addItems(mNode, namePrefix + var(vn), arrayVal());
	}
	
	return mNode;
}

//
// Extract the assignment flow graph (i.e., which names, field accesses, etc, are assigned into which names, field lookups, etc)
// as well as individual call nodes. The first piece of information is used for the intraprocedural part of the analysis, the
// second provides the hook needed for hte interprocedural analysis.
//
public tuple[AssignmentFlow aflow, CallNodes callNodes, UsedGlobals globals] extractAssignmentFlow(AAInfo aaInfo, NamePath namePrefix, list[node] body) {
	AssignmentFlow aflow = { };
	CallNodes callNodes = { };
	UsedGlobals usedGlobals = { };
	
	visit(body) {
		//
		// For a return, propagate the type through the return value into the special name @return
		//
		case \return(variable_name(vn)) :
			aflow += < namePrefix + var(vn), namePrefix + var("@return") >;

		//
		// For global, the local and global versions of the name will flow into one another
		//		
		case global(variable_name(vn)) : {
			aflow += { < namePrefix + var(vn), [ global(), var(vn) ] >, < [ global(), var(vn) ], namePrefix + var(vn) > };
			usedGlobals += < namePrefix, [ global(), var(vn) ] >;
		}
			
		//
		// Method/function calls that do not assign a return value
		//
		case eval_expr(invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, false);

		case eval_expr(invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, false);

		case eval_expr(invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, false);

		case eval_expr(invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, false);

		case eval_expr(invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, false);

		case eval_expr(invoke(target(class_name(cn)), variable_method(variable_name(mn)), actuals(al))) :
			callNodes += smcall(cn, al, false);

		case eval_expr(new(class_name(cn), actuals(al))) : 
			callNodes += ccall(cn, al, false);

		case eval_expr(new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, false);

		//
		// Standard assignments into variables. The cases handle the different kinds
		// of sources: variables, field accesses, array accesses, method invocations,
		// etc, with (at least one) case for each.
		//
		case assign_var(variable_name(vn),ref(b),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var(vn) >; 
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) >;
		}

		case assign_var(variable_name(vn),ref(b),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var(vn) >; 
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_var(variable_name(vn),ref(b),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var(vn) >;
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) + field("@anyfield") >;
		}

		case assign_var(variable_name(vn),ref(b),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) >; 
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var(variable_name(vn),ref(b),array_next(variable_name(vn2))) : { 
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) >; 
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var(variable_name(vn),ref(b),foreach_get_val(variable_name(vn2),_)) : { 
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) >; 
			if (b) aflow += < namePrefix + var(vn), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var(variable_name(vn),ref(b),nd:new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),nd:new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var(vn), b);

		case assign_var(variable_name(vn),ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var(vn), b);

		//
		// Same as above, but the target is a field $vn->fn.
		//
		case assign_field(variable_name(vn),field_name(fn),ref(r),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var(vn) + field(fn) >; 
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) >;
		}

		case assign_field(variable_name(vn),field_name(fn),ref(r),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var(vn) + field(fn) >; 
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_field(variable_name(vn),field_name(fn),ref(r),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var(vn) + field(fn) >;
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) + field("@anyfield") >;
		}
		
		case assign_field(variable_name(vn),field_name(fn),ref(r),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field(fn) >; 
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_field(variable_name(vn),field_name(fn),ref(r),array_next(variable_name(vn2))) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field(fn) >; 
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_field(variable_name(vn),field_name(fn),ref(r),foreach_get_val(variable_name(vn2),_)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field(fn) >; 
			if (r) aflow += < namePrefix + var(vn) + field(fn), namePrefix + var(vn2) + arrayContents() >;
		}
		
		case assign_field(variable_name(vn),field_name(fn),ref(b),nd:new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),nd:new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var(vn) + field(fn), b);

		case assign_field(variable_name(vn),field_name(fn),ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var(vn) + field(fn), b);

		//
		// Same as above, but the target is a variable field $vn->$fn (or whatever the syntax actually is). In
		// this case, the target could be any field on $vn, so we use a special field, @anyfield, the same field
		// used in the variable field source cases above.
		//
		case assign_field(variable_name(vn),variable_field(_),ref(r),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var(vn) + field("@anyfield") >; 
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) >;
		}

		case assign_field(variable_name(vn),variable_field(_),ref(r),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var(vn) + field("@anyfield") >; 
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_field(variable_name(vn),variable_field(_),ref(r),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var(vn) + field("@anyfield") >;
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) + field("@anyfield") >;
		}
		
		case assign_field(variable_name(vn),variable_field(_),ref(r),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field("@anyfield") >; 
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_field(variable_name(vn),variable_field(_),ref(r),array_next(variable_name(vn2))) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field("@anyfield") >; 
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_field(variable_name(vn),variable_field(_),ref(r),foreach_get_val(variable_name(vn2),_)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + field("@anyfield") >; 
			if (r) aflow += < namePrefix + var(vn) + field("@anyfield"), namePrefix + var(vn2) + arrayContents() >;
		}
		
		case assign_field(variable_name(vn),variable_field(_),ref(b),nd:new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),nd:new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var(vn) + field("@anyfield"), b);

		case assign_field(variable_name(vn),variable_field(_),ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var(vn) + field("@anyfield"), b);

		//
		// Same as above, but the target is an array $vn[idx]
		//
		case assign_array(variable_name(vn),rv,ref(b),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) >;
		}

		case assign_array(variable_name(vn),rv,ref(b),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_array(variable_name(vn),rv,ref(b),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var(vn) + arrayContents() >;
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + field("@anyfield") >;
		}
		
		case assign_array(variable_name(vn),rv,ref(b),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_array(variable_name(vn),rv,ref(b),array_next(variable_name(vn2))) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_array(variable_name(vn),rv,ref(b),foreach_get_val(variable_name(vn2),_)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_array(variable_name(vn),rv,ref(b),new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_array(variable_name(vn),rv,ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var(vn) + arrayContents(), b);

		//
		// Same as above, but the target is a variable variable, $$x = something
		//
		case assign_var_var(variable_name(_),ref(b),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var("@anyvar") >;
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) >;
		}

		case assign_var_var(variable_name(_),ref(b),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var("@anyvar") >; 
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_var_var(variable_name(_),ref(b),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var("@anyvar") >;
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) + field("@anyfield") >;
		}

		case assign_var_var(variable_name(_),ref(b),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var("@anyvar") >; 
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var_var(variable_name(_),ref(b),array_next(variable_name(vn2))) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var("@anyvar") >; 
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var_var(variable_name(_),ref(b),foreach_get_val(variable_name(vn2),_)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var("@anyvar") >; 
			if (b) aflow += < namePrefix + var("@anyvar"), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_var_var(variable_name(_),ref(b),new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var("@anyvar"), b);

		case assign_var_var(variable_name(_),ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var("@anyvar"), b);

		//
		// Same as above, but the target is an array $vn[]
		//
		case assign_next(variable_name(vn),ref(b),variable_name(vn2)) : {
			aflow += < namePrefix + var(vn2), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) >;
		}

		case assign_next(variable_name(vn),ref(b),field_access(variable_name(vn2),field_name(fn2))) : {
			aflow += < namePrefix + var(vn2) + field(fn2), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + field(fn2) >;
		}

		case assign_next(variable_name(vn),ref(b),field_access(variable_name(vn2),variable_field(_))) : {
			aflow += < namePrefix + var(vn2) + field("@anyfield"), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + field("@anyfield") >;
		}
		
		case assign_next(variable_name(vn),ref(b),array_access(variable_name(vn2),idx)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_next(variable_name(vn),ref(b),array_next(variable_name(vn2))) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_next(variable_name(vn),ref(b),foreach_get_val(variable_name(vn2),_)) : {
			aflow += < namePrefix + var(vn2) + arrayContents(), namePrefix + var(vn) + arrayContents() >; 
			if (b) aflow += < namePrefix + var(vn) + arrayContents(), namePrefix + var(vn2) + arrayContents() >;
		}

		case assign_next(variable_name(vn),ref(b),new(class_name(cn), actuals(al))) :
			callNodes += ccall(cn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),new(variable_class(_), actuals(al))) : 
			callNodes += ccall(al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(), method_name(mn), actuals(al))) :
			callNodes += funcall(mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(), variable_method(_), actuals(al))) :
			callNodes += funcall(al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), method_name(mn), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(variable_name(tvn)), variable_method(_), actuals(al))) :
			callNodes += mcall(namePrefix + var(tvn), al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(class_name(cn)), method_name(mn), actuals(al))) :
			callNodes += smcall(cn, mn, al, namePrefix + var(vn) + arrayContents(), b);

		case assign_next(variable_name(vn),ref(b),invoke(target(class_name(cn)), variable_method(_), actuals(al))) :
			callNodes += smcall(cn, al, namePrefix + var(vn) + arrayContents(), b);
	}

	// Handle @anyfield in the assignment flow -- @anyfield sources will be turned into sources from all
	// fields, while @anyfield targets will become targets in all fields. This also has the effect of
	// removing any fields named @anyfield so we don't have to consider them during propagation.
	aflowFrom = { < s, t > | < s, t > <- aflow, field("@anyfield") := last(s) };
	aflowTo = { < s, t > | < s, t > <- aflow, field("@anyfield") := last(t) };
	if (size(aflowFrom+aflowTo) > 0) {
		println("INFO: Linking uses of @anyfield to actual fields");
		aflowNewFrom = { < p + f, t > | < s, t > <- aflowFrom, p := take(size(s)-1,s), f <- aaInfo.targetFields[p], f != field("@anyfield") }; 
		aflowNewTo = { < s, p + f > | < s, t > <- aflowFrom, p := take(size(t)-1,t), f <- aaInfo.targetFields[p], f != field("@anyfield") }; 
		aflow = aflow - (aflowFrom + aflowTo) + (aflowNewFrom + aflowNewTo);
	}
	
	// TODO: Also handle @anyfield in the various call nodes
			
	// TODO: We should do the same for @anyvar, but that will be very expensive and will make the
	// analysis very imprecise.
	
	// TODO: We should also do something for @varargs. This also involves handling the
	// functions that work with the additional arguments.
	return < aflow, callNodes, usedGlobals >;
}

//
// Handle initializers. These initialize each of the targets to a specific value that does not
// depend on the actuals provided in the call (and thus will be invariant during propagation).
// NOTE: We should handle all allocation here (i.e., any new objVals should be created here),
// but can wire up the constructors, etc below.
//
public MemoryNode initLibraryAllocators(MemoryNode mNode, set[NamePath] targets, str fname, list[node] actuals, int allocationSite) {
	switch(fname) {
		case "mysql_fetch_object" :
			if (size(actuals) == 1)
				for (t <- targets) mNode = addItems(mNode, t, objectVal("stdClass", allocationSite));
		case "array_keys" :
			// The keys are always scalars, so we can assume that here. This acts as an allocation.
			for (t <- targets) mNode = addItems(mNode, t, arrayVal());
		case "explode" :
			// The result is always a newly allocated array of strings.
			for (t <- targets) mNode = addItems(mNode, t, arrayVal());
		case "str_replace" :
			for (t <- targets) mNode = addItems(mNode, t, arrayVal());
	}
	return mNode;
}

public MemoryNode initLibraryAllocators(MemoryNode mNode, NamePath target, str fname, list[node] actuals, int allocationSite) {
	return initLibraryAllocators(mNode, {target},fname,actuals,allocationSite);
}


alias ActualsInfo = list[tuple[bool isRef, bool hasName, str aname, node anode]];

public AAInfo contextInsensitivePropagation(AAInfo aaInfo) {
	// Form an overall assignment flow graph by collapsing all the individual graphs into one.
	AssignmentFlow af = { aaInfo.assignmentFlows[afn] | afn <- aaInfo.assignmentFlows<0> };
	
	//
	// Given a named function, a call site, and the actual parameters, add assignment flows
	// from the actuals to the formals. Also add an assignment flow back from the return
	// value of the function to each assignment target (we can have multiple, for instance
	// when the target is a variable variable). If we have both a reference assignment and
	// a reference return, we create a flow that also goes from each assignment target into
	// the return value.
	// 
	void mapParams(NamePath funName, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		if (signature(_,_,_,_,_,_,pass_rest_by_ref(pbr),return_by_ref(rr),_,parameters(fpl)) := aaInfo.signatures[funName]) {
			list[str] paramNames = [ fpn | formal_parameter(_,_,name(variable_name(fpn),_)) <- fpl ];
			list[bool] paramIsRef = [ iref | formal_parameter(_,ref(iref),_) <- fpl ];
			int idx = 0;
			
			// First, map between formals and actuals while we have both formals and actuals to process.
			// Note that we only deal with actuals that have names, since we don't really care about
			// flows from literals.
			// TODO: See if we need to do anything about pass_rest_by_ref, probably only for varargs...
			while (idx < min(size(paramNames),size(actuals)), actuals[idx].hasName) {
				af += < callSite + var(actuals[idx].aname), funName + var(paramNames[idx]) > ;
				if (actuals[idx].isRef || paramIsRef[idx]) {
					af += < funName + var(paramNames[idx]), callSite + var(actuals[idx].aname) >; 
				}
				idx = idx + 1;
			}

			// Second, if we have more actuals than formals, map them all to a variable called @varargs
			// TODO: We need to add support when building the flow to account for uses of the
			// functions that allow reading the arguments used in varargs functions.
			while (idx < size(actuals), actuals[idx].hasName) {
				af += < callSite + var(actuals[idx].aname), funName + var("@varargs") >;
				if (actuals[idx].isRef || pbr) af += < funName + var("@varargs"), callSite + var(actuals[idx].aname) >;
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
			for (t <- assignmentTargets) af += < funName + var("@return"), t >;

			// Fifth, iIf we return by reference, add that to the flow as well 
			if (rr && refAssign) for (t <- assignmentTargets) af += < t, funName + var("@return") >; 
		} else {
			throw "Invalid signature for <funName>: <aaInfo.signatures[funName]>";
		}
	}
	
	//
	// Handle allocations that depend on values propagated through the actuals. We need to do this
	// during propagation, not during initial allocation, since we don't have any information during
	// the latter about what the actuals could hold. Note that the actual object should be created
	// in initLibraryAllocators, this should just wire up the constructors, etc, that are used.
	//
	void propagateLibraryAllocators(str funName, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		switch(funName) {
			case "mysql_fetch_object" :
				if (size(actuals) > 1) println("WARNING: We do not yet handle mysql_fetch_object with an explicit class name");
			case "str_replace" :
				// The result is of the same type as the third parameter, but this is returned
				// as a new array. So, the allocation site lets us allocate the new array, but
				// the values for each t[] (array contents) are the same as the values for
				// parameter-3[] (array contents of third parameter).
				// TODO: Verify that the replacement is not in-place.
				if (size(actuals) >= 3, actuals[2].hasName) {
					for (t <- assignmentTargets) {
						af += < callSite + var(actuals[2].aname), t >;
						if (refAssign) af += < t, callSite + var(actuals[2].aname) >;
					} 
				} else if (size(actuals) >= 3) {
					println("WARNING: In call to str_replace, cannot handle a non-variable parameter for $subject");
				} else {
					println("WARNING: In call to str_replace, cannot handle calls with fewer than 3 parameters");
				}
		}
	}

	//
	// Handle invocations of functions for which we have function summaries, i.e., library
	// functions. In some cases we need to handle these on a case by case basis.
	//
	// TODO: Extract the handling out into closures that can be put into a map; this way we
	// can at least move the code elsewhere.
	//
	void invokeSummaryFunction(str funName, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		// First, if this function propagates allocation information, do so
		if (allocatorFun(funName)) propagateLibraryAllocators(funName, callSite, assignmentTargets, refAssign, actuals); 
		
		// Next, handle the effects of function pointers (basically, names passed into functions which are then
		// used to select the function to invoke). This logic is coded for each function that accepts function
		// pointers and that is part of the library; functions in the code that do this are handled correctly
		// already, although using very conservative assumptions (allowing room for improvement later...)
		// TODO: Extract this implementation code out
		if (usesFunPointers(funName)) {
			if (funName == "usort", size(actuals) == 2, \str(funptr) := actuals[1].anode) {
				if ([global(),method(funptr)] in aaInfo.signatures) {
					mapParams([global(),method(funptr)], callSite, assignmentTargets, refAssign, [actuals[0],actuals[0]]); 
				} else {
					println("WARNING: Could not find function <funptr> to invoke");
				}
			} else {
				println("Could not process use of function pointer in function <funName>");
			}
		}
		
		if (createsAliases(funName)) {
			// TODO: Handle this
			println("WARNING: We do not yet handle library functions that create aliases");
		}
		
	}	

	//
	// Add needed assignment flows for invoked functions. The summary function logic dispatches
	// out to invokeSummaryFunction, which handles invocations of library functions.
	// 
	void invokeFunction(str funName, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		if (hasSummary(funName)) {
			invokeSummaryFunction(funName, callSite, assignmentTargets, refAssign, actuals); 
		} else if ([global(),method(funName)] in aaInfo.signatures) {
			mapParams([global(),method(funName)], callSite, assignmentTargets, refAssign, actuals);
		} else {
			println("WARNING: Function <funName> not known, assuming this creates and returns no aliases");
		}
	}
	
	void invokeFunction(str funName, NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeFunction(funName, callSite, {assignmentTarget}, refAssign, actuals);
	}

	//
	// Helper function -- get the first class up the inheritance chain that defines method mname
	//		
	str getDefiningClass(str cname, str mname) {
		if ([class(cname),method(mname)] in aaInfo.signatures) return cname;
		if (cname in (aaInfo.ig<1> - cname)) return getDefiningClass(getOneFrom(invert(aaInfo.ig)[cname]), mname);
		return "";
	}

	//
	// Add needed assignment flows for invoked methods. We have logic here to figure out which method will be invoked.
	// If we cannot find a method, we record this as a possible error. It isn't actually an error until we get to the
	// end and have unresolved functions, since it is possible that we don't get the invoker (i.e., this) until a
	// later iteration during propagation. We also take this opportunity to map from the invoker to $this,
	// and to make the recipricol mapping. 
	//
	void invokeMethod(str methodName, NamePath invoker, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		set[str] possibleClasses = { cn | objectVal(cn,_) <- getItems(aaInfo.abstractStore, invoker) };
		set[NamePath] possibleMethods = { [class(dc),method(methodName)] | cn <- possibleClasses, dc := getDefiningClass(cn,methodName), dc != ""};

		if (size(possibleMethods) == 0) {
			aaInfo.unknownMethods = aaInfo.unknownMethods + "<invoker>-\><methodName>";
		} else {
			if ("<invoker>-\><methodName>" in aaInfo.unknownMethods) aaInfo.unknownMethods = aaInfo.unknownMethods - "<invoker>-\><methodName>";
			for (pm <- possibleMethods) {
				mapParams(pm, callSite, assignmentTargets, refAssign, actuals);
				af += { < invoker, pm + var("this") >, < pm + var("this"), invoker > };
			}
		}
	}

	void invokeMethod(str methodName, NamePath invoker, NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeMethod(methodName, invoker, callSite, {assignmentTarget}, refAssign, actuals);
	}
	
	//
	// Add needed assignment flows for invoked static methods. We have logic here to figure out which method will be invoked.
	// If we cannot find a method, we record this as a possible error. It isn't actually an error until we get to the
	// end and have unresolved functions, since it is possible that we don't get the invoker (i.e., this) until a
	// later iteration during propagation. We also take this opportunity to map from the invoker to $this,
	// and to make the recipricol mapping. 
	//
	void invokeStaticMethod(str methodName, str className, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		set[str] possibleClasses = { className };
		set[NamePath] possibleMethods = { [class(dc),method(methodName)] | cn <- possibleClasses, dc := getDefiningClass(cn,methodName), dc != ""};

		if (size(possibleMethods) == 0) {
			aaInfo.unknownMethods = aaInfo.unknownMethods + "<className>::<methodName>";
		} else {
			if ("<className>::<methodName>" in aaInfo.unknownMethods) aaInfo.unknownMethods = aaInfo.unknownMethods - "<className>::<methodName>";
			for (pm <- possibleMethods) mapParams(pm, callSite, assignmentTargets, refAssign, actuals);
		}
	}

	void invokeStaticMethod(str methodName, str className, NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeStaticMethod(className, methodName, callSite, {assignmentTarget}, refAssign, actuals);
	}

	//
	// Add needed assignment flows for invoked constructors. This logic is similar to the logic given
	// above for methods, except that the method name is inferred (it is the same as the class name).
	// As above, we also map to and from $this, but instead of the invoker we use the assignment
	// targets which are given the newly-created object.
	//
	void invokeConstructor(str className, NamePath callSite, set[NamePath] assignmentTargets, ActualsInfo actuals) {
		// This accounts for class aliases, which crop up occasionally in the code because of the MIR transformations.
		// If we have a class alias, we need to make sure we are using the correct version of the name.
		if (size(aaInfo.classAliases[className]) == 1) className = getOneFrom(aaInfo.classAliases[className]);
		
		if (getDefiningClass(className,className) != "") { 
			mapParams([class(className),method(className)], callSite, assignmentTargets, false, actuals);
			for (t <- assignmentTargets) af += { < t, [class(className),method(className),var("this")] >, < [class(className),method(className),var("this")], t > };
		}
	}

	void invokeConstructor(str className, NamePath callSite, NamePath assignmentTarget, ActualsInfo actuals) {
		invokeConstructor(className, callSite, {assignmentTarget}, actuals);
	}

	//
	// Add needed assignment flows for invocations that can invoke any function in global scope. We try to
	// limit this to only functions that could sensibly be called, defined here as functions that are given
	// at least the minimum number of parameters that they need.
	//
	void invokeAnyFunction(NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		int matched = 0;
		for ([global(),method(fn)] <- aaInfo.signatures<0>, signature(_,_,_,_,_,_,_,_,_,parameters(fpl)) := aaInfo.signatures[[global(),method(fn)]]) {
			int minParams = size({ fpi:formal_parameter(_,_,name(_,\default())) <- fpl });
			if (size(actuals) >= minParams) {
				matched = matched + 1;
				mapParams([global(),method(fn)], callSite, assignmentTargets, refAssign, actuals);
			}
		}
		
		if (matched == 0)
			println("WARNING: No viable functions found, assuming this creates and returns no aliases");
	}
	
	void invokeAnyFunction(NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeAnyFunction(callSite,{assignmentTarget},refAssign,actuals);
	}
	
	//
	// Same as above, but handles invocations to methods, not functions. This is then a mix of the code
	// for handling calls to unknown functions and the code from invoking methods. Given the concrete
	// class, we find all the methods that we could invoke. This includes inherited methods. We then
	// check each to see if we have enough parameters.
	//
	void invokeAnyMethod(NamePath invoker, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		str getDefiningClass(str cname, str mname) {
			if ([class(cname),method(mname)] in aaInfo.signatures) return cname;
			if (cname in (aaInfo.ig<1> - cname)) return getDefiningClass(getOneFrom(invert(aaInfo.ig)[cname]), mname);
			return "";
		}

		int matched = 0;

		set[str] possibleClasses = { cn | objectVal(cn,_) <- getItems(aaInfo.abstractStore, invoker) };
		// Why (invert(aaInfo.ig)*)[cn]? inverting gives us a relation from sub to superclasses; transitive
		// closure gives all the superclasses on the chain; subscripting then gives us all possible
		// superclasses. We then get back all the methods that could be called on an instance of this
		// class, including the inherited methods.
		set[NamePath] possibleMethods = { [class(dc),method(methodName)] | cn <- possibleClasses, methodName <- aaInfo.definedMethods[(invert(aaInfo.ig)*)[cn]], dc := getDefiningClass(cn,methodName), dc != ""};

		for (pm <- possibleMethods, signature(_,_,_,_,_,_,_,_,_,parameters(fpl)) := aaInfo.signatures[pm]) {
			int minParams = size({ fpi:formal_parameter(_,_,name(_,\default())) <- fpl });
			if (size(actuals) >= minParams) {
				matched = matched + 1;
				mapParams(pm, callSite, assignmentTargets, refAssign, actuals);
				af += { < invoker, pm + var("this") >, < pm + var("this"), invoker > };
			}
		}

		if (matched == 0)
			println("WARNING: No viable methods found, assuming this creates and returns no aliases");
	}
	
	void invokeAnyMethod(NamePath invoker, NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeAnyMethod(invoker, callSite, {assignmentTarget}, refAssign, actuals);
	}

	//
	// Same as above, but handles invocations to methods, not functions. This is then a mix of the code
	// for handling calls to unknown functions and the code from invoking methods. Given the concrete
	// class, we find all the methods that we could invoke. This includes inherited methods. We then
	// check each to see if we have enough parameters.
	//
	void invokeAnyStaticMethod(str className, NamePath callSite, set[NamePath] assignmentTargets, bool refAssign, ActualsInfo actuals) {
		str getDefiningClass(str cname, str mname) {
			if ([class(cname),method(mname)] in aaInfo.signatures) return cname;
			if (cname in (aaInfo.ig<1> - cname)) return getDefiningClass(getOneFrom(invert(aaInfo.ig)[cname]), mname);
			return "";
		}

		int matched = 0;

		set[str] possibleClasses = { className };
		// Why (invert(aaInfo.ig)*)[cn]? inverting gives us a relation from sub to superclasses; transitive
		// closure gives all the superclasses on the chain; subscripting then gives us all possible
		// superclasses. We then get back all the methods that could be called on an instance of this
		// class, including the inherited methods.
		set[NamePath] possibleMethods = { [class(dc),method(methodName)] | cn <- possibleClasses, methodName <- aaInfo.definedMethods[(invert(aaInfo.ig)*)[cn]], dc := getDefiningClass(cn,methodName), dc != ""};

		for (pm <- possibleMethods, signature(_,_,_,_,_,_,_,_,_,parameters(fpl)) := aaInfo.signatures[pm]) {
			int minParams = size({ fpi:formal_parameter(_,_,name(_,\default())) <- fpl });
			if (size(actuals) >= minParams) {
				matched = matched + 1;
				mapParams(pm, callSite, assignmentTargets, refAssign, actuals);
			}
		}

		if (matched == 0)
			println("WARNING: No viable methods found for invoke of any static on <className> in context <callSite>, assuming this creates and returns no aliases");
	}
	
	void invokeAnyStaticMethod(str className, NamePath callSite, NamePath assignmentTarget, bool refAssign, ActualsInfo actuals) {
		invokeAnyStaticMethod(className, callSite, {assignmentTarget}, refAssign, actuals);
	}

	void processCall(NamePath callSite, CallNode cn) {
		ActualsInfo createActualsInfo(list[node] actuals) {
			return [ < b, (variable_name(_) := i), ((variable_name(vn) := i) ? vn : ""), i > | a:actual(ref(b), i) <- actuals ];
		}
		
		switch(cn) {
			case funcall(str funName, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeFunction(funName, callSite, assignTo, refCall, createActualsInfo(actuals));
			case funcall(str funName, list[node] actuals, bool refCall) :
				invokeFunction(funName, callSite, { }, refCall, createActualsInfo(actuals));
			case funcall(list[node] actuals, NamePath assignTo, bool refCall) :
				invokeAnyFunction(callSite, assignTo, refCall, createActualsInfo(actuals));
			case funcall(list[node] actuals, bool refCall) :
				invokeAnyFunction(callSite, { }, refCall, createActualsInfo(actuals));
			case mcall(NamePath target, str methodName, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeMethod(methodName, target, callSite, assignTo, refCall, createActualsInfo(actuals));
			case mcall(NamePath target, str methodName, list[node] actuals, bool refCall) :
				invokeMethod(methodName, target, callSite, { }, refCall, createActualsInfo(actuals));
			case mcall(NamePath target, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeAnyMethod(target, callSite, assignTo, refCall, createActualsInfo(actuals));
			case mcall(NamePath target, list[node] actuals, bool refCall) :
				invokeAnyMethod(target, callSite, { }, refCall, createActualsInfo(actuals));
			case smcall(str className, str methodName, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeStaticMethod(className, methodName, callSite, assignTo, refCall, createActualsInfo(actuals));
			case smcall(str className, str methodName, list[node] actuals, bool refCall) :
				invokeStaticMethod(className, methodName, callSite, { }, refCall, createActualsInfo(actuals));
			case smcall(str className, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeAnyStaticMethod(className, callSite, assignTo, refCall, createActualsInfo(actuals));
			case smcall(str className, list[node] actuals, bool refCall) :
				invokeAnyStaticMethod(className, callSite, { }, refCall, createActualsInfo(actuals));
			case ccall(str className, list[node] actuals, NamePath assignTo, bool refCall) :
				invokeConstructor(className, callSite, assignTo, createActualsInfo(actuals));
			case ccall(str className, list[node] actuals, bool refCall) :
				invokeConstructor(className, callSite, { }, createActualsInfo(actuals));
			case ccall(list[node] actuals, NamePath assignTo, bool refCall) :
				println("WARNING: We cannot invoke arbitrary constructors yet");
			case ccall(list[node] actuals, bool refCall) :
				println("WARNING: We cannot invoke arbitrary constructors yet");
		}
	}
		
	// Perform an initial setup for each call, based on the information we start with.
	println("INFO: Setting up function and method aflow edges");
	for (np <- aaInfo.callNodes<0>, cn <- aaInfo.callNodes[np]) processCall(np, cn);
	println("INFO: Edge setup complete");
	
	// Set up the info about which invokers/classes have already been used in these calls.
	// If this changes, we know that we need to redo the related calls.
	// TODO: Do globals play a role here? It seems like they should already be "hooked in" correctly.
	// TODO: We may still need to account properly for library functions here, if they can modify the
	//       aflow based on inputs.
	callNames = { < cn.target, np, cn > | np <- aaInfo.callNodes<0>, cn <- aaInfo.callNodes[np], cn is mcall };
	justNames = callNames<0>;
	triggeredClasses = { < jn, cn > | jn <- justNames, cn <- { cn | objectVal(cn,_) <- getItems(aaInfo.abstractStore, jn) } };
	
	
	// Now, propagate the constraints, using a worklist.
	set[NamePath] worklist = af<0>;
	int iters = 0;
	while (!isEmpty(worklist)) {
		source = getOneFrom(worklist); 
		worklist = worklist - source;
		iters = iters + 1;
		if (iters % 100 == 0) println("INFO: Performed <iters> iterations, <size(worklist)> items remaining in worklist");
		
		// If the node isn't in the store, we don't have any information to propagate anyway, so just skip it;
		// if information flows into it, we will add it to the worklist and process it later.
		if (hasNode(aaInfo.abstractStore, source)) {
			// If the source name is one of the names used as an invocation target, see if we have
			// added more classes since the initial setup of the aflow. If so, call again to add the
			// additional aflow edges, plus add this new info into triggeredClasses so we don't
			// repeat this needlessly.
			if (source in justNames) {
				sourceObjectClasses = { cn | objectVal(cn,_) <- getItems(aaInfo.abstractStore, source) };
				if (!isEmpty(sourceObjectClasses - triggeredClasses[source])) {
					triggeredClasses = triggeredClasses + { < source, cn > | cn <- sourceObjectClasses };
					for ( < np, cn > <- callNames[source] ) processCall(np, cn);
				}
			}
			
			// Propagate to each target; if this changes the target, add the target to the worklist
			// so we can propagate from that as well...
			for (target <- af[source]) {
				< modifiedStore, wasModified > = mergeNodes(aaInfo.abstractStore, source, target);
				if (wasModified) {
					aaInfo.abstractStore = modifiedStore;
					worklist = worklist + target;
				}
			}
		}
	}
	
	return aaInfo;
}

