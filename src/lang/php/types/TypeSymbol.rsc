module lang::php::types::TypeSymbol
extend analysis::m3::TypeSymbol;

// type `mixed()` is omitted, `\any()` will be used

data TypeSymbol
  = arrayType(TypeSymbol arrayType)
  | booleanType()
  | classType(loc decl)
  | floatType()
  | integerType()
  | nullType()
  | objectType()
  | resourceType()
  | stringType()
  ; 
 
//default bool subtyp(TypeSymbol s, TypeSymbol t) = s == t;

default TypeSymbol lub(TypeSymbol s, TypeSymbol t) = s == t ? s : \any();

public set[TypeSymbol] allTypes = {  arrayType(\any()), booleanType(), floatType(), integerType(), nullType(), objectType(), resourceType(), stringType() }; 
