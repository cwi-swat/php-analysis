module lang::php::analysis::values::Strings

import lang::php::ast::AbstractSyntax;

data PHPString
	= bot()
	| val(set[str] values)
	| top()
	;
