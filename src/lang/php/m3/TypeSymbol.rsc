module lang::php::m3::TypeSymbol

extend analysis::m3::TypeSymbol;

data Bound 
  = \super(list[TypeSymbol] bound)
  | \extends(list[TypeSymbol] bound)
  | \unbounded()
  ;
  
data TypeSymbol 
  = \class(loc decl, list[TypeSymbol] typeParameters)
  | \interface(loc decl, list[TypeSymbol] typeParameters)
  | \trait(loc decl, list[TypeSymbol] typeParameters)
  | \method(loc decl, list[TypeSymbol] typeParameters, TypeSymbol returnType, list[TypeSymbol] parameters)
  | \typeParameter(loc decl, Bound upperbound) 
  //| \callback(loc decl, list[TypeSymbol] typeParameters)
  | array()
  | \bool()
  | float()
  | \int()
  | mixed()
  | object()
  //| resouce()
  //| \null()
  | string()
  | unset()
  ;  
  
  
  
default bool subtype(TypeSymbol s, TypeSymbol t) = s == t;

default TypeSymbol lub(TypeSymbol s, TypeSymbol t) = s == t ? s : object();  