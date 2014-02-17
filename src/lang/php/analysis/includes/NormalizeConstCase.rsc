module lang::php::analysis::includes::NormalizeConstCase

import lang::php::ast::AbstractSyntax;
import String;

private set[str] caseInsensitiveConsts = { "TRUE", "FALSE", "NULL" };

public Expr normalizeConstCase(Expr e) {
	return bottom-up visit(e) {
		case fi:fetchConst(ni:name(s)) : {
			if (toUpperCase(s) in caseInsensitiveConsts)
				insert fi[name=ni[name=toUpperCase(s)]];
		}
	}
}
