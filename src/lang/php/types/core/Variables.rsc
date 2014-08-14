module lang::php::types::core::Variables

import lang::php::types::TypeSymbol;

// Predefined variables
// http://php.net/manual/en/reserved.variables.php

public map[str, TypeSymbol] predefinedVariables =
(
	"argc": integerType(),
	"argv": arrayType(stringType()),
	"_COOKIE": arrayType(\any()),
	"_ENV": arrayType(\any()),
	"_FILES": arrayType(\any()),
	"_GET": arrayType(\any()),
	"GLOBALS": arrayType(\any()),
	"_REQUEST": arrayType(\any()),
	"_POST": arrayType(\any()),
	"_SERVER": arrayType(\any()),
	"_SESSION": arrayType(\any()),

	"php_errormsg": stringType(),
	"HTTP_RAW_POST_DATA": arrayType(stringType()),
	"http_response_header": arrayType(stringType())
);