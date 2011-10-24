@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::InferTypes

//import lang::php::types::Types;
import lang::php::util::NodeInfo;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::Split;
import Node;
import IO;
import List;
import Set;
import Graph;

data Type 
	= scalar() 
	| array() 
	| array(Type elementType) 
	| class() 
	| class(str className) 
	| interface(str interfaceName) 
	| tv(int n) 
	| null() 
	| anything()
	| elementOf(Type arrayType)
	| resource()
	;

data Constraint 
	= eq(Type l, Type r)
	| superset(Type l, Type r)
	| expandFieldTemplate(Type targetType, str fieldName, Type fieldType)
	| expandTemplate(Type targetType, str methodName, list[Type] actualTypes, Type resultType)
	;

public anno Type node@tvar;
public anno set[Type] node@types;

//
// Templates represent instances of methods used in the inference process. The first version of
// template represents an uninstantiated template. The second represents an instantiated template,
// which includes the types of the receiver, result, and actual parameters.
//
public data Template 
	= template(Owner owner, str name, list[str] params, map[str,node] defaults, list[node] body)
	| template(Owner owner, str name, list[str] params, map[str,node] defaults, list[node] body, Type receiverType, Type receiverTypeVar, Type resultTypeVar, list[Type] actualTypes, list[Type] formalTypeVars)
	;

//
// Similarly to method templates, field templates represent fields used in the inference
// process. These are needed especially since we don't always know the target type during
// a field access.
// 
public data FieldTemplate
	= fieldTemplate(Owner owner, str name, node fieldDefault)
	| fieldTemplate(Owner owner, str name, node fieldDefault, Type receiverType)
	;

//
// The inference state keeps information we need during the type inference process.
//
data InferenceState = istate(int nextTV, 
							 set[Constraint] constraints, 
							 set[Template] methodTemplates, 
							 set[FieldTemplate] fieldTemplates, 
							 rel[Owner,str,Type,list[Type],Template] instantiatedMethodTemplates, 
							 rel[Owner,str,Type,FieldTemplate] instantiatedFieldTemplates);

//
// Create a new inference state item. This should only be used at the beginning; once inference starts,
// even during iteration, we need to keep the one we already have
//
public InferenceState newIS() {
	return istate(0,{},{},{},{},{});
}

//
// Allocate a unique type variable.
//
public tuple[Type,InferenceState] nextTypeVar(InferenceState iState) {
	iState.nextTV = iState.nextTV + 1;
	return < tv(iState.nextTV), iState >; 
}

public InferenceState addTemplate(InferenceState iState, Template t) {
	iState.methodTemplates = iState.methodTemplates + t;
	return iState;
}

public InferenceState addFieldTemplate(InferenceState iState, FieldTemplate ft) {
	iState.fieldTemplates = iState.fieldTemplates + ft;
	return iState;
}

public InferenceState addConstraints(InferenceState iState, Constraint cs...) {
	iState.constraints = iState.constraints + toSet(cs);
	return iState;
} 

public Template getTemplate(InferenceState iState, Owner o, str m) {
	return getOneFrom({ t | t:template(o,m,_,_,_) <- iState.methodTemplates});
}

public FieldTemplate getFieldTemplate(InferenceState iState, Owner o, str m) {
	return getOneFrom({ t | t:fieldTemplate(o,m,_) <- iState.fieldTemplates});
}

public InferenceState addInstantiatedTemplate(InferenceState iState, Template t) {
	iState.instantiatedMethodTemplates = iState.instantiatedMethodTemplates + < t.owner, t.name, t.receiverType, t.actualTypes, t >;
	return iState;
}

public InferenceState addInstantiatedFieldTemplate(InferenceState iState, FieldTemplate ft) {
	iState.instantiatedFieldTemplates = iState.instantiatedFieldTemlates + < t.owner, t.name, t.receiverType, t >;
	return iState;
}

public bool hasInstantiatedTemplate(InferenceState iState, Owner o, str m, Type receiver, list[Type] actuals) {
	return size(iState.instantiatedMethodTemplates[o,m,receiver,actuals]) > 0;
}

public Template getInstantiatedTemplate(InferenceState iState, Owner o, str m, Type receiver, list[Type] actuals) {
	return getOneFrom(iState.instantiatedMethodTemplates[o,m,receiver,actuals]);
}

public bool hasInstantiatedFieldTemplate(InferenceState iState, Owner o, str m, Type receiver) {
	return size(iState.instantiatedFieldTemplates[o,m,receiver]) > 0;
}

public Template getInstantiatedFieldTemplate(InferenceState iState, Owner o, str m, Type receiver) {
	return getOneFrom(iState.instantiatedFieldTemplates[o,m,receiver]);
}

