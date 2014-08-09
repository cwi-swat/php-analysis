module lang::php::types::TypeSymbol
extend analysis::m3::TypeSymbol;

// type `mixed()` is omitted, `\any()` will be used

data TypeSymbol
  = array(TypeSymbol arrayType)
  | boolean()
  | class(loc decl)
  | float()
  | integer()
  | null()
  | object()
  | resource()
  | string()
  ; 
  
//default bool subtyp(TypeSymbol s, TypeSymbol t) = s == t;

default TypeSymbol lub(TypeSymbol s, TypeSymbol t) = s == t ? s : \any();

public set[TypeSymbol] allTypes = {  array(\any()), boolean(), float(), integer(), null(), object(), resource(), string() }; 