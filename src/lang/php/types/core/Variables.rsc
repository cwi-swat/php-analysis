module lang::php::types::core::Variables

import lang::php::types::TypeSymbol;

// Predefined variables
// http://php.net/manual/en/reserved.variables.php

public map[str, TypeSymbol] predefinedVariables =
(
	"argc": integer(),
	"argv": array(string()),
	"_COOKIE": array(\any()),
	"_ENV": array(\any()),
	"_FILES": array(\any()),
	"_GET": array(\any()),
	"GLOBALS": array(\any()),
	"_REQUEST": array(\any()),
	"_POST": array(\any()),
	"_SERVER": array(\any()),
	"_SESSION": array(\any()),

	"php_errormsg": string(),
	"HTTP_RAW_POST_DATA": array(string()),
	"http_response_header": array(string())
);