//
// Create the base/uninstantiated templates, based on the script that is being analyzed. This will
// create a base template for each method and for the "main method", i.e., for the top-level of the
// script which will automatically run when the script is loaded.
//
// TODO: Add support for constants. We just need to mark them as scalars and ignore the associated
// define calls.
//
// TODO: Add support for static. Either mediawiki doesn't use any, or it wasn't supported in PHP4,
// but we will need this for PHP5. This goes for both static delarations inside function bodies
// and for static functions.
//
// TODO: Add support for interfaces. Interfaces are not available in PHP4.
//
public InferenceState calculateBaseTemplates(node scr, InferenceState iState) {
	// Get all variables used in the global scope
	vars = { v | script(n) := scr, ni <- n, getName(ni) notin { "class_def", "interface_def", "method" }, /variable_name(v) <- ni };
	
	// Assign type vars to each global; keep the assignment around in a map so we can use it later
	map[str,Type] globalVars = ( ) ;
	for (v <- vars) {
		< tvGlobal, iState > = nextTypeVar(iState);
		globalVars[v] = tvGlobal;
	}
	
	// Tag all the top-level uses of the globals with the appropriate type variable; in each method we will need to check
	// to see if the variable is in fact global before linking it in (which is why we limit this to top-level items)
	scr = "script"([getName(ni) notin { "class_def", "interface_def", "method" } ? visit(ni) { case vni:variable_name(vn) : if (vn in globalVars) insert(vni[@tvar = globalVars[vn]]); } : ni | script(n) := scr, ni <- n ]);
	
	// Add a template for the "main" routine, i.e., the top-level script
	iState = addTemplate(iState,template(globalOwns(),"***toplevel",[],(),[ni | script(n) := scr, ni <- n, getName(ni) notin {"class_def","interface_def","method"}]));
		
	// Get the top-level functions, which are in the global scope
	funs = getTopLevelFunctions(scr);
	
	// Create a template for each top-level function; in each, we need to check to see which globals are declared,
	// and link in the globals if they are used. Note that we don't bother assigning type variables to the formals
	// yet, since we want unique instances of these with each template we create.
	for (method(signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- funs) {
		// Find any global declarations inside this function; tag them with the existing global var
		// id, or add a new one if this global wasn't declared at the top level (which could happen
		// if this script is intended to be included in another one that has defined this already)
		funGlobals = { vn | /global(variable_name(vn)) <- b };
		b = visit(b) { 
			case n:variable_name(vn) : {
				if (vn in globalVars, vn in funGlobals) {
					insert(n[@tvar = globalVars[vn]]);
				} else if (vn in funGlobals) {
					< tvGlobal, iState > = nextTypeVar(iState);
					globalVars[vn] = tvGlobal;
					insert(n[@tvar = globalVars[vn]]);
				}
			}
		}
		
		// Perform some error checking, flagging parts of the language we do not currently handle
		for (/global(variable_variable(_)) <- b) println("WARNING: We do not currently handle variable variables used in global declarations");
		formals = [ vn | formal_parameter(_,_,name(variable_name(vn),_)) <- fpl ];
		overlap = toSet(formals) & funGlobals;
		defaults = ( vn : d  | formal_parameter(_,_,name(variable_name(vn),\default(d))) <- fpl );
		if (!isEmpty(overlap)) println("WARNING: Some formal parameters are also declared as globals: <overlap>");
		
		// Add a template for this function, including the body that has been annotated
		iState = addTemplate(iState, template(globalOwns(), mn, formals, defaults, b));
	}
	
	// Get all defined classes
	classes = getClasses(scr);
	
	// For each class, create field templates for each field, plus process each method as we did above.
	// We currently treat static fields and fields alike from a type perspective. When we start to split
	// instances of fields across templates, the static fields will still not be split, since they are
	// shared across all instances of a class. NOTE: Static fields are not supported in PHP4, so this is
	// only an issue when we also want to support PHP5.
	for (c:class_def(_,_,class_name(cn),_,_,_) <- classes) {
		fields = getAttributes(c);
		for (attribute(_,_,_,_,_,name(variable_name(vn),d)) <- fields)
			iState = addFieldTemplate(iState, fieldTemplate(classOwns(cn), vn, d));
		
		// Process each method in the class. This is like the processing of top-level functions.
		methods = getMethods(c);
		for (method(signature(_,_,_,_,_,_,_,_,method_name(mn),parameters(fpl)),body(b)) <- methods) {
			// Tag any globals with the global type
			funGlobals = { vn | /global(variable_name(vn)) <- b };
			b = visit(b) { 
				case n:variable_name(vn) : {
					if (vn in globalVars, vn in funGlobals) {
						insert(n[@tvar = globalVars[vn]]);
					} else if (vn in funGlobals) {
						< tvGlobal, iState > = nextTypeVar(iState);
						globalVars[vn] = tvGlobal;
						insert(n[@tvar = globalVars[vn]]);
					}
				}
			}
			
			// Perform some error checking, flagging parts of the language we do not currently handle
			for (/global(variable_variable(_)) <- b) println("WARNING: We do not currently handle variable variables used in global declarations");
			formals = [ vn | formal_parameter(_,_,name(variable_name(vn),_)) <- fpl ];
			defaults = ( vn : d  | formal_parameter(_,_,name(variable_name(vn),\default(d))) <- fpl );
			overlap = toSet(formals) & funGlobals;
			if (!isEmpty(overlap)) println("WARNING: Some formal parameters are also declared as globals: <overlap>");

			// Finally, build the template.
			iState = addTemplate(iState, template(classOwns(cn), mn, formals, defaults, b));
		}
		
	}
	
	return iState;
}

InferenceState addLibraryTemplates(InferenceState iState) {
	void addLibraryTemplate(str name, list[str] args, map[str,node] defaults, Type res) {
		Template t = libraryTemplate(name, args, defaults, res);
	}
	
	// { "wfDie" }	This is brought in automatically from a file of global mediawiki functions

	// bool define ( string $name , mixed $value [, bool $case_insensitive = false ] )
	// bool in_array ( mixed $needle , array $haystack [, bool $strict = FALSE ] )
	// int filemtime ( string $filename )
	// string php_sapi_name ( void )
	// string ini_get ( string $varname )
	// int error_reporting ([ int $level ] )
	// bool ob_start ([ callback $output_callback [, int $chunk_size = 0 [, bool $erase = true ]]] )
	// bool is_object ( mixed $var )
	// bool mysql_free_result ( resource $result )
	// string htmlspecialchars ( string $string [, int $flags = ENT_COMPAT | ENT_HTML401 [, string $charset [, bool $double_encode = true ]]] )
	// int print ( string $arg )
	// resource mysql_query ( string $query [, resource $link_identifier ] )
	// string mysql_error ([ resource $link_identifier ] )
	// int preg_match ( string $pattern , string $subject [, array &$matches [, int $flags = 0 [, int $offset = 0 ]]] )
	// mixed max ( array $values )
	// mixed max ( mixed $value1 , mixed $value2 [, mixed $value3... ] )
	// bool function_exists ( string $function_name )
	// bool array_key_exists ( mixed $key , array $search )
	// string preg_quote ( string $str [, string $delimiter = NULL ] )
	// array explode ( string $delimiter , string $string [, int $limit ] )
	// object mysql_fetch_object ( resource $result [, string $class_name [, array $params ]] )
	// string strstr ( string $haystack , mixed $needle [, bool $before_needle = false ] )
	// bool mysql_close ([ resource $link_identifier ] )
	// array array_keys ( array $input [, mixed $search_value [, bool $strict = false ]] )
	// int printf ( string $format [, mixed $args [, mixed $... ]] )
	// string set_include_path ( string $new_include_path )
	// string dirname ( string $path )
	// string gmdate ( string $format [, int $timestamp = time() ] )
	// bool usort ( array &$array , callback $cmp_function )
	// string implode ( string $glue , array $pieces )
	// string implode ( array $pieces )
	// bool empty ( mixed $var )
	// resource mysql_connect ([ string $server = ini_get("mysql.default_host") [, string $username = ini_get("mysql.default_user") [, string $password = ini_get("mysql.default_password") [, bool $new_link = false [, int $client_flags = 0 ]]]]] )
	// int time ( void )
	// bool defined ( string $name )
	
	// int strlen ( string $string )
	iState = addLibraryTemplate("strlen", ["string"], ( ), scalar());
	
	// bool is_array ( mixed $var )
	iState = addLibraryTemplate("is_array", ["var"],  ( ), scalar());
	
	// bool mysql_select_db ( string $database_name [, resource $link_identifier ] )
	iState = addLibraryTemplate("mysql_select_db", ["database_name", "link_identifier"], ("link_identifier" : null()), scalar());
		
	// int strpos ( string $haystack , mixed $needle [, int $offset = 0 ] )
	iState = addLibraryTemplate("strpos", ["haystack", "needle", "offset" ], ("offset" : scalar()), scalar());
	
	// bool trigger_error ( string $error_msg [, int $error_type = E_USER_NOTICE ] )
	iState = addLibraryTemplate("trigger_error", [ "error_msg", "error_type" ], ( "error_type" : scalar()), scalar());
		
	// void exit ([ string $status ] )
	// void exit ( int $status )
	iState = addLibraryTemplate("exit", [ "status" ], ( ), null());

	// void die ([ string $status ] )
	// void die ( int $status )
	iState = addLibraryTemplate("die", [ "status" ], ( ), null());
	
	
	return iState;
}

public Type nestedArrayType(1) = array();
public default Type nestedArrayType(n) = array(nestedArrayType(n-1));

//
// Given types for the actuals and the receivers, construct a new template. This allocates new type variables for the
// formals, for $this, for self, and for parent, and also builds the initial constraint system based on the body
// of the method. Note that we do not do any solving here (yet).
//
// NOTE: We do not need to handle parent or self. The parent keyword is being processed by phc to put in the actual parent, while the
// self keyword is only available in PHP 5.
//
// TODO: Add support for self, if needed -- phc may remove that as well, since self appears to be a static property of the code, i.e.,
// it is the class in which the method is defined, not the dynamic class of $this.
//
public InferenceState instantiateTemplate(Owner owner, str method, Type receiverType, list[Type] actualTypes, InferenceState iState) {
	// First, have we already instantiated this template? If so, just return right away.
	if (hasInstantiatedTemplate(iState, owner, method, receiverType, actualTypes)) return iState;
	 
	// Grab out the template to be instantiated
	Template t = getTemplate(iState, owner, method);
	
	// Allocate a new variable for $this, the type of the receiver, and annotate the template body with it.
	// Also constrain the type to be the receiver type.
	< tvReceiver, iState > = nextTypeVar(iState);
	t.body = visit(t.body) {
		case vn:variable_name("this") => vn[@tvar = tvReceiver]
	}
	iState = addConstraints(iState, eq(tvReceiver, receiverType));
	map[Type,Type] varsToTypes = ( tvReceiver : receiverType );
	
	// Allocate new variables for the formal parameters. NOTE: When building the template, we already checked
	// to see if the formals are shadowed by globals declared in the same method and issued a warning. So,
	// here we assume that this is not an issue.
	list[Type] formals = [ ];
	list[Type] varArgsTypes = [ actualTypes[idx] | idx <- index(actualTypes), idx >= size(t.params)];
	for (idx <- index(t.params)) {
		x = t.params[idx];
		< tvFormal, iState> = nextTypeVar(iState);
		formals = formals + tvFormal;
		t.body = visit(t.body) {
			case vn:variable_name(x) => vn[@tvar = tvFormal]
		}
		// Add type constraints for the formals. If we have an actual parameter type, then the
		// type var for the formal is in a superset relation with the actual parameter type.
		// If there is no actual parameter, set the constraint based on the default. If there
		// is no default, this should be an error (but we want to check it anyway), so set the
		// constraint to assume it is nil.
		if (idx < size(actualTypes)) {
			iState = addConstraints(iState, superset(tvFormal, actualTypes[idx]));
			varsToTypes[formals[idx]] = actualTypes[idx];
		} else {
			if (t.params[idx] in t.defaults) {
				if (getName(t.defaults[t.params[idx]]) in { "array" })
					// TODO: We need to calculate the value type if possible; this is the
					// same as saying we have an array of anything 
					iState = addConstraints(iState,superset(tvFormal,array()));
				else if (\null() := t.defaults[t.params[idx]]) 
					iState = addConstraints(iState,superset(tvFormal,null()));
				else
					iState = addConstraints(iState,superset(tvFormal,scalar()));
			} else {
				// Assign nil -- this is actually a type error
				iState = addConstraints(iState, superset(tvFormal,null()));
			}
		}
	}
	
	// Allocate a new variable representing the result type. Mark all return
	// expressions with this type.
	< tvResult, iState > = nextTypeVar(iState);
	t.body = visit(t.body) {
		case r:"return"(e) : insert(setAnnotations("return"(e[@tvar = tvResult]),getAnnotations(r)));
	}
	
	// Allocate new variables for any other variable names that have not already 
	// been assigned type variables.
	for (/vn:variable_name(x) <- t.body, "tvar" notin getAnnotations(vn)) {
		< tvLocal, iState > = nextTypeVar(iState);
		t.body = visit(t.body) {
			case vn:variable_name(x) => vn[@tvar = tvLocal]
		}
	}
	
	// Add type variables for all the expressions in the body of the method that have
	// not already been annotated (i.e., we don't want to add new type vars for the
	// formal parameters). Also add annotations to any literals (which may be used
	// in non-expression positions)
	t.body = visit(t.body) { 
		case n:\int(_) :
			if ( "tvar" notin getAnnotations(n)) {
				< tvar, iState > = nextTypeVar(iState);
				insert(n[@tvar = tvar]);
			}
		case n:\real(_) :
			if ( "tvar" notin getAnnotations(n)) {
				< tvar, iState > = nextTypeVar(iState);
				insert(n[@tvar = tvar]);
			}
		case n:\str(_) :
			if ( "tvar" notin getAnnotations(n)) {
				< tvar, iState > = nextTypeVar(iState);
				insert(n[@tvar = tvar]);
			}
		case n:\bool(_) :
			if ( "tvar" notin getAnnotations(n)) {
				< tvar, iState > = nextTypeVar(iState);
				insert(n[@tvar = tvar]);
			}
		case n:\null() :
			if ( "tvar" notin getAnnotations(n)) {
				< tvar, iState > = nextTypeVar(iState);
				insert(n[@tvar = tvar]);
			}
		case node n :
			if ( ! ((n@tvar)?), (n@nodecat)?, expr() := n@nodecat) {
				< tvar, iState > = nextTypeVar(iState);
				insert (n[@tvar = tvar]);
			}
	}

	// Build the constraints over the annotated method body
	// TODO: The case for name with default has been commented out. The only structure in a method body that
	// can use this is a static declaration. But, since these aren't avialable in the version we are looking
	// at, we will handle them later.
	// TODO: The exception cases are commented out, since they are not available in PHP4. For throw, the
	// constraint actually needs to be [| throw v |] subset downset("Exception"), i.e., the type of the
	// thrown value is an element of all classes which (reflexively, transitively) inherit from Exception
	// TODO: We need to handle fields more like we handle methods, since we don't know the target types.
	// Add the code to do this. This will treat all fields of the same receiver type as being of the
	// same type themselves.
	visit(t.body) {
		case n:\int(_) :
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		case n:\real(_) :
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		case n:\str(_) :
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		case n:\bool(_) :
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		case n:\null() :
			iState = addConstraints(iState, eq(n@tvar,null()));
		//case name(vn,\default(d)) : {
		//	if (vn@tvar notin varsToTypes) { 
		//		if (getName(d) in { "array" }) 
		//			iState = addConstraints(iState,superset(n@tvar,array()));
		//		else if (\null() := d) 
		//			iState = addConstraints(iState,superset(n@tvar,null()));
		//		else
		//			iState = addConstraints(iState,superset(n@tvar,scalar()));
		//	} 
		//}
		case \return() :
			// For an empty return, the result type is at least nil
			iState = addConstraints(iState, superset(tvResult, null()));
		case \return(rv) :
			// For a return with a return value rv, the result type is at least rv
			iState = addConstraints(iState, superset(tvResult, rv@tvar));
		//case \catch(catch_type(class_name(ct)),catch_name(cn),body(cb)) :
		//	iState = addConstraints(iState, superset(cn@tvar, class(ct)));
		//case \throw(v) :
		//	iState = addConstraints(iState,subset(v@tvar, class("Exception")));		
		case assign_var(vn,ref(r),e) :
			// For $x = e, x is at least an e
			iState = addConstraints(iState, superset(vn@tvar, e@tvar));
		case assign_field(t,field_name(fn),ref(r),e) : {
			// For $t->fn = e, we will need to create a field template, but we won't do
			// so until we actually have computed the target type
			< tvField, iState > = nextTypeVar(iState);
			iState = addConstraints(iState, expandFieldTemplate(t@tvar, fn, tvField), superset(tvField, e@tvar));
		}
		case assign_array(v,rv,ref(r),e) :
			// For $v[rv] = e, v is at least an array of e, while rv is scalar (string or int)
			iState = addConstraints(iState, superset(v@tvar, array(e@tvar)), superset(rv@tvar,scalar()));
		case assign_var_var(v,ref(r),e) :
			// For $$v = e, $v is a scalar, since it should be a string; $$v will be at least an e,
			// but we need to figure out which strings $$v can be 
			iState = addConstraints(iState, superset(v@tvar, scalar()), vvsuperset(v@tvar, e@tvar));
		case assign_next(vn,ref(r),e) :
			// This assigns e to the next slot of vn, i.e., $vn[] = e, so is like assign_array above
			iState = addConstraints(iState, superset(vn@tvar, array(e@tvar)));
		case pre_op(op,vn) :
			// Pre-ops include ++ and -- and work over scalars (ints)
			iState = addConstraints(iState, superset(vn@tvar, scalar()));
		case unset(target(),name(v),indices(idxs)) :
			// If we unset an array, then v must be at least an array
			if (size(idxs) > 0) iState = addConstraints(iState, superset(v@tvar, nestedArrayType(size(idxs)))); 
		case unset(target(t),name(v),indices(idxs)) : {
			// If we unset an array, then v must be at least an array
			< tvField, iState > = nextTypeVar(iState);
			if (size(idxs) > 0) iState = addConstraints(iState, expandFieldTemplate(t@tvar, v, tvField), superset(tvField, nestedArrayType(size(idxs))));
		} 
		case n:isset(target(),name(v),indices(idxs)) : {
			// If we isSet an array, then v must be at least an array; plus, the entire thing is a scalar(boolean)
			if (size(idxs) > 0) iState = addConstraints(iState, superset(v@tvar, nestedArrayType(size(idxs))));
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		} 
		case n:isset(target(t),name(v),indices(idxs)) : {
			// If we isSet an array, then v must be at least an array; plus, the entire thing is a scalar(boolean)
			< tvField, iState > = nextTypeVar(iState);
			if (size(idxs) > 0) iState = addConstraints(iState, expandFieldTemplate(t@tvar, v, tvField), superset(tvField, nestedArrayType(size(idxs))));
			iState = addConstraints(iState, eq(n@tvar,scalar()));
		} 
		case n:field_access(t,field_name(f)) : {
			// If we have a field access, we need to expand the field template once we have an actual for t.
			< tvField, iState > = nextTypeVar(iState);
			iState = addConstraints(iState, expandFieldTemplate(t@tvar, f, tvField), eq(n@tvar, tvField));
		}  
		case n:array_access(v,idx) :
			// If we have an array access, then v is some sort of array and idx is a scalar index; the
			// overall result
			iState = addConstraints(iState, superset(v@tvar, array()), superset(idx@tvar, scalar()));
		case array_next(v) :
			// If we have an array next, then v is some sort of array
			iState = addConstraints(iState, superset(v@tvar, array()));
		case n:cast(cast(c),v) :
			if (c in { "int", "real", "bool", "string" })
				// If c is a scalar literal than n is some sort of scalar, while v could be anything
				iState = addConstraints(iState, eq(n@tvar, scalar()));
			else if (c in { "array" })
				// If c is array than n is some sort of array, while v could be anything
				iState = addConstraints(iState, eq(n@tvar, array()));
			else if (c in { "object"})
				// If c is object than n is some sort of object (class type), while v could be anything
				iState = addConstraints(iState, eq(n@tvar, class()));
			else
				println("WARNING: unexpected cast literal <c>");
		case n:unary_op(op(x),v) :
			if (x in { "~" })
				// Bitwise not: operand and result both scalar
				iState = addConstraints(iState, superset(v@tvar, scalar()), eq(n@tvar, scalar()));
			else if (x in { "!" })
				// Logical not: result scalar, operand could be any type
				iState = addConstraints(iState, eq(n@tvar, scalar()));
			else if (x in { "-" })
				// Arithmetic negation: result scalar, operand scalar
				iState = addConstraints(iState, superset(v@tvar, scalar()), eq(n@tvar, scalar()));
			else
				println("WARNING: unexpected unary operator <x>");
		case n:bin_op(l,op(x),r) :
			if (x in { "*", "/", "%", "+", "-"})
				// Arithmetic Operators: *, /, %, +, -, both operands scalars, result scalar
				iState = addConstraints(iState, superset(l@tvar, scalar()), superset(r@tvar, scalar()), eq(n@tvar, scalar()));
			else if (x in { "\<\<", "\>\>", "&", "^", "|"})
				// Bitwise Operators: <<, >>, &, ^, |, both operands scalars, result scalar
				iState = addConstraints(iState, superset(l@tvar, scalar()), superset(r@tvar, scalar()), eq(n@tvar, scalar()));
			else if (x in { "and", "or", "xor", "&&", "||"})
				// Logical Operators: and, or, xor, &&, ||, operators could be any type, result scalar
				iState = addConstraints(iState, eq(n@tvar, scalar()));
			else if (x in { "."})
				// String operators: scalar result, any operand types
				iState = addConstraints(iState, eq(n@tvar, scalar()));
			else if (x in { "\<", "\<=", "\>", "\>=", "\<\>", "==", "===", "!=", "!=="})
				// Comparison operators: scalar result, any operand types
				iState = addConstraints(iState, eq(n@tvar, scalar()));
			else
				println("WARNING: unexpected binary operator <x>");
		case n:constant(class(),cn) :
			// Constants are scalars. TODO: Is this always true? Can they be nil?
			iState = addConstraints(iState, eq(n@tvar, scalar()));
		case constant(class(cln),cn) :
			// Constants are scalars. TODO: Is this always true? Can they be nil?
			iState = addConstraints(iState, eq(n@tvar, scalar()));
		case instanceof(v,c) :
			// TODO: Add support for this later, at least not in Mediawiki 1.6.12
			iState = iState;
		case n:invoke(target(), method_name(mn), actuals(al)) :
			// A call to a function with no target is a call to a top-level (global) function
			iState = addConstraints(iState, expandTemplate(null(), mn, [ a@tvar | actual(_,a) <- al ], n@tvar));
		case n:invoke(target(), variable_method(mn), actuals(al)) :
			// A call to a function with no target is a call to a top-level (global) function
			println("WARNING: We do not currently handle variable methods: <mn>");
		case n:invoke(target(t), method_name(mn), actuals(al)) :
			iState = addConstraints(iState, expandTemplate(t@tvar, mn, [ a@tvar | actual(_,a) <- al ], n@tvar)); 
		case n:invoke(target(t), variable_method(mn), actuals(al)) :
			println("WARNING: We do not currently handle variable methods: $<t>-\><mn>");
		case n:new(class_name(cn), actuals(al)) :
			iState = addConstraints(iState, expandTemplate(class(cn), cn, [ a@tvar | actual(_,a) <- al ], n@tvar), eq(n@tvar, class(cn))); 
		case n:static_array(l) :
			// TODO: We may want to actually try to figure out a type here; for now, just use array()
			iState = addConstraints(iState, superset(n@tvar, array()));
		case foreach_reset(vn,ht) :
			// This is a statement -- all we know from this is that vn is some sort of array
			iState = addConstraints(iState, superset(vn@tvar, array()));
		case foreach_next(vn,ht) :
			// This is a statement -- all we know from this is that vn is some sort of array
			iState = addConstraints(iState, superset(vn@tvar, array()));
		case foreach_end(vn,ht) :
			// This is a statement -- all we know from this is that vn is some sort of array
			iState = addConstraints(iState, superset(vn@tvar, array()));
		case n:foreach_has_key(vn,ht) :
			// vn is some sort of array, while the overall result is scalar (boolean)
			iState = addConstraints(iState, superset(vn@tvar, array()), eq(n@tvar, scalar()));
		case n:foreach_get_key(vn,ht) :
			// vn is some sort of array, while the overall result is scalar (either int or string)
			iState = addConstraints(iState, superset(vn@tvar, array()), eq(n@tvar, scalar()));
		case n:foreach_get_val(vn,ht) :
			// vn is some sort of array, while the overall result is based on the element type computed for vn
			iState = addConstraints(iState, superset(vn@tvar, array()), eq(n@tvar, elementOf(vn@tvar)));
		case n:param_is_ref(_,_,_) :
			// the target and field could be any type, the result of the exp is scalar (bool)
			iState = addConstraints(iState, eq(n@tvar, scalar()));
	}
	
	println("Instantiated template for <t.name>");
	iState = addInstantiatedTemplate(iState, template(t.owner, t.name, t.params, t.defaults, t.body, receiverType, tvReceiver, tvResult, actualTypes, formals));
	return iState;
}

public InferenceState instantiateMain(InferenceState iState) {
	return instantiateTemplate(globalOwns(), "***toplevel", null(), [], iState);

}
////
//// Assign initial type variables to the body of the method represented by this template.
////
//public tuple[Template,InferenceState] assignInitialTypeVars(Template t, InferenceState iState) {
//	< newBody, iState > = assignInitialTypeVars(t.body, iState);
//	return < t[body = newBody], iState >;
//}
//
////
//// Go through the method body, assigning initial type variables to any expression,
//// assignment target, etc that does not already have a type variable assignment. We
//// do not want to assign type variables "over the top" of existing variables.
////
//public tuple[node,InferenceState] assignInitialTypeVars(node scr, InferenceState iState) {
//	// Next, assign type vars to specific items in specific nodes, such as to the names
//	// in assignments and attributes in class definitions
//	// NOTE: On some parts of the node, e.g., ref(r) in assign_var, this drops existing
//	// annotations. If we start adding annotations, fix this.
//	scr = visit(scr) {
//		case n:assign_var(vn,ref(r),e) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("assign_var"(vn[@tvar = tvar], "ref"(r), e), getAnnotations(n)));
//			}
//		}
//		
//		case n:assign_field(t,fn,ref(r),e) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				< tvar2, iState > = nextTypeVar(iState);
//				insert(setAnnotations("assign_field"(t[@tvar = tvar],fn[@tvar = tvar2],"ref"(r),e),getAnnotations(n)));
//			}
//		}
//		
//		case n:assign_array(v,rv,ref(r),e) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				< tvar2, iState > = nextTypeVar(iState);
//				insert(setAnnotations("assign_array"(v[@tvar = tvar],rv[@tvar = tvar2],"ref"(r),e),getAnnotations(n)));
//			}
//		}
//		
//		case n:assign_var_var(v,ref(r),e) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("assign_var_var"(v[@tvar = tvar],"ref"(r),e),getAnnotations(n)));
//			}
//		}
//		
//		case n:assign_next(vn,ref(r),e) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("assign_next"(vn[@tvar = tvar],"ref"(r),e),getAnnotations(n)));
//			}
//		}
//		
//		case n:\catch(catch_type(ct),catch_name(cn),body(cb)) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("catch"("catch_type"(ct),"catch_name"(cn[@tvar = tvar]),"body"(cb)),getAnnotations(n)));
//			}
//		}
//		
//		case n:\global(g) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("global"(g[@tvar = tvar]),getAnnotations(n)));
//			}
//		}
//		
//		case n:static_decL(v) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				insert(setAnnotations("static_decl"(v[@tvar = tvar]),getAnnotations(n)));
//			}
//		}
//		
//		case n:method_alias(\alias(m1),m2) : {
//			if ("tvar" notin getAnnotations(n)) {
//				< tvar, iState > = nextTypeVar(iState);
//				< tvar2, iState > = nextTypeVar(iState);
//				insert(setAnnotations("method_alias"("alias"(c1[@tvar = tvar]),c2[@tvar = tvar2]), getAnnotations(n)));
//			}
//		}
//
//	}
//	
//	return < scr, iState >;
//}
//
////
//// The list version of the above -- this just pushes changes through all the nodes and through
//// the given iState
////
//private tuple[list[node],InferenceState] assignInitialTypeVars(list[node] nl, InferenceState iState) {
//	list[node] res = [ ];
//	for (n <- nl) {
//		< n, iState > = assignInitialTypeVars(n, iState);
//		res = res + n;
//	}
//	return < res, iState >;
//}
//
////
//// Build the constraint network for the code inside a template.
////
//public InferenceState buildConstraintNetwork(Template t, InferenceState iState) {
//	iState = buildConstraintNetwork(t.body, iState);
//	return iState;
//}
//
////
//// Build the constraint network for the code inside a given node. This uses
//// the type variables already assigned to the various nodes, added constraints
//// over these variables indicating the allowable types.
////
//public InferenceState buildConstraintNetwork(node scr, InferenceState iState) {
//	scr = visit(scr) {
//		// First, handle literals. These generate equality constraints, since
//		// since they restrict the type to be just the type of the literal.
//		// For instance, [| 5 |] == { scalar }.  
//		case n:\int(_) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),scalar());
//			}
//		}
//		case n:\real(_) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),scalar());
//			}
//		}
//		case n:\str(_) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),scalar());
//			}
//		}
//		case n:\bool(_) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),scalar());
//			}
//		}
//		case n:\null() : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),null());
//			}
//		}
//		
//		// The next few constraints are on expressions that are expected to evaluate
//		// to a scalar value. For instance, param_is_ref evaluates to either true
//		// or false, so, regardless of the type of the argument, the constraint will
//		// be [| param_is_ref(t,mn,x) |] == { scalar }.
//		case n:param_is_ref(target(), mn, x) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n), scalar());
//			}
//		}
//		case n:param_is_ref(target(t), mn, x) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n), scalar());
//			}
//		}
//		case n:foreach_has_key(vn,ht) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n), scalar());
//			}
//		}
//		case n:isset(target(),name(v),indices(idxs)) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n), scalar());
//			}
//		}				
//		case n:isset(target(t),name(v),indices(idxs)) : {
//			if ( "tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n), scalar());
//			}
//		}
//		
//		// Unset again allows the constrained item to be anything. TODO: Figure
//		// out how to properly set this. It may be best to just leave it as a no-op,
//		// or to add a map from the type var to nil (in case it is used again before
//		// being set, we don't want to do a flow analysis here...)
//		
//		// Now, add constraints for other expressions. These constraints are
//		// based on the arguments as well.
//		// TODO: To handle field access, we need to set type vars on the fields
//		// above.
//		//case n:field_access(t,f) :
//		//	return "<pp(t)>-\><pp(f)>";
//
//		case n:array_access(v,idx) : {
//			if ("tvar" in getAnnotations(v), "tvar" in getAnnotations(idx)) {
//				iState.constraints = iState.constraints;
//			}
//		}
//			
//		case array_next(v) :
//			return "arraynext(<pp(v)>)";
//			
//		case cast(c,v) :
//			return "(<pp(c)>) <pp(v)>";
//			
//		case unary_op(op,v) :
//			return "<pp(op)><pp(v)>";
//			
//		case bin_op(l,op,r) :
//			return "<pp(l)> <pp(op)> <pp(r)>";
//			
//		case constant(class(),cn) :
//			return "<pp(cn)>";
//			
//		case constant(class(cln),cn) :
//			return "<pp(cln)>-\><pp(cn)>";
//			
//		case instanceof(v,c) :
//			return "<pp(v)> instanceof <pp(c)>";
//			
//
//
//
//		case \return() :
//			return "return;";
//			
//		case \return(rv) :
//			return "return(<pp(rv)>);";
//			
//		case static_decl(v) :
//			return "static <pp(v)>;";
//			
//		case \global(g) :
//			return "global <pp(g)>;";
//			
//		case \try(body(tb),catches(cs)) :
//			return "try {
//				   '  <intercalate("\n",[pp(tbi)|tbi<-tb])>
//				   '}
//				   '<intercalate("\n",[pp(csi)|csi<-cs])>
//				   '";
//				   
//		case \catch(catch_type(ct),catch_name(cn),body(cb)) :
//			return "catch (<pp(ct)> <pp(cn)>) {
//				   '  <intercalate("\n",[pp(cbi)|cbi<-cb])>
//				   '}";
//			
//			
//		case \throw(v) :
//			return "throw <pp(v)>;";
//			
//		case assign_var(vn,ref(r),e) :
//			return "<pp(vn)> <r?"?":"">= <pp(e)>;";
//			
//		case assign_field(t,fn,ref(r),e) :
//			return "<pp(t)>-\><pp(fn)> <r?"?":"">= <pp(e)>;";
//			
//		case assign_array(v,rv,ref(r),e) :
//			return "<pp(v)>[<pp(rv)>] <r?"?":"">= <pp(e)>;";
//			
//		case assign_var_var(v,ref(r),e) :
//			return "$<pp(v)> <r?"?":"">= <pp(e)>;";
//			
//		case assign_next(vn,ref(r),e) :
//			// TODO: What does this do?
//			return "<pp(vn)> <r?"?":"">= <pp(e)>;";
//			
//		case pre_op(op,vn) :
//			return "<pp(op)><pp(vn)>;";
//			
//		case eval_expr(e) :
//			return "<pp(e)>;";
//			
//		case unset(target(),name(v),indices(idxs)) :
//			return "unset(<pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";
//
//		case unset(target(t),name(v),indices(idxs)) :
//			return "unset(<pp(t)>-\><pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";
//
//		case isset(target(),name(v),indices(idxs)) :
//			return "isset(<pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">)";
//
//		case isset(target(t),name(v),indices(idxs)) :
//			return "isset(<pp(t)>-\><pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";
//
//		case invoke(target(), mn, actuals(al)) :
//			return "<pp(mn)>(<intercalate(",",[pp(ali)|ali<-al])>)";
//		
//		case invoke(target(t), mn, actuals(al)) :
//			return "<pp(t)>-\><pp(mn)>(<intercalate(",",[pp(ali)|ali<-al])>)";
//
//		case new(cn, actuals(al)) :
//			return "new <pp(cn)>(<intercalate(",",[pp(ali)|ali<-al])>)";
//		
//		case actual(ref(r),rv) :
//			return "<r?"?":""><pp(rv)>";
//			
//		case static_array(l) :
//			return "array(<intercalate(",", [pp(li)|li<-l])>)";
//			
//		case static_array_elem(key(),ref(b),v) :
//			return "<b?"?":""><pp(v)>";
//					
//		case static_array_elem(key(k),ref(b),v) :
//			return "<pp(k)> =\> <b?"?":""><pp(v)>";
//
//		case branch(vn,tb,fb) :
//			return "branch(<pp(vn)>,<pp(tb)>,<pp(fb)>);";
//			
//		case goto(l) :
//			return "goto <pp(l)>;";
//			
//		case label(l) :
//			return "<pp(l)>:";
//			
//		case foreach_reset(vn,ht) :
//			return "fe_reset(<pp(vn)>,<pp(ht)>);";
//					
//		case foreach_next(vn,ht) :
//			return "fe_next(<pp(vn)>,<pp(ht)>);";
//
//		case foreach_end(vn,ht) :
//			return "fe_end(<pp(vn)>,<pp(ht)>);";
//
//		case foreach_has_key(vn,ht) :
//			return "fe_has_key(<pp(vn)>,<pp(ht)>)";
//					
//		case foreach_get_key(vn,ht) :
//			return "fe_get_key(<pp(vn)>,<pp(ht)>)";
//
//		case foreach_get_val(vn,ht) :
//			return "fe_get_val(<pp(vn)>,<pp(ht)>)";
//			
//		case param_is_ref(target(), mn, n) :
//			return "param_is_ref(<pp(mn)>,<n>)";
//
//		case param_is_ref(target(t), mn, n) :
//			return "param_is_ref(<pp(t)>-\><pp(mn)>,<n>)";
//	}
//	
//	// Look for expressions that cause the initial assignments of types. This
//	// includes new expressions, which have a type identical to the class being
//	// created; casts, which have a type equal to the type being casted to;
//	// catches, which include class names as the type of exception being caught;
//	// and others. NOTE: Not all of these (catch, for instance) are available in
//	// PHP 4, so some of these are additions to ensure this functionality still
//	// works when we turn to PHP 5 analysis.
//	scr = visit(scr) {
//		// Language construct: new
//		case n:new(class_name(cn), actuals(al)) : {
//			if ("tvar" in getAnnotations(n)) {
//				iState.constraints = iState.constraints + eq(gettv(n),class(cn));			
//			}
//		}
//		
//		// Language construct: cast
//		case n:cast(cast(cl),v) : {
//			if ("tvar" in getAnnotations(n)) {
//				if (cl in { "int", "real", "booL", "string" })
//					iState.constraints = iState.constraints + eq(gettv(n),scalar());
//				else if (cl in { "array" })
//					iState.constraints = iState.constraints + eq(gettv(n), array());
//				else if (cl in { "object" })
//					instate.constraints = iState.constraints + eq(gettv(n), class());
//			}
//		}
//		
//		// Language construct: catch (not in PHP4)
//		case n:\catch(catch_type(class_name(ct)),catch_name(cn),body(cb)) : {
//			if ("tvar" in getAnnotations(cn)) {
//				iState.constraints = iState.constraints + eq(gettv(cn), class(ct));
//			}
//		}
//		
//		// Language construct: formal parameter, no type, default given; only adds
//		// a type constraint when the default is one that we can directly infer a
//		// type for, such as 5, 6.1, nil, or "hello world"
//		case n:formal_parameter(\type(),ref(r),name(vn,\default(d))) : {
//			if ("tvar" in getAnnotations(vn)) {
//				switch(d) {
//					case \int(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \real(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \bool(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \string(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case "null"() : iState.constraints = iState.constraints + eq(gettv(vn), null()); 
//				}
//			}
//		}
//
//		// Language construct: formal parameter, type, no default
//		case n:formal_parameter(\type(class_name(ct)),ref(r),name(vn,\default())) : {
//			if ("tvar" in getAnnotations(vn)) {
//				iState.constraints = iState.constraints + eq(gettv(vn), class(ct));
//			}
//		}
//
//		// Language construct: formal parameter, type, default given
//		// TODO: What should we do in cases where there is an error in the formal
//		// parameter declaration? For instance, what if we say MyObject $x = 5?
//		// This is only an issue for PHP5, since PHP4 doesn't allow type hinting
//		// on formal parameters anyway, so don't worry about it until later.			
//		case n:formal_parameter(\type(class_name(ct)),ref(r),name(vn,\default(d))) : {
//			if ("tvar" in getAnnotations(vn)) {
//				iState.constraints = iState.constraints + eq(gettv(vn), class(ct));
//			}
//		}
//
//		// Language construct: attribute (i.e., field), default given
//		case n:attribute(\public(pb),protected(pr),\private(pv),static(st),const(c),name(vn,\default(d))) : {
//			if ("tvar" in getAnnotations(vn)) {
//				switch(d) {
//					case \int(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \real(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \bool(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case \string(_) : iState.constraints = iState.constraints + eq(gettv(vn), scalar()); 
//					case "null"() : iState.constraints = iState.constraints + eq(gettv(vn), null()); 
//				}
//			}
//		}
//	}
//	
//	return iState;
//}
//
//private InferenceState buildConstraintNetwork(list[node] nl, InferenceState iState) {
//	for (n <- nl) iState = buildConstraintNetwork(n, iState);
//	return iState;
//}

public Type gettv(node n) {
	if ("tvar" in getAnnotations(n), Type tvar:tv(_) := getAnnotations(n)["tvar"]) return tvar;
}

public void performInference(SplitScript scr) {
	InferenceState iState = newIS();
	< baseTemplates, iState > = calculateBaseTemplates(scr, iState); 
}

