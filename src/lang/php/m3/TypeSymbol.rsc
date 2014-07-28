module lang::php::m3::TypeSymbol
extend analysis::m3::TypeSymbol;

// type `mixed()` is omitted, `\any()` will be used

data TypeSymbol
  = array(set[TypeSymbol] itemTypes)
  | \bool()
  | class(loc decl)
  | float()
  | \int()
  | \null()
  | object()
  | resource()
  | string()
  ; 
  
default bool subtype(TypeSymbol s, TypeSymbol t) = s == t;

default TypeSymbol lub(TypeSymbol s, TypeSymbol t) = s == t ? s : \any();