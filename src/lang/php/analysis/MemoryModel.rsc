@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::MemoryModel

import Node;
import List;

alias MemoryLoc = int;
data MemoryVal;
alias MemoryCell = tuple[MemoryLoc, MemoryVal];
alias Heap = set[MemoryCell];
alias FieldName = str;
alias ItemName = str;

data MemoryVal 
	= nullVal() 
	| unknownVal()
	| scalarVal() 
	| arrayVal(MemoryLoc dataLoc) 
	| objVal(map[FieldName,MemoryLoc])
	| objRef(MemoryLoc objLoc) 
	| anyVal()
	| classAlias(str className)
	| methodAlias(str methodName)
	| interfaceAlias(str interfaceName)
	| indirectVal(MemoryLoc pointsTo)
	;

alias Env = rel[ItemName,MemoryLoc];

data MMEnv = globalEnv() | functionEnv(str funName) | methodEnv (str className, str methodName);
data MemoryModel = MM(Env env, Heap heap, MemoryLoc mloc);

public MemoryModel newMemoryModel() {
	return MM({ }, { }, 1);
}

//
// Given a memory location, insert the given value at that location if it is not
// already one of the possible values for that heap address.
//
public MemoryModel insertValue(MemoryModel mm, MemoryLoc mloc, MemoryVal mv) {
	if (mv notin mm.heap[mloc])
		mm.heap = mm.heap + < mloc, mv >;
	return mm;
}

//
// Assign mv to the given name, if it has not already been so assigned.
// If the name is not already in the environment, add it and point it to
// a new location in the heap first.
//
public MemoryModel insertValue(MemoryModel mm, str name, MemoryVal mv) {
	if (name notin mm.env<0>) {
		mm.env = mm.env + < name, mm.mloc >;
		mm.mloc = mm.mloc + 1;
	}
	for (mloc <- mm.env[name]) mm = insertValue(mm, mloc, mv);
	return mm;
}

//
// Given a memory location, check to see if an indirect val is one of the
// possible values at that address. If not, add it, pointing to a new
// location in the heap. Then, for each indirect val at this location,
// add the given value as one of the possible pointed-to values.
//
public MemoryModel insertIndirectValue(MemoryModel mm, MemoryLoc mloc, MemoryVal mv) {
	if ({indirectVal(_),_*} !:= mm.heap[mloc]) {
		mm.heap = mm.heap + < mloc, indirectVal(mm.mloc) >;
		mm.mloc = mm.mloc + 1;
	}
	for (indirectVal(ivloc) <- mm.heap[mloc]) mm = insertValue(mm, ivloc, mv);
	return mm;
}

//
// Assign mv as an indirect value to the given name. If that name does not
// yet exist in the environment, allocate a slot for it in the environment
// pointing to a ne heap location.
//
public MemoryModel insertIndirectValue(MemoryModel mm, str name, MemoryVal mv) {
	if (name notin mm.env<0>) {
		mm.env = mm.env + < name, mm.mloc >;
		mm.mloc = mm.mloc + 1;
	}
	for (mloc <- mm.env[name]) mm = insertIndirectValue(mm, mloc, mv);
	return mm;
}

//
// Assign a given value into the array as one of the possible values for
// the array. The index depth allows us to handle nested arrays, e.g.,
// $x[][] = "hello".
//
public MemoryModel insertArrayValue(MemoryModel mm, MemoryLoc mloc, int idxDepth, MemoryVal mv) {
	if (idxDepth == 1) {
		mm.heap = mm.heap + < mloc, arrayVal(mm.mloc) > + < mm.mloc, mv >;
		mm.mloc = mm.mloc + 1;
	} else {
		mm.heap = mm.heap + < mloc, arrayVal(mm.mloc) >;
		mm.mloc = mm.mloc + 1;
		for (arrayVal(avloc) <- mm.heap[mloc]) mm = insertArrayValue(mm, avloc, idxDepth - 1, mv);
	}
	return mm;
}

//
// Assign mv to array $name, at index depth idxDepth (representing
// cases where we have multiple levels of indexing, such as $x[][].
//
public MemoryModel insertArrayValue(MemoryModel mm, str name, int idxDepth, MemoryVal mv) {
	if (name notin mm.env<0>) {
		mm.env = mm.env + < name, mm.mloc >;
		mm.mloc = mm.mloc + 1;
	}
	for (mloc <- mm.env[name]) mm = insertArrayValue(mm, mloc, idxDepth, mv);
	return mm;
}

//
// A handy default for arrays with only one level of indexing
//
public MemoryModel insertArrayValue(MemoryModel mm, str name, MemoryVal mv) {
	return insertArrayValue(mm, name, 1, mv);
}

