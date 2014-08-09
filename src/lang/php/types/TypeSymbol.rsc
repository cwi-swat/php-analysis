module lang::php::types::TypeSymbol
extend analysis::m3::TypeSymbol;

// type `mixed()` is omitted, `\any()` will be used

data TypeSymbol
  = array(TypeSymbol arrayType)
  | \bool()
  | class(loc decl)
  | float()
  | \int()
  //| mixed()
  | \null()
  | object()
  | resource()
  | string()
  ; 
  
//default bool subtyp(TypeSymbol s, TypeSymbol t) = s == t;

default TypeSymbol lub(TypeSymbol s, TypeSymbol t) = s == t ? s : \any();

public set[TypeSymbol] allTypes = {  array(\any()), \bool(), float(), \int(), \null(), object(), resource(), string() }; 
//public set[TypeSymbol] allTypes = {  array(mixed()), boolean(), float(), integer(), null_(), object(), resource(), string() }; 