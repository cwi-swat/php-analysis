module lang::php::semantics::shared::StoreModel

import lang::php::semantics::shared::Value;

public alias Loc = int;

public alias Mem = map[Loc,Value];