//
// Assign mv to a field in an object. If the object exists already,
// see if it has a location for the given field. If it doesn't exist
// yet, we need to create it.
//
public MemoryModel insertObjectFieldValue(MemoryModel mm, MemoryLoc mloc, str fieldName, MemoryVal mv) {
	if ( { objRef(orloc), _* } := mm.heap[mloc] ) {
		for ( objVal(fmap) <- mm.heap[orloc] ) {
			if (fieldName in fmap, mv notin mm.heap[fmap[fieldName]]) {
				mm.heap[fmap[fieldName]] = mm.heap[fmap[fieldName]] + < fmap[fieldName], mv >;
			} else {
				mm.heap = mm.heap - < mloc, objVal(fmap) >;
				fmap[fieldName] = mm.mloc;
				mm.mloc = mm.mloc + 1;
				mm.heap = mm.heap + < mloc, objVal(fmap) > + < fmap[fieldName], mv >;
			}
		}
	} else {
		mm.heap = mm.heap + < mloc, objRef(mm.mloc) > + < mm.mloc, objVal( ( fieldName : mm.mloc + 1 ) ) > + < mm.mloc + 1, mv >;
		mm.mloc = mm.mloc + 2;
	}
	return mm;
}

//
// Assign mv to a field in an object named name.
//
public MemoryModel insertObjectFieldValue(MemoryModel mm, str name, str fieldName, MemoryVal mv) {
	if (name notin mm.env<0>) {
		mm.env = mm.env + < name, mm.mloc >;
		mm.mloc = mm.mloc + 1;
	}
	for (mloc <- mm.env[name]) insertObjectFieldValue(mm, mloc, fieldName, mv);
	return mm;
}

//
// Build the memory model for a script in a flow-insensitive fashion
//
public MemoryModel buildMemoryModelFI(node scr) {
	if (script(body) := scr) {
		// Get a list of body statements, excluding those that are class, interface, or method decls
		toplevel = [ b | b <- body, getName(b) notin { "class_def", "interface_def", "method" } ];
		
		// Handle any initial allocations at the global level. By initial allocations, we mean
		// situations where we can identify what value is being assigned into a variable, such
		// as $x = new C, or $x = 5, but not cases where we are cloning ($x = 5; $y = $x) or
		// passing around references ($x = new C; $y = $x).
		MemoryModel mm = newMemoryModel();
		mm = addAllocationsToModelFI(body, mm);
		
		// Now, go through all the functions, adding them into the memory model. In each of these
		// cases, we clear out the environment first EXCEPT FOR any globals or fields, which
		// are left in.
		toplevelFuns = [ b | b <- body, getName(b) in { "method" } ];
		for (method(signature(_,_,_,_,_,_,_,_,mn,parameters(fpl)),body(b)) <- toplevelFuns) {
			// First, grab out the globals
			globals = { vn | bi <- b, /global(variable_name(vn)) <- bi };
			
			// Second, create a memory model with an environment just containing the globals
			MemoryModel mmfun = mm; mm.env = { < fn, fl > | < fn, fl > <- mm.env, fn in globals };
			mmfun = addAllocationsToModelFI(b, mmfun); 
		}
		
		return mm; 
	} else {
		throw "Should have a script!";
	}
}

//
// Add allocations into the model
//
public MemoryModel addAllocationsToModelFI(list[node] body, MemoryModel mm) {
	
	MemoryVal deriveValue(node e) {
		// If the expression is an invocation of "new", return an empty object
		// type -- we only model fields as they are accessed right now, instead
		// of trying to allocate the structure for them up front.
		// TODO: If needed, change this -- it may be useful for later, when
		// doing alias analsis, etc.
		if (getName(e) in { "new" }) {
			MemoryVal mv = objRef(mm.mloc + 1);
			mm.heap = mm.heap + < mm.mloc, mv > + < mm.mloc + 1, objVal( ( ) ) >;
			mm.mloc = mm.mloc + 2;
			return mv;
		}
		
		if (getName(e) in { "int", "real", "str", "bool" }) {
			return scalarVal(); // these don't live anywhere in memory
		}
		
		if (getName(e) in { "nil" }) {
			return nullVal(); // neither does this
		}
		
		if (getName(e) in { "static_array" }) {
			// TODO: Look at values, try to allocate something useful for the array value type
			MemoryVal mv = arrayVal(mm.mloc + 1);
			mm.heap = mm.heap + < mm.mloc, mv > + < mm.mloc + 1, unknownVal() >;
			mm.mloc = mm.mloc + 2;
			return mv;
		}
		
		// If all else fails, just return unknown val
		return unknownVal();
	}
	//
	// Just visit those nodes that perform potential allocations of some sort.
	// We only consider intraprocedural allocations; i.e., we don't try to reason
	// about the allocations that called functions/methods can do.
	//
	bottom-up visit(body) {
		// A class alias will assign class c2 to name c1
		case class_alias(\alias(class_name(c1)),class_name(c2)) : 
			mm = insertValue(mm, c1, classAlias(c2));
			
		// An interface alias will assign interface i2 to name i1
		case interface_alias(\alias(interface_name(i1)),interface_name(i2)) :
			mm = insertValue(mm, i1, interfaceAlias(i2));
			
		// A method alias will assign method m2 to name m1
		case method_alias(\alias(method_name(m1)),method_name(m2)) :
			mm = insertValue(mm, m1, methodAlias(m2));
			
		// A static decl with no default, so we just assume
		// the declared name is null at this point
		case static_decl(name(variable_name(vn),\default())) :
			mm = insertValue(mm, vn, nullVal());

		// If we have a static decl with a default, use that default
		// to set the name to an initial value. TODO: Do something
		// useful with the info in the array, which could tell us the
		// type
		case static_decl(name(variable_name(vn),\default(d))) :
			if (getName(d) in { "array" })
				mm = insertArrayValue(mm, vn, unknownVal());
			else if (\null() := d)
				mm = insertValue(mm, vn, nullVal());
			else 
				mm = insertValue(mm, vn, scalarVal());
			
		// Catch indicates that vn holds some sort of object, of whatever
		// type is in catch_type; we don't do any allocation here, though,
		// since we just do this by need
		case \catch(catch_type(_),catch_name(variable_name(vn)),body(cb)) :
			mm = insertValue(mm, vn, objVal());

		// Figure out a value from expression e, assining this to name vn.
		// The "figure out" part is a bit loose right now, since we don't
		// have types, so, if we cannot easily figure it out, just assign
		// unknown. 
		case assign_var(variable_name(vn),ref(r),e) :
			mm = insertValue(mm, vn, deriveValue(e));
			
		// Do the same here, except in this case we have a field of an
		// object. This will also allocate the field if needed.
		case assign_field(variable_name(vn),field_name(fn),ref(r),e) :
			mm = insertObjectFieldValue(mm, vn, fn, deriveValue(e));
			
		// We don't handle this yet. So, don't handle it yet.
		case assign_field(class_name(cn),field_name(fn),ref(r),e) : {
			println("WARNING: We do not yet handle assignments to static fields of classes");
			throw "Unhandled: We do not yet handle assignments to static fields of classes";
		}
		
		// Do the same as above, except for arrays.
		case assign_array(variable_name(vn),rv,ref(r),e) :
			mm = insertArrayValue(mm, vn, deriveValue(e));
			
		// Do the same as above, except for var vars. We maintain the indirection
		// here, since we don't know the string value of vn.
		case assign_var_var(variable_name(vn),ref(r),e) :
			mm = insertIndirectValue(mm, vn, deriveValue(e));

		// This is the same as an array assignment, so we treat it identically to the array
		// case above.		
		case assign_next(variable_name(vn),ref(r),e) :
			mm = insertArrayValue(mm, vn, deriveValue(e));

		// Unset a name, with or without indices; if we have indices, this is an array
		// unset, which we handle by setting the element to null, but if there are no
		// indices this is just a set of a scalar to null			
		case unset(target(),name(variable_name(v)),indices(idxs)) :
			if (size(idxs) > 0)
				mm = insertArrayValue(mm, v, size(idxs), nullVal());
			else
				mm = insertValue(mm, v, nullVal());

		// Same as above, but with var vars; if we have no indices, just make sure our
		// level of indirection is set, but if we have indices, issue a warning, since
		// we don't currently handle variable variables as array names (e.g., we don't
		// handle $$x[3])
		case unset(target(t),name(variable_variable(variable_name(v))),indices(idxs)) :
			if (size(idxs) > 0) {
				println("WARNING: We do not yet handle variable variables are array names");
				throw "Unhandled: We do not yet handle variable variables are array names";
			} else {
				mm = insertIndirectValue(mm, v, nullVal());
			}

		// TODO: We could add the various foreach constructs here, which would at least
		// allow us to infer the item in question is an array, but for now just focus on
		// constructs that actually perform assignments into memory (the foreach constructs
		// just iterate over already-allocated arrays)			
	}
	
	return mm;
}

// For a given function, build a memory model for that function
