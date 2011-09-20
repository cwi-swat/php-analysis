module lang::php::semantics::concrete::Value

import lang::php::semantics::shared::Value;

public data Value
	= IntValue(int iv)
	| RealValue(real rv)
	| BoolValue(bool bv)
	| StringValue(str sv)
	;
	