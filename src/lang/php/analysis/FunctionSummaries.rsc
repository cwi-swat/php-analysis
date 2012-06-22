@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::FunctionSummaries



alias ParamTriple = tuple[str paramType, bool isRef, str paramName, bool notRequired];
alias Params = list[ParamTriple];
alias SummarySig = tuple[str retType, bool isRef, Params params];
alias SummarySigs = map[str funName, SummarySig summarySig];

private SummarySigs summarySigs = ( 
	"in_array" : < "bool", false, [ < "mixed", false, "needle", false >,
									< "array", false, "haystack", false >,
									< "bool", false, "strict", true > ] >,
	"filemtime" : < "int", false, [ < "string", false, "filename", false > ] >,
	"is_null" : < "bool", false, [ < "mixed", false, "var", false > ] >,
	"php_sapi_name" : < "string", false, [ ] >,
	"ini_get" : < "string", false, [ < "string", false, "varname", false > ] >,
	"define" : < "bool", false, [ < "string", false, "name", false >,
							      < "mixed", false, "value", false >,
							      < "bool", false, "case_insensitive", true > ] >,
	"error_reporting" : < "int", false, [ < "int", false, "level", false > ] >,
	"ob_start" : < "bool", false, [ < "callback", false, "output_callback", false >,
									< "int", false, "chunk_size", true >,
									< "bool", false, "erase", true > ] >,
	"strcmp" : < "int", false, [ < "string", false, "str1", false >,
								 < "string", false, "str2", false > ] >,
	"is_object" : < "bool", false, [ < "mixed", false, "var", false > ] >,
	"mysql_free_result" : < "bool", false, [ < "resource", false, "result", false > ] >,
	"substr" : < "string", false, [ < "string", false, "string", false >, 
	 							    < "int", false, "start", false >,
	 							    < "int", false, "length", true >] >,
	"htmlspecialchars" : < "string", false, [ < "string", false, "string", false >,
											  < "int", false, "flags", true >,
											  < "string", false, "charset", true >,
											  < "bool", false, "double_encode", true > ] >,
	"print" : < "int", false, [ < "string", false, "arg", false > ] >,
	"mysql_query" : < "resource", false, [ < "string", false, "query", false >,
										   < "resource", false, "Link_identifier", true > ] >,
	"mysql_error" : < "string", false, [ < "resouce", false, "Link_identifier", true > ] >,
	"preg_match" : < "int", false, [ < "string", false, "pattern", false >,
									 < "string", false, "subject", false >,
									 < "array", true, "matches", true >,
									 < "int", false, "flags", true >,
									 < "int", false, "offset", true > ] >,
	"str_replace" : < "mixed", false, [ < "mixed", false, "search", false >,
									    < "mixed", false, "replace", false >,
									    < "mixed", false, "subject", false >,
									    < "int", true, "count", true > ] >,
	"max" : < "mixed", false, [ < "mixed", false, "value1", false >,
	                            < "mixed", false, "value2", true >,
	                            < "mixed", false, "value3", true > ] >,
	"function_exists" : < "bool", false, [ < "string", false, "function_name", false > ] >,
	"array_key_exists" : < "bool", false, [ < "mixed", false, "key", false >,
	            						    < "array", false, "search", false > ] >,
	"preg_quote" : < "string", false, [ < "string", false, "str", false >,
	  									< "string", false, "delimiter", true > ] >,
	"mysql_fetch_object" : < "object", false, [ < "resource", false, "result", false >,
												< "string", false, "class_name", true >,
												< "array", false, "params", true > ] >,
	"explode" : < "array", false, [ < "string", false, "delimiter", false >,
									< "string", false, "string", false >,
									< "int", false, "limit", true > ] >,
	"strstr" : < "string", false, [ < "string", false, "haystack", false >,
								    < "mixed", false, "needle", false >,
								    < "bool", false, "before_needle", true > ] >,
	"mysql_close" : < "bool", false, [ < "resource", false, "Link_identifier", true > ] >,
	"array_keys" : < "array", false, [ < "array", false, "input", false >,
									   < "mixed", false, "search_value", true >,
									   < "bool", false, "strict", true > ] >,
	"printf" : < "int", false, [ < "string", false, "format", false >,
								 < "mixed", false, "args", true > ] >,
	"set_include_path" : < "string", false, [ < "string", false, "new_include_path", false > ] >,
	"dirname" : < "string", false, [ < "string", false, "path", false > ] >,
	"gmdate" : < "string", false, [ < "string", false, "format", false >,
									< "int", false, "timestamp", true > ] >,
	"usort" : < "bool", false, [ < "array", true, "array", false >,
								 < "callback", false, "cmp_function", false > ] >,
	// NOTE: implode is odd, in that the arguments can be given in either order; this should not
	// matter for the analysis, though, it doesn't create aliases, etc.
	"implode" : < "string", false, [ < "mixed", false, "glue", true >,
								     < "mixed", false, "pieces", true > ] >,
	"count" : < "int", false, [ < "mixed", false, "var", false >,
							    < "int", false, "mode", true > ] >,
	"empty" : < "bool", false, [ < "mixed", false, "var", false > ] >,
	"mysql_connect" : < "resource", false, [ < "string", false, "server", true >,
											 < "string", false, "username", true >,
											 < "string", false, "password", true >,
											 < "bool", false, "new_Link", true >,
											 < "int", false,  "client_flags", true > ]>,
	"sprintf" : < "string", false, [ < "string", false, "format", false >,
									 < "mixed", false, "args", true > ] >,
	"defined" : < "bool", false, [ < "string", false, "name", false > ] >,
	"urlencode" : < "string", false, [ < "string", false, "string", false > ] >,
	"strlen" : < "int", false, [ < "string", false, "string", false > ] >,
	"is_array" : < "bool", false, [ < "mixed", false, "var", false > ] >,
	"mysql_select_db" : < "bool", false, [ < "string", false, "database_name", false >,
										   < "resource", false, "Link_identifier", true > ] >,
	"strpos" : < "int", false, [ < "string", false, "haystack", false >,
								 < "mixed", false, "needle", false >,
								 < "int", false, "offset", true > ] >,
	"trigger_error" : < "bool", false, [ < "string", false, "error_msg", false >,
										 < "int", false, "error_type", true > ] >,
	"die" : < "void", false, [ < "mixed", false, "status", true > ] >,
	"exit" : < "void", false, [ < "mixed", false, "status", true > ] >
);

private set[str] varargsFuns = { "max", "printf", "sprintf" };

private set[str] allocatorFuns = { "mysql_fetch_object", "array_keys", "explode", "str_replace" };

// TODO: Add in mysql_fetch_object
private set[str] aliasCreatorFuns = { };

private set[str] functionPointerFuns = { "ob_start", "usort" };

public bool hasSummary(str fname) { return fname in summarySigs; }

public SummarySig getSummary(str fname) { return summarySigs[fname]; }

public bool createsAliases(str fname) { return fname in aliasCreatorFuns; }

public bool usesVarArgs(str fname) { return fname in varargsFuns; }

public bool allocatorFun(str fname) { return fname in allocatorFuns; }

public bool usesFunPointers(str fname) { return fname in functionPointerFuns; }

public bool returnsVoid(str fname) { return summarySigs[fname].retType in { "void" }; }
