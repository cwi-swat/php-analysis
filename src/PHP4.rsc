module PHP4 
lexical HereDocLit
  = (![\n \r $ \\ {] | CurlyBracketLit | SlashCharLit | DollarCharLit | HereDocLineTerminator)+ 
  ;

lexical CommandLit
  = (DollarCharLit | CurlyBracketLit | ![$ \\ ` {] | ESlashCharLit)+ 
  ;

lexical EmbeddedArrayVariable
  =  EmbeddedArrayVariable: "${" String !>> [0-9 A-Z _ a-z] 
  ;

syntax New
  =  ObjectCreation: "new" !>> [0-9 A-Z _ a-z] ClassNameReference 
    |  ObjectCreation: "new" !>> [0-9 A-Z _ a-z] ClassNameReference "(" {CallParam ","}* ")" 
  ;

lexical OctaCharacterTwo
  =  OctaChar: "\\" [0-7] [0-7] 
  ;

lexical DollarCharLit
  = "$" 
  ;

syntax Bool
  =  False: "false" !>> [0-9 A-Z _ a-z] 
    |  True: "true" !>> [0-9 A-Z _ a-z] 
  ;

lexical HexaCharacterOne
  =  HexaChar: "\\" "x" [0-9 A-F a-f] 
  ;

syntax ClassNameReference
  =  ClassName: String !>> [0-9 A-Z _ a-z] 
    | DynamicClassNameReference 
  ;

lexical Octa
  = [0] [0-9]+ 
  ;

lexical OctaCharacterOne
  =  OctaChar: "\\" [0-7] 
  ;

syntax InlineHtmlPart
  =  Literal: InlineHTMLChars !>> ![\<] 
    | InlineEcho 
    |  Literal: NonOpenTag 
  ;

//layout LAYOUTLIST 
//  = LAYOUT* 
//  ;

layout LAYOUTLIST = LAYOUT* !>> [\t-\n \r \ ] !>> "//" !>> "/*";

syntax Expr
  = ObjectCVar "\<\<=" Expr 
    > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    |  IsNotEqual: Expr "\<\>" Expr 
    |  Die: "die" !>> [0-9 A-Z _ a-z] "(" Expr ")" 
    | CommonScalar 
    |  Greater: Expr "\>" Expr 
    |  IsNotEqual: Expr "!=" Expr 
    |  Die: "die" !>> [0-9 A-Z _ a-z] 
    |  Less: Expr "\<" !>> [\>] Expr 
    |  IntCast: "(" "int" ")" Expr 
    |  Die: "die" !>> [0-9 A-Z _ a-z] "(" ")" 
    | left Div: Expr "/" Expr 
    | Variable 
    |  PostDec: ObjectCVar "--" 
    |  Positive: "+" !>> [+] Expr 
    |  Exit: "exit" !>> [0-9 A-Z _ a-z] 
    | New 
    |  GreaterEqual: Expr "\>=" Expr 
    | FunctionCall 
    | left BinXor: Expr "^" Expr 
    |  Print: "print" !>> [0-9 A-Z _ a-z] Expr 
    |  ShellCommand: "`" CommandPart* "`" 
    |  SLAssign: ObjectCVar "\<\<=" Expr 
    |  Neg: "~" Expr 
    |  FloatCast: "(" "double" ")" Expr 
    |  BoolCast: "(" "boolean" ")" Expr 
    |  ListAssign: List "=" Expr 
    |  StringCast: "(" "string" ")" Expr 
    | left Mod: Expr "%" Expr 
    |  NullCast: "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
    |  Assign: ObjectCVar "=" Expr 
    |  Not: "!" Expr 
    |  ReferenceAssign: ObjectCVar "=" "&" ObjectFunctionCall 
    |  IntCast: "(" "integer" ")" Expr 
    |  ReferenceAssign: ObjectCVar "=" "&" ObjectCVar 
    |  MinAssign: ObjectCVar "-=" Expr 
    |  FloatCast: "(" "float" ")" Expr 
    |  XorAssign: ObjectCVar "^=" Expr 
    |  BoolCast: "(" "bool" ")" Expr 
    | left Plus: Expr "+" !>> [+] Expr 
    | left Mul: Expr "*" Expr 
    | left LOr: Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | left BinAnd: Expr "&" Expr 
    |  IsIdentical: Expr "===" Expr 
    |  PreDec: "--" ObjectCVar 
    |  ArrayCast: "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
    |  PlusAssign: ObjectCVar "+=" Expr 
    |  SRAssign: ObjectCVar "\>\>=" Expr 
    | left Min: Expr "-" !>> [\-] Expr 
    | @NotSupported="prefer" ErrorFree: "@" Expr 
    |  PostInc: ObjectCVar "++" 
    |  InternalFunction: InternalFunction 
    | left And: Expr "&&" Expr 
    | left Ternary: Expr "?" Expr ":" Expr 
    | Array 
    |  ModAssign: ObjectCVar "%=" Expr 
    | left LXor: Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    |  FloatCast: "(" "real" ")" Expr 
    | left BinOr: Expr "|" Expr 
    | left Or: Expr "||" Expr 
    | bracket"(" Expr ")" 
    |  Exit: "exit" !>> [0-9 A-Z _ a-z] "(" Expr ")" 
    |  IsNotIdentical: Expr "!==" Expr 
    |  ConcatAssign: ObjectCVar ".=" Expr 
    |  Exit: "exit" !>> [0-9 A-Z _ a-z] "(" ")" 
    |  ObjectCast: "(" "object" ")" Expr 
    |  AndAssign: ObjectCVar "&=" Expr 
    | left LAnd: Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    |  MulAssign: ObjectCVar "*=" Expr 
    |  Negative: "-" !>> [\-] Expr 
    |  ReferenceAssign: ObjectCVar "=" "&" FunctionCall 
    | left SR: Expr "\>\>" Expr 
    | left SL: Expr "\<\<" Expr 
    |  ReferenceAssign: ObjectCVar "=" "&" New 
    |  OrAssign: ObjectCVar "|=" Expr 
    | ConstantVariable \ ConstantVariableKeywords 
    |  LessEqual: Expr "\<=" Expr 
    |  IsEqual: Expr "==" Expr 
    |  DivAssign: ObjectCVar "/=" Expr 
    | left Concat: Expr "." Expr 
    |  PreInc: "++" ObjectCVar 
    | "(" "boolean" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "boolean" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "boolean" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "!" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "~" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "@" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "!" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "~" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "@" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "!" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "~" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "@" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "double" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "+" !>> [+] Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "-" !>> [\-] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "\>\>=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > "+" !>> [+] Expr 
    | Expr "/" Expr 
      > "+" !>> [+] Expr 
    | Expr "%" Expr 
      > "+" !>> [+] Expr 
    | ObjectCVar "|=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "&=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "%=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "\<\<=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "\>\>=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "^=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "+=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "-=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "*=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "/=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar ".=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "\<\<=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "\>\>=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "^=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "|=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "&=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "%=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar ".=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "/=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "*=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "-=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "+=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "+=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "-=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "*=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "/=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar ".=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "%=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "&=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "|=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | ObjectCVar "^=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "-" !>> [\-] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "-" !>> [\-] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "-" !>> [\-] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "float" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "integer" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "float" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "float" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "real" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "?" Expr ":" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "?" Expr ":" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "?" Expr ":" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > List "=" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "||" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "&&" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "|" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "&" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "^" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "." Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "*" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "/" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "%" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "==" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "!=" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<=" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>=" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "===" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "!==" Expr 
    | Expr "or" !>> [0-9 A-Z _ a-z] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "string" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "string" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "." Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "||" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "&&" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "|" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "&" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "^" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\<\<" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\>\>" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "==" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\<\>" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "!=" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\<=" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\>" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\>=" Expr 
    | "(" "string" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "!==" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "===" Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "bool" ")" Expr 
      > Expr "===" Expr 
    | "(" "bool" ")" Expr 
      > Expr "!==" Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "bool" ")" Expr 
      > Expr "\>=" Expr 
    | "(" "bool" ")" Expr 
      > Expr "\>" Expr 
    | "(" "bool" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "bool" ")" Expr 
      > Expr "!=" Expr 
    | "(" "bool" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "bool" ")" Expr 
      > Expr "==" Expr 
    | "(" "bool" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "bool" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "bool" ")" Expr 
      > Expr "%" Expr 
    | "(" "bool" ")" Expr 
      > Expr "/" Expr 
    | "(" "bool" ")" Expr 
      > Expr "*" Expr 
    | "(" "bool" ")" Expr 
      > Expr "." Expr 
    | "(" "bool" ")" Expr 
      > Expr "^" Expr 
    | "(" "bool" ")" Expr 
      > Expr "&" Expr 
    | "(" "bool" ")" Expr 
      > Expr "|" Expr 
    | "(" "bool" ")" Expr 
      > Expr "&&" Expr 
    | "(" "bool" ")" Expr 
      > Expr "||" Expr 
    | Expr "||" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "===" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!==" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | "-" !>> [\-] Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "bool" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "float" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "||" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "." Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "." Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "||" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "||" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "&&" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "|" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "|" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "&" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "&" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "^" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "^" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "." Expr 
      > ObjectCVar "=" Expr 
    | Expr "." Expr 
      > ObjectCVar "+=" Expr 
    | Expr "." Expr 
      > ObjectCVar "-=" Expr 
    | Expr "." Expr 
      > ObjectCVar "*=" Expr 
    | Expr "." Expr 
      > ObjectCVar "/=" Expr 
    | Expr "." Expr 
      > ObjectCVar ".=" Expr 
    | Expr "." Expr 
      > ObjectCVar "%=" Expr 
    | Expr "." Expr 
      > ObjectCVar "&=" Expr 
    | Expr "." Expr 
      > ObjectCVar "|=" Expr 
    | Expr "." Expr 
      > ObjectCVar "^=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "*" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "*" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "/" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "/" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "%" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "%" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\<\<" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\>\>" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\<=" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\>" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\>=" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "!=" Expr 
      > ObjectCVar "=" Expr 
    | Expr "\<\>" Expr 
      > ObjectCVar "=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "==" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "==" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "===" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "===" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "!==" Expr 
      > ObjectCVar "^=" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "double" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "+" !>> [+] Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "?" Expr ":" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "integer" ")" Expr 
      > Expr "||" Expr 
    | "(" "integer" ")" Expr 
      > Expr "&&" Expr 
    | "(" "integer" ")" Expr 
      > Expr "|" Expr 
    | "(" "integer" ")" Expr 
      > Expr "&" Expr 
    | "(" "integer" ")" Expr 
      > Expr "^" Expr 
    | "(" "integer" ")" Expr 
      > Expr "." Expr 
    | "(" "integer" ")" Expr 
      > Expr "*" Expr 
    | "(" "integer" ")" Expr 
      > Expr "/" Expr 
    | "(" "integer" ")" Expr 
      > Expr "%" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "integer" ")" Expr 
      > Expr "==" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "integer" ")" Expr 
      > Expr "!=" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\>" Expr 
    | "(" "integer" ")" Expr 
      > Expr "\>=" Expr 
    | "(" "integer" ")" Expr 
      > Expr "!==" Expr 
    | "(" "integer" ")" Expr 
      > Expr "===" Expr 
    | "(" "real" ")" Expr 
      > Expr "\>=" Expr 
    | "(" "real" ")" Expr 
      > Expr "\>" Expr 
    | "(" "real" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "real" ")" Expr 
      > Expr "!=" Expr 
    | "(" "real" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "real" ")" Expr 
      > Expr "==" Expr 
    | "(" "real" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "real" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "real" ")" Expr 
      > Expr "%" Expr 
    | "(" "real" ")" Expr 
      > Expr "/" Expr 
    | "(" "real" ")" Expr 
      > Expr "*" Expr 
    | "(" "real" ")" Expr 
      > Expr "." Expr 
    | "(" "real" ")" Expr 
      > Expr "^" Expr 
    | "(" "real" ")" Expr 
      > Expr "&" Expr 
    | "(" "real" ")" Expr 
      > Expr "|" Expr 
    | "(" "real" ")" Expr 
      > Expr "&&" Expr 
    | "(" "real" ")" Expr 
      > Expr "||" Expr 
    | "(" "real" ")" Expr 
      > Expr "===" Expr 
    | "(" "real" ")" Expr 
      > Expr "!==" Expr 
    | Expr "or" !>> [0-9 A-Z _ a-z] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "string" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "!" Expr 
      > Expr "?" Expr ":" Expr 
    | "~" Expr 
      > Expr "?" Expr ":" Expr 
    | "@" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "!=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "\<\>" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "==" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "^" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "&" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "|" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "&&" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "||" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "\>=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "\>" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "\<=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "!==" Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "===" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "+=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "-=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "*=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "/=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar ".=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "%=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "&=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "|=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "^=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "-" !>> [\-] Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > List "=" Expr 
    | Expr "?" Expr ":" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "object" ")" Expr 
      > Expr "!==" Expr 
    | "(" "object" ")" Expr 
      > Expr "===" Expr 
    | "(" "object" ")" Expr 
      > Expr "||" Expr 
    | "(" "object" ")" Expr 
      > Expr "&&" Expr 
    | "(" "object" ")" Expr 
      > Expr "|" Expr 
    | "(" "object" ")" Expr 
      > Expr "&" Expr 
    | "(" "object" ")" Expr 
      > Expr "^" Expr 
    | "(" "object" ")" Expr 
      > Expr "." Expr 
    | "(" "object" ")" Expr 
      > Expr "*" Expr 
    | "(" "object" ")" Expr 
      > Expr "/" Expr 
    | "(" "object" ")" Expr 
      > Expr "%" Expr 
    | "(" "object" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "object" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "object" ")" Expr 
      > Expr "==" Expr 
    | "(" "object" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "object" ")" Expr 
      > Expr "!=" Expr 
    | "(" "object" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "object" ")" Expr 
      > Expr "\>" Expr 
    | "(" "object" ")" Expr 
      > Expr "\>=" Expr 
    | "(" "string" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "int" ")" Expr 
      > Expr "||" Expr 
    | "(" "int" ")" Expr 
      > Expr "&&" Expr 
    | "(" "int" ")" Expr 
      > Expr "\>=" Expr 
    | "(" "int" ")" Expr 
      > Expr "\>" Expr 
    | "(" "int" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "int" ")" Expr 
      > Expr "!=" Expr 
    | "(" "int" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "int" ")" Expr 
      > Expr "==" Expr 
    | "(" "int" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "int" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "int" ")" Expr 
      > Expr "%" Expr 
    | "(" "int" ")" Expr 
      > Expr "/" Expr 
    | "(" "int" ")" Expr 
      > Expr "*" Expr 
    | "(" "int" ")" Expr 
      > Expr "." Expr 
    | "(" "int" ")" Expr 
      > Expr "^" Expr 
    | "(" "int" ")" Expr 
      > Expr "&" Expr 
    | "(" "int" ")" Expr 
      > Expr "|" Expr 
    | "(" "int" ")" Expr 
      > Expr "===" Expr 
    | "(" "int" ")" Expr 
      > Expr "!==" Expr 
    | "+" !>> [+] Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "?" Expr ":" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "||" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "&&" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "|" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "&" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "^" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "." Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "*" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "/" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "%" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "==" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "!=" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<=" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\>=" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "===" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "!==" Expr 
    | Expr "\<" !>> [\>] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "float" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "-" !>> [\-] Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "double" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "double" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "double" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "*" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "/" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "%" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "^=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "|=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "&=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "%=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar ".=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "/=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "*=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "-=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "+=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "+" !>> [+] Expr 
      > ObjectCVar "\>\>=" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "or" !>> [0-9 A-Z _ a-z] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "!" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "~" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "@" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "===" Expr 
      > List "=" Expr 
    | Expr "!==" Expr 
      > List "=" Expr 
    | Expr "||" Expr 
      > List "=" Expr 
    | Expr "&&" Expr 
      > List "=" Expr 
    | Expr "|" Expr 
      > List "=" Expr 
    | Expr "&" Expr 
      > List "=" Expr 
    | Expr "^" Expr 
      > List "=" Expr 
    | Expr "." Expr 
      > List "=" Expr 
    | Expr "*" Expr 
      > List "=" Expr 
    | Expr "/" Expr 
      > List "=" Expr 
    | Expr "%" Expr 
      > List "=" Expr 
    | Expr "\<\<" Expr 
      > List "=" Expr 
    | Expr "\>\>" Expr 
      > List "=" Expr 
    | Expr "==" Expr 
      > List "=" Expr 
    | Expr "\<\>" Expr 
      > List "=" Expr 
    | Expr "!=" Expr 
      > List "=" Expr 
    | Expr "\<=" Expr 
      > List "=" Expr 
    | Expr "\>" Expr 
      > List "=" Expr 
    | Expr "\>=" Expr 
      > List "=" Expr 
    | "(" "string" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "!==" Expr 
      > Expr "===" Expr 
    | Expr "===" Expr 
      > Expr "^" Expr 
    | Expr "===" Expr 
      > Expr "&" Expr 
    | Expr "===" Expr 
      > Expr "|" Expr 
    | Expr "===" Expr 
      > Expr "&&" Expr 
    | Expr "===" Expr 
      > Expr "||" Expr 
    | Expr "===" Expr 
      > Expr "!=" Expr 
    | Expr "===" Expr 
      > Expr "\<\>" Expr 
    | Expr "===" Expr 
      > Expr "==" Expr 
    | Expr "!==" Expr 
      > Expr "!==" Expr 
    | Expr "===" Expr 
      > Expr "!==" Expr 
    | Expr "===" Expr 
      > Expr "===" Expr 
    | Expr "!==" Expr 
      > Expr "==" Expr 
    | Expr "!==" Expr 
      > Expr "\<\>" Expr 
    | Expr "!==" Expr 
      > Expr "!=" Expr 
    | Expr "!==" Expr 
      > Expr "||" Expr 
    | Expr "!==" Expr 
      > Expr "&&" Expr 
    | Expr "!==" Expr 
      > Expr "|" Expr 
    | Expr "!==" Expr 
      > Expr "&" Expr 
    | Expr "!==" Expr 
      > Expr "^" Expr 
    | Expr "." Expr 
      > Expr "===" Expr 
    | Expr "*" Expr 
      > Expr "===" Expr 
    | Expr "/" Expr 
      > Expr "===" Expr 
    | Expr "%" Expr 
      > Expr "===" Expr 
    | Expr "\<\<" Expr 
      > Expr "===" Expr 
    | Expr "\>\>" Expr 
      > Expr "===" Expr 
    | Expr "==" Expr 
      > Expr "===" Expr 
    | Expr "\<\>" Expr 
      > Expr "===" Expr 
    | Expr "!=" Expr 
      > Expr "===" Expr 
    | Expr "\<=" Expr 
      > Expr "===" Expr 
    | Expr "\>" Expr 
      > Expr "===" Expr 
    | Expr "\>=" Expr 
      > Expr "===" Expr 
    | Expr "." Expr 
      > Expr "!==" Expr 
    | Expr "*" Expr 
      > Expr "!==" Expr 
    | Expr "/" Expr 
      > Expr "!==" Expr 
    | Expr "%" Expr 
      > Expr "!==" Expr 
    | Expr "\<\<" Expr 
      > Expr "!==" Expr 
    | Expr "\>\>" Expr 
      > Expr "!==" Expr 
    | Expr "==" Expr 
      > Expr "!==" Expr 
    | Expr "\<\>" Expr 
      > Expr "!==" Expr 
    | Expr "!=" Expr 
      > Expr "!==" Expr 
    | Expr "\>=" Expr 
      > Expr "!==" Expr 
    | Expr "\>" Expr 
      > Expr "!==" Expr 
    | Expr "\<=" Expr 
      > Expr "!==" Expr 
    | Expr "\>=" Expr 
      > Expr "!=" Expr 
    | Expr "\>=" Expr 
      > Expr "\<\>" Expr 
    | Expr "\>=" Expr 
      > Expr "==" Expr 
    | Expr "\>=" Expr 
      > Expr "^" Expr 
    | Expr "\>=" Expr 
      > Expr "&" Expr 
    | Expr "\>=" Expr 
      > Expr "|" Expr 
    | Expr "\>=" Expr 
      > Expr "&&" Expr 
    | Expr "\>=" Expr 
      > Expr "||" Expr 
    | Expr "\>=" Expr 
      > Expr "\>=" Expr 
    | Expr "\>=" Expr 
      > Expr "\>" Expr 
    | Expr "\>=" Expr 
      > Expr "\<=" Expr 
    | Expr "\>" Expr 
      > Expr "!=" Expr 
    | Expr "\>" Expr 
      > Expr "\<\>" Expr 
    | Expr "\>" Expr 
      > Expr "==" Expr 
    | Expr "\>" Expr 
      > Expr "^" Expr 
    | Expr "\>" Expr 
      > Expr "&" Expr 
    | Expr "\>" Expr 
      > Expr "|" Expr 
    | Expr "\>" Expr 
      > Expr "&&" Expr 
    | Expr "\>" Expr 
      > Expr "||" Expr 
    | Expr "\>" Expr 
      > Expr "\>=" Expr 
    | Expr "\>" Expr 
      > Expr "\>" Expr 
    | Expr "\>" Expr 
      > Expr "\<=" Expr 
    | Expr "\<=" Expr 
      > Expr "!=" Expr 
    | Expr "\<=" Expr 
      > Expr "\<\>" Expr 
    | Expr "\<=" Expr 
      > Expr "==" Expr 
    | Expr "\<=" Expr 
      > Expr "^" Expr 
    | Expr "\<=" Expr 
      > Expr "&" Expr 
    | Expr "\<=" Expr 
      > Expr "|" Expr 
    | Expr "\<=" Expr 
      > Expr "&&" Expr 
    | Expr "\<=" Expr 
      > Expr "||" Expr 
    | Expr "\<=" Expr 
      > Expr "\>=" Expr 
    | Expr "\<=" Expr 
      > Expr "\>" Expr 
    | Expr "\<=" Expr 
      > Expr "\<=" Expr 
    | Expr "!=" Expr 
      > Expr "^" Expr 
    | Expr "\<\>" Expr 
      > Expr "^" Expr 
    | Expr "!=" Expr 
      > Expr "&" Expr 
    | Expr "\<\>" Expr 
      > Expr "&" Expr 
    | Expr "!=" Expr 
      > Expr "|" Expr 
    | Expr "\<\>" Expr 
      > Expr "|" Expr 
    | Expr "!=" Expr 
      > Expr "&&" Expr 
    | Expr "\<\>" Expr 
      > Expr "&&" Expr 
    | Expr "!=" Expr 
      > Expr "||" Expr 
    | Expr "\<\>" Expr 
      > Expr "||" Expr 
    | Expr "!=" Expr 
      > Expr "!=" Expr 
    | Expr "\<\>" Expr 
      > Expr "!=" Expr 
    | Expr "!=" Expr 
      > Expr "\<\>" Expr 
    | Expr "\<\>" Expr 
      > Expr "\<\>" Expr 
    | Expr "!=" Expr 
      > Expr "==" Expr 
    | Expr "\<\>" Expr 
      > Expr "==" Expr 
    | Expr "==" Expr 
      > Expr "^" Expr 
    | Expr "==" Expr 
      > Expr "&" Expr 
    | Expr "==" Expr 
      > Expr "|" Expr 
    | Expr "==" Expr 
      > Expr "&&" Expr 
    | Expr "==" Expr 
      > Expr "||" Expr 
    | Expr "==" Expr 
      > Expr "!=" Expr 
    | Expr "==" Expr 
      > Expr "\<\>" Expr 
    | Expr "==" Expr 
      > Expr "==" Expr 
    | Expr "\>\>" Expr 
      > Expr "\>=" Expr 
    | Expr "\>\>" Expr 
      > Expr "\>" Expr 
    | Expr "\>\>" Expr 
      > Expr "\<=" Expr 
    | Expr "\>\>" Expr 
      > Expr "!=" Expr 
    | Expr "\>\>" Expr 
      > Expr "\<\>" Expr 
    | Expr "\>\>" Expr 
      > Expr "==" Expr 
    | Expr "\>\>" Expr 
      > Expr "^" Expr 
    | Expr "\>\>" Expr 
      > Expr "&" Expr 
    | Expr "\>\>" Expr 
      > Expr "|" Expr 
    | Expr "\>\>" Expr 
      > Expr "&&" Expr 
    | Expr "\>\>" Expr 
      > Expr "||" Expr 
    | Expr "\>\>" Expr 
      > Expr "\>\>" Expr 
    | Expr "\>\>" Expr 
      > Expr "\<\<" Expr 
    | Expr "\<\<" Expr 
      > Expr "\>=" Expr 
    | Expr "\<\<" Expr 
      > Expr "\>" Expr 
    | Expr "\<\<" Expr 
      > Expr "\<=" Expr 
    | Expr "\<\<" Expr 
      > Expr "!=" Expr 
    | Expr "\<\<" Expr 
      > Expr "\<\>" Expr 
    | Expr "\<\<" Expr 
      > Expr "==" Expr 
    | Expr "\<\<" Expr 
      > Expr "^" Expr 
    | Expr "\<\<" Expr 
      > Expr "&" Expr 
    | Expr "\<\<" Expr 
      > Expr "|" Expr 
    | Expr "\<\<" Expr 
      > Expr "&&" Expr 
    | Expr "\<\<" Expr 
      > Expr "||" Expr 
    | Expr "\<\<" Expr 
      > Expr "\>\>" Expr 
    | Expr "\<\<" Expr 
      > Expr "\<\<" Expr 
    | Expr "%" Expr 
      > Expr "\>=" Expr 
    | Expr "%" Expr 
      > Expr "\>" Expr 
    | Expr "%" Expr 
      > Expr "\<=" Expr 
    | Expr "%" Expr 
      > Expr "!=" Expr 
    | Expr "%" Expr 
      > Expr "\<\>" Expr 
    | Expr "%" Expr 
      > Expr "==" Expr 
    | Expr "%" Expr 
      > Expr "\>\>" Expr 
    | Expr "%" Expr 
      > Expr "\<\<" Expr 
    | Expr "%" Expr 
      > Expr "." Expr 
    | Expr "%" Expr 
      > Expr "^" Expr 
    | Expr "%" Expr 
      > Expr "&" Expr 
    | Expr "%" Expr 
      > Expr "|" Expr 
    | Expr "%" Expr 
      > Expr "&&" Expr 
    | Expr "%" Expr 
      > Expr "||" Expr 
    | Expr "%" Expr 
      > Expr "%" Expr 
    | Expr "%" Expr 
      > Expr "/" Expr 
    | Expr "%" Expr 
      > Expr "*" Expr 
    | Expr "/" Expr 
      > Expr "\>=" Expr 
    | Expr "/" Expr 
      > Expr "\>" Expr 
    | Expr "/" Expr 
      > Expr "\<=" Expr 
    | Expr "/" Expr 
      > Expr "!=" Expr 
    | Expr "/" Expr 
      > Expr "\<\>" Expr 
    | Expr "/" Expr 
      > Expr "==" Expr 
    | Expr "/" Expr 
      > Expr "\>\>" Expr 
    | Expr "/" Expr 
      > Expr "\<\<" Expr 
    | Expr "/" Expr 
      > Expr "." Expr 
    | Expr "/" Expr 
      > Expr "^" Expr 
    | Expr "/" Expr 
      > Expr "&" Expr 
    | Expr "/" Expr 
      > Expr "|" Expr 
    | Expr "/" Expr 
      > Expr "&&" Expr 
    | Expr "/" Expr 
      > Expr "||" Expr 
    | Expr "/" Expr 
      > Expr "%" Expr 
    | Expr "/" Expr 
      > Expr "/" Expr 
    | Expr "/" Expr 
      > Expr "*" Expr 
    | Expr "*" Expr 
      > Expr "\>=" Expr 
    | Expr "*" Expr 
      > Expr "\>" Expr 
    | Expr "*" Expr 
      > Expr "\<=" Expr 
    | Expr "*" Expr 
      > Expr "!=" Expr 
    | Expr "*" Expr 
      > Expr "\<\>" Expr 
    | Expr "*" Expr 
      > Expr "==" Expr 
    | Expr "*" Expr 
      > Expr "\>\>" Expr 
    | Expr "*" Expr 
      > Expr "\<\<" Expr 
    | Expr "*" Expr 
      > Expr "." Expr 
    | Expr "*" Expr 
      > Expr "^" Expr 
    | Expr "*" Expr 
      > Expr "&" Expr 
    | Expr "*" Expr 
      > Expr "|" Expr 
    | Expr "*" Expr 
      > Expr "&&" Expr 
    | Expr "*" Expr 
      > Expr "||" Expr 
    | Expr "*" Expr 
      > Expr "%" Expr 
    | Expr "*" Expr 
      > Expr "/" Expr 
    | Expr "*" Expr 
      > Expr "*" Expr 
    | Expr "." Expr 
      > Expr "\>=" Expr 
    | Expr "." Expr 
      > Expr "\>" Expr 
    | Expr "." Expr 
      > Expr "\<=" Expr 
    | Expr "." Expr 
      > Expr "!=" Expr 
    | Expr "." Expr 
      > Expr "\<\>" Expr 
    | Expr "." Expr 
      > Expr "==" Expr 
    | Expr "." Expr 
      > Expr "\>\>" Expr 
    | Expr "." Expr 
      > Expr "\<\<" Expr 
    | Expr "." Expr 
      > Expr "^" Expr 
    | Expr "." Expr 
      > Expr "&" Expr 
    | Expr "." Expr 
      > Expr "|" Expr 
    | Expr "." Expr 
      > Expr "&&" Expr 
    | Expr "." Expr 
      > Expr "||" Expr 
    | Expr "." Expr 
      > Expr "." Expr 
    | Expr "^" Expr 
      > Expr "|" Expr 
    | Expr "^" Expr 
      > Expr "&&" Expr 
    | Expr "^" Expr 
      > Expr "||" Expr 
    | Expr "^" Expr 
      > Expr "^" Expr 
    | Expr "&" Expr 
      > Expr "^" Expr 
    | Expr "&" Expr 
      > Expr "|" Expr 
    | Expr "&" Expr 
      > Expr "&&" Expr 
    | Expr "&" Expr 
      > Expr "||" Expr 
    | Expr "&" Expr 
      > Expr "&" Expr 
    | Expr "|" Expr 
      > Expr "&&" Expr 
    | Expr "|" Expr 
      > Expr "||" Expr 
    | Expr "|" Expr 
      > Expr "|" Expr 
    | Expr "&&" Expr 
      > Expr "||" Expr 
    | Expr "&&" Expr 
      > Expr "&&" Expr 
    | Expr "||" Expr 
      > Expr "||" Expr 
    | Expr "+" !>> [+] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "float" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "double" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "-" !>> [\-] Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "^=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "|=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "&=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "%=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar ".=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "/=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "*=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "-=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "+=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "\<" !>> [\>] Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "-" !>> [\-] Expr 
      > List "=" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\>=" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\>" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\<=" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "!=" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\<\>" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "==" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\>\>" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\<\<" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "^" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "&" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "|" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "&&" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "||" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "." Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "!==" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "===" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "?" Expr ":" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "+" !>> [+] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "+" !>> [+] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "+" !>> [+] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "or" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "object" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "!" Expr 
      > Expr "-" !>> [\-] Expr 
    | "~" Expr 
      > Expr "-" !>> [\-] Expr 
    | "@" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "int" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "?" Expr ":" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "boolean" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "integer" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "real" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "object" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "int" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "+" !>> [+] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "+" !>> [+] Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | "+" !>> [+] Expr 
      > Expr "||" Expr 
    | "+" !>> [+] Expr 
      > Expr "&&" Expr 
    | "+" !>> [+] Expr 
      > Expr "|" Expr 
    | "+" !>> [+] Expr 
      > Expr "&" Expr 
    | "+" !>> [+] Expr 
      > Expr "^" Expr 
    | "+" !>> [+] Expr 
      > Expr "." Expr 
    | "+" !>> [+] Expr 
      > Expr "\<\<" Expr 
    | "+" !>> [+] Expr 
      > Expr "\>\>" Expr 
    | "+" !>> [+] Expr 
      > Expr "==" Expr 
    | "+" !>> [+] Expr 
      > Expr "\<\>" Expr 
    | "+" !>> [+] Expr 
      > Expr "!=" Expr 
    | "+" !>> [+] Expr 
      > Expr "\<=" Expr 
    | "+" !>> [+] Expr 
      > Expr "\>" Expr 
    | "+" !>> [+] Expr 
      > Expr "\>=" Expr 
    | "+" !>> [+] Expr 
      > Expr "===" Expr 
    | "+" !>> [+] Expr 
      > Expr "!==" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "!==" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "||" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "===" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!==" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "double" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "===" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "||" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!==" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "===" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "||" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "?" Expr ":" Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "bool" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "\<" !>> [\>] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | List "=" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | List "=" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | List "=" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\<" !>> [\>] Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "-" !>> [\-] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "||" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "&&" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "|" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "&" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "^" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "." Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "*" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "/" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "%" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\<\<" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\>\>" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "==" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\<\>" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "!=" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\<=" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\>" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "\>=" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "===" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "!==" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "integer" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "real" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "*" Expr 
      > "-" !>> [\-] Expr 
    | Expr "/" Expr 
      > "-" !>> [\-] Expr 
    | Expr "%" Expr 
      > "-" !>> [\-] Expr 
    | Expr "\<" !>> [\>] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "\>\>=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "\<\<=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "^=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "|=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "&=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "%=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar ".=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "/=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "*=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "-=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "+=" Expr 
    | Expr "?" Expr ":" Expr 
      > ObjectCVar "=" Expr 
    | "(" "double" ")" Expr 
      > Expr "===" Expr 
    | "(" "double" ")" Expr 
      > Expr "!==" Expr 
    | "(" "double" ")" Expr 
      > Expr "||" Expr 
    | "(" "double" ")" Expr 
      > Expr "&&" Expr 
    | "(" "double" ")" Expr 
      > Expr "|" Expr 
    | "(" "double" ")" Expr 
      > Expr "&" Expr 
    | "(" "double" ")" Expr 
      > Expr "^" Expr 
    | "(" "double" ")" Expr 
      > Expr "." Expr 
    | "(" "double" ")" Expr 
      > Expr "*" Expr 
    | "(" "double" ")" Expr 
      > Expr "/" Expr 
    | "(" "double" ")" Expr 
      > Expr "%" Expr 
    | "(" "double" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "double" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "double" ")" Expr 
      > Expr "==" Expr 
    | "(" "double" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "double" ")" Expr 
      > Expr "!=" Expr 
    | "(" "double" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "double" ")" Expr 
      > Expr "\>" Expr 
    | "(" "double" ")" Expr 
      > Expr "\>=" Expr 
    | Expr "!==" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "===" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "||" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "&&" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "|" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "&" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "^" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "." Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "*" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "/" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "%" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<\<" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>\>" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "==" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<\>" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "!=" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<=" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>=" Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "?" Expr ":" Expr 
    | "+" !>> [+] Expr 
      > Expr "+" !>> [+] Expr 
    | "print" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "print" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "print" !>> [0-9 A-Z _ a-z] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "int" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "int" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "int" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "object" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "object" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "bool" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "object" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "!==" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "===" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "||" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "(" "object" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "!" Expr 
      > Expr "+" !>> [+] Expr 
    | "~" Expr 
      > Expr "+" !>> [+] Expr 
    | "@" Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "int" ")" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "boolean" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "." Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "*" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "/" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "%" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\<\<" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\>\>" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\<=" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\>" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "\>=" Expr 
      > Expr "\<" !>> [\>] Expr 
    | Expr "-" !>> [\-] Expr 
      > "include_once" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "string" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "bool" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "?" Expr ":" Expr 
    | "-" !>> [\-] Expr 
      > Expr "+" !>> [+] Expr 
    | "(" "real" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "real" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "real" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "integer" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "integer" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "integer" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "float" ")" Expr 
      > Expr "+" !>> [+] Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "unset" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "float" ")" Expr 
      > Expr "!==" Expr 
    | "(" "float" ")" Expr 
      > Expr "===" Expr 
    | "(" "float" ")" Expr 
      > Expr "||" Expr 
    | "(" "float" ")" Expr 
      > Expr "&&" Expr 
    | "(" "float" ")" Expr 
      > Expr "|" Expr 
    | "(" "float" ")" Expr 
      > Expr "&" Expr 
    | "(" "float" ")" Expr 
      > Expr "^" Expr 
    | "(" "float" ")" Expr 
      > Expr "." Expr 
    | "(" "float" ")" Expr 
      > Expr "*" Expr 
    | "(" "float" ")" Expr 
      > Expr "/" Expr 
    | "(" "float" ")" Expr 
      > Expr "%" Expr 
    | "(" "float" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "float" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "float" ")" Expr 
      > Expr "==" Expr 
    | "(" "float" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "float" ")" Expr 
      > Expr "!=" Expr 
    | "(" "float" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "float" ")" Expr 
      > Expr "\>" Expr 
    | "(" "float" ")" Expr 
      > Expr "\>=" Expr 
    | Expr "-" !>> [\-] Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "-" !>> [\-] Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | "-" !>> [\-] Expr 
      > Expr "||" Expr 
    | "-" !>> [\-] Expr 
      > Expr "&&" Expr 
    | "-" !>> [\-] Expr 
      > Expr "|" Expr 
    | "-" !>> [\-] Expr 
      > Expr "&" Expr 
    | "-" !>> [\-] Expr 
      > Expr "^" Expr 
    | "-" !>> [\-] Expr 
      > Expr "." Expr 
    | "-" !>> [\-] Expr 
      > Expr "\<\<" Expr 
    | "-" !>> [\-] Expr 
      > Expr "\>\>" Expr 
    | "-" !>> [\-] Expr 
      > Expr "==" Expr 
    | "-" !>> [\-] Expr 
      > Expr "\<\>" Expr 
    | "-" !>> [\-] Expr 
      > Expr "!=" Expr 
    | "-" !>> [\-] Expr 
      > Expr "\<=" Expr 
    | "-" !>> [\-] Expr 
      > Expr "\>" Expr 
    | "-" !>> [\-] Expr 
      > Expr "\>=" Expr 
    | "-" !>> [\-] Expr 
      > Expr "===" Expr 
    | "-" !>> [\-] Expr 
      > Expr "!==" Expr 
    | "(" "int" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "bool" ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "bool" ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "bool" ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "?" Expr ":" Expr 
      > List "=" Expr 
    | "(" "object" ")" Expr 
      > Expr "\<" !>> [\>] Expr 
    | "(" "string" ")" Expr 
      > Expr "!==" Expr 
    | "(" "string" ")" Expr 
      > Expr "===" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "string" ")" Expr 
      > Expr "||" Expr 
    | "(" "string" ")" Expr 
      > Expr "&&" Expr 
    | "(" "string" ")" Expr 
      > Expr "|" Expr 
    | "(" "string" ")" Expr 
      > Expr "&" Expr 
    | "(" "string" ")" Expr 
      > Expr "^" Expr 
    | "(" "string" ")" Expr 
      > Expr "." Expr 
    | "(" "string" ")" Expr 
      > Expr "*" Expr 
    | "(" "string" ")" Expr 
      > Expr "/" Expr 
    | "(" "string" ")" Expr 
      > Expr "%" Expr 
    | "(" "string" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "string" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "string" ")" Expr 
      > Expr "==" Expr 
    | "(" "string" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "string" ")" Expr 
      > Expr "!=" Expr 
    | "(" "string" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "string" ")" Expr 
      > Expr "\>" Expr 
    | "(" "string" ")" Expr 
      > Expr "\>=" Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "+" !>> [+] Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "*" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "/" Expr 
      > Expr "-" !>> [\-] Expr 
    | Expr "%" Expr 
      > Expr "-" !>> [\-] Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "and" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "array" !>> [0-9 A-Z _ a-z] ")" Expr 
      > Expr "or" !>> [0-9 A-Z _ a-z] Expr 
    | "(" "real" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | "(" "integer" ")" Expr 
      > Expr "?" Expr ":" Expr 
    | Expr "or" !>> [0-9 A-Z _ a-z] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "xor" !>> [0-9 A-Z _ a-z] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "and" !>> [0-9 A-Z _ a-z] Expr 
      > "require_once" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!==" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "===" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "||" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "&&" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "|" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "&" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "^" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "." Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "*" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "/" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "%" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<\<" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>\>" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "==" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<\>" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "!=" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\<=" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "\>=" Expr 
      > "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    | Expr "||" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&&" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "|" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "&" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "^" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "." Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "*" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "/" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "%" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\<" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>\>" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "==" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<=" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!=" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<\>" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\>=" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "===" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "!==" Expr 
      > "print" !>> [0-9 A-Z _ a-z] Expr 
    | Expr "\<" !>> [\>] Expr 
      > Expr "?" Expr ":" Expr 
    | "!" Expr 
      > Expr "!==" Expr 
    | "~" Expr 
      > Expr "!==" Expr 
    | "@" Expr 
      > Expr "!==" Expr 
    | "!" Expr 
      > Expr "===" Expr 
    | "~" Expr 
      > Expr "===" Expr 
    | "@" Expr 
      > Expr "===" Expr 
    | "!" Expr 
      > Expr "||" Expr 
    | "!" Expr 
      > Expr "&&" Expr 
    | "!" Expr 
      > Expr "|" Expr 
    | "!" Expr 
      > Expr "&" Expr 
    | "!" Expr 
      > Expr "^" Expr 
    | "!" Expr 
      > Expr "." Expr 
    | "!" Expr 
      > Expr "*" Expr 
    | "!" Expr 
      > Expr "/" Expr 
    | "!" Expr 
      > Expr "%" Expr 
    | "!" Expr 
      > Expr "\<\<" Expr 
    | "!" Expr 
      > Expr "\>\>" Expr 
    | "!" Expr 
      > Expr "==" Expr 
    | "!" Expr 
      > Expr "\<\>" Expr 
    | "!" Expr 
      > Expr "!=" Expr 
    | "!" Expr 
      > Expr "\<=" Expr 
    | "!" Expr 
      > Expr "\>" Expr 
    | "!" Expr 
      > Expr "\>=" Expr 
    | "~" Expr 
      > Expr "||" Expr 
    | "~" Expr 
      > Expr "&&" Expr 
    | "~" Expr 
      > Expr "|" Expr 
    | "~" Expr 
      > Expr "&" Expr 
    | "~" Expr 
      > Expr "^" Expr 
    | "~" Expr 
      > Expr "." Expr 
    | "~" Expr 
      > Expr "*" Expr 
    | "~" Expr 
      > Expr "/" Expr 
    | "~" Expr 
      > Expr "%" Expr 
    | "~" Expr 
      > Expr "\<\<" Expr 
    | "~" Expr 
      > Expr "\>\>" Expr 
    | "~" Expr 
      > Expr "==" Expr 
    | "~" Expr 
      > Expr "\<\>" Expr 
    | "~" Expr 
      > Expr "!=" Expr 
    | "~" Expr 
      > Expr "\<=" Expr 
    | "~" Expr 
      > Expr "\>" Expr 
    | "~" Expr 
      > Expr "\>=" Expr 
    | "@" Expr 
      > Expr "||" Expr 
    | "@" Expr 
      > Expr "&&" Expr 
    | "@" Expr 
      > Expr "|" Expr 
    | "@" Expr 
      > Expr "&" Expr 
    | "@" Expr 
      > Expr "^" Expr 
    | "@" Expr 
      > Expr "." Expr 
    | "@" Expr 
      > Expr "*" Expr 
    | "@" Expr 
      > Expr "/" Expr 
    | "@" Expr 
      > Expr "%" Expr 
    | "@" Expr 
      > Expr "\<\<" Expr 
    | "@" Expr 
      > Expr "\>\>" Expr 
    | "@" Expr 
      > Expr "==" Expr 
    | "@" Expr 
      > Expr "\<\>" Expr 
    | "@" Expr 
      > Expr "!=" Expr 
    | "@" Expr 
      > Expr "\<=" Expr 
    | "@" Expr 
      > Expr "\>" Expr 
    | "@" Expr 
      > Expr "\>=" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "!==" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "===" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "||" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "&&" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "|" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "&" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "^" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "." Expr 
    | "(" "boolean" ")" Expr 
      > Expr "*" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "/" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "%" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\<\<" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\>\>" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "==" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\<\>" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "!=" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\<=" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\>" Expr 
    | "(" "boolean" ")" Expr 
      > Expr "\>=" Expr 
    | Expr "-" !>> [\-] Expr 
      > Expr "-" !>> [\-] Expr 
  ;

syntax ClassMember
  =  InstanceVariable: "var" !>> [0-9 A-Z _ a-z] {InstanceVariable ","}+ ";" 
    | FunctionDecl 
  ;

syntax PHPEchoOpenTag
  =  EchoOpenTag: "\<?=" 
  ;

syntax Variable
  = ObjectFunctionCall 
    | ObjectCVar 
  ;

syntax StaticScalar
  = Array 
    | ConstantVariable \ ConstantVariableKeywords 
    | @NotSupported="prefer"CommonScalar 
  ;

syntax HereDocPart
  =  Literal: HereDocLit !>> ![\n \r $ \\ {] 
  ;

lexical CaseSeperator
  = ":" 
    | ";" 
  ;

syntax SimpleVariableName
  =  Simple: String !>> [0-9 A-Z _ a-z] 
  ;

lexical EscapeSimpleVariable
  = TVariable 
  ;

syntax Null
  =  Null: "null" !>> [0-9 A-Z _ a-z] 
  ;

lexical BracedVariable
  =  Braced: "{" Variable "}" 
  ;

lexical DoubleQuotedPartSpecial
  = BracedVariable 
    | HexaCharacter 
    | OctaCharacter 
    | Escape 
    | EscapeVariable 
  ;

syntax ClassDecl
  =  Class: ClassType String !>> [0-9 A-Z _ a-z] ExtendsClause? "{" ClassMember* "}" 
  ;

syntax FunctionName
  =  FunctionName: String !>> [0-9 A-Z _ a-z] 
  ;

//lexical BlockCommentChars
//  = ![* \\]+ 
//  ;

lexical DQList
  =  DQContent: DQList DoubleQuotedPart? DQList 
    | DoubleQuotedPartSpecial 
  ;

//lexical EscChar
//  = "\\" 
//  ;

lexical OctaCharacter
  = OctaCharacterOne 
    | OctaCharacterThree 
    | OctaCharacterTwo 
  ;

lexical HexaCharacterTwo
  =  HexaChar: "\\" "x" [0-9 A-F a-f] [0-9 A-F a-f] 
  ;

lexical Keyword
  = "endwhile" !>> [0-9 A-Z _ a-z] 
    | "array" !>> [0-9 A-Z _ a-z] 
    | "foreach" !>> [0-9 A-Z _ a-z] 
    | "echo" !>> [0-9 A-Z _ a-z] 
    | "endfor" !>> [0-9 A-Z _ a-z] 
    | "old_function" !>> [0-9 A-Z _ a-z] 
    | "print" !>> [0-9 A-Z _ a-z] 
    | "__LINE__" !>> [0-9 A-Z _ a-z] 
    | "while" !>> [0-9 A-Z _ a-z] 
    | "unset" !>> [0-9 A-Z _ a-z] 
    | "endif" !>> [0-9 A-Z _ a-z] 
    | "case" !>> [0-9 A-Z _ a-z] 
    | "function" !>> [0-9 A-Z _ a-z] 
    | "include_once" !>> [0-9 A-Z _ a-z] 
    | "global" !>> [0-9 A-Z _ a-z] 
    | "require" !>> [0-9 A-Z _ a-z] !>> [_] 
    | "xor" !>> [0-9 A-Z _ a-z] 
    | "enddeclare" !>> [0-9 A-Z _ a-z] 
    | "elseif" !>> [0-9 A-Z _ a-z] 
    | "break" !>> [0-9 A-Z _ a-z] 
    | "parent" !>> [0-9 A-Z _ a-z] 
    | "list" !>> [0-9 A-Z _ a-z] 
    | "eval" !>> [0-9 A-Z _ a-z] 
    | "class" !>> [0-9 A-Z _ a-z] 
    | "false" !>> [0-9 A-Z _ a-z] 
    | "cfunction" !>> [0-9 A-Z _ a-z] 
    | "exit" !>> [0-9 A-Z _ a-z] 
    | "and" !>> [0-9 A-Z _ a-z] 
    | "new" !>> [0-9 A-Z _ a-z] 
    | "static" !>> [0-9 A-Z _ a-z] 
    | "include" !>> [0-9 A-Z _ a-z] !>> [_] 
    | "default" !>> [0-9 A-Z _ a-z] 
    | "__FILE__" !>> [0-9 A-Z _ a-z] 
    | "isset" !>> [0-9 A-Z _ a-z] 
    | "this" !>> [0-9 A-Z _ a-z] 
    | "__CLASS__" !>> [0-9 A-Z _ a-z] 
    | "var" !>> [0-9 A-Z _ a-z] 
    | "switch" !>> [0-9 A-Z _ a-z] 
    | "else" !>> [i] !>> [0-9 A-Z _ a-z] 
    | "endswitch" !>> [0-9 A-Z _ a-z] 
    | "as" !>> [0-9 A-Z _ a-z] 
    | "for" !>> [0-9 A-Z _ a-z] 
    | "continue" !>> [0-9 A-Z _ a-z] 
    | "die" !>> [0-9 A-Z _ a-z] 
    | "do" !>> [0-9 A-Z _ a-z] 
    | "extends" !>> [0-9 A-Z _ a-z] 
    | "declare" !>> [0-9 A-Z _ a-z] 
    | "empty" !>> [0-9 A-Z _ a-z] 
    | "return" !>> [0-9 A-Z _ a-z] 
    | "require_once" !>> [0-9 A-Z _ a-z] 
    | "if" !>> [0-9 A-Z _ a-z] 
    | "endforeach" !>> [0-9 A-Z _ a-z] 
    | "or" !>> [0-9 A-Z _ a-z] 
    | "use" !>> [0-9 A-Z _ a-z] 
    | "true" !>> [0-9 A-Z _ a-z] 
    | "null" !>> [0-9 A-Z _ a-z] 
    | "__FUNCTION__" !>> [0-9 A-Z _ a-z] 
  ;

lexical HereDocList
  =  HereDocContent: HereDocList HereDocPart? HereDocList 
    | HereDocPartSpecial 
  ;

lexical Hexa
  = [0] [X x] [0-9 A-F a-f]+ 
  ;

lexical Deci
  = [0] 
    | [1-9] [0-9]* 
  ;

syntax Directive
  =  Directive: String !>> [0-9 A-Z _ a-z] "=" StaticScalar 
  ;

syntax CallParam
  =  Param: Expr 
    |  RefParam: "&" Expr 
  ;

lexical SlashCharLit
  = "\\" 
  ;

syntax StaticVariable
  =  StaticVariable: TVariable 
    |  StaticVariable: TVariable "=" StaticScalar 
  ;

keyword ConstantVariableKeywords
  = Keyword 
    | MagicConstant 
  ;

//syntax LAYOUT
//  = [\t-\n \r \ ] 
//    | Comment 
//  ;

lexical LAYOUT = Comment | [\t-\n \r \ ] ;

//lexical EOLCommentChars
//  = (![\n \r ?] | EOLCommentQuestionMark)* 
//  ;

//lexical BeforeCloseTag
//  = 
//  ;

lexical CurlyBracketLit
  = "{" 
  ;

syntax ForEachKey
  =  Key: ForEachVar "=\>" 
  ;

syntax LNumber
  =  Deci: Deci !>> [. 0-9] 
    |  Octa: Octa !>> [0-9] 
    |  Hexa: Hexa !>> [0-9 A-F a-f] 
  ;

syntax ClassType
  =  Normal: "class" !>> [0-9 A-Z _ a-z] 
  ;

lexical InlineHTMLChar
  = ![\<] 
  ;

lexical EmbeddedString
  =  EmbeddedString: "\'" String !>> [0-9 A-Z _ a-z] "\'" 
  ;

syntax ArrayPair
  =  Pair: ArrayKey? ArrayValue 
  ;

syntax AltElseifStatement
  =  AltElseIf: "elseif" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" TopStatement* 
  ;

syntax CommonScalarType
  =  LNumber: LNumber 
    |  MagicConstant: MagicConstant 
    | Null 
    |  ConstantEncapsedString: ConstantEncapsedString 
    | Bool 
    |  DNumber: DNumber !>> [0-9] \ DNumberKeywords 
  ;

syntax FullyQualifiedClassName
  =  ClassName: String !>> [0-9 A-Z _ a-z] 
  ;

lexical InlineHTMLChars
  =  Literal: InlineHTMLChar+ 
  ;

syntax List
  =  List: "list" !>> [0-9 A-Z _ a-z] "(" AssignmentListElem? ")" 
    |  List: "list" !>> [0-9 A-Z _ a-z] "(" {AssignmentListElem? ","}+ ")" 
  ;

//lexical EscEscChar
//  = "\\\\" 
//  ;

syntax TopStatement
  = Statement 
    | FunctionDecl 
    | ClassDecl 
  ;

//lexical CommentPart
//  = Asterisk !>> [/] 
//    | EscChar !>> [\\ u] 
//    | BlockCommentChars !>> ![* \\] 
//    | EscEscChar 
//  ;

lexical CommentPart = "*" !>> [/] | "\\" !>> [\\ u] | ![* \\]+ !>> ![* \\] | "\\\\" ;

syntax ArrayValue
  =  RefValue: "&" ObjectCVar 
    |  Value: Expr 
  ;

syntax ElseIfStatement
  =  ElseIf: "elseif" !>> [0-9 A-Z _ a-z] "(" Expr ")" TopStatementBlock 
  ;

lexical MagicConstant
  = "__FILE__" 
    | "__LINE__" 
    | "__CLASS__" 
    | "__FUNCTION__" 
  ;

lexical HereDocContent
  =  HereDocContent: HereDocPart? HereDocList HereDocPart? 
    |  HereDocContent: HereDocPart? 
  ;

syntax Array
  =  Array: "array" !>> [0-9 A-Z _ a-z] "(" {ArrayPair ","}* ")" 
    |  Array: "array" !>> [0-9 A-Z _ a-z] "(" {ArrayPair ","}+ "," ")" 
  ;

syntax VariableName
  = SimpleVariableName 
    |  Braced: "{" Expr "}" 
    | @NotSupported="prefer" Braced: "{" SimpleVariableName "}" 
  ;

syntax ReferenceVariable
  =  ArrayAccess: ReferenceVariable "[" Expr? "]" 
    | CompoundVariable 
    |  StringAccess: ReferenceVariable "{" Expr "}" 
  ;

lexical DQContent
  =  DQContent: DoubleQuotedPart? 
    |  DQContent: DoubleQuotedPart? DQList DoubleQuotedPart? 
  ;

//lexical DNumber
//  = (DNumber | [0-9]+) [E e] [+ \-]? [0-9]+ 
//    | @NotSupported="prefer"[0-9]* [.] [0-9]+ 
//    | [0-9]+ [.] [0-9]* 
//  ;

lexical DNumber
  = [0-9]+[.][0-9]* !>> [0-9]
  | [0-9] !<< [.][0-9]+ !>> [0-9]
  | [0-9]+[.][0-9]*[E e] [+ \-]? [0-9]+ !>> [0-9]
  | [0-9] !<< [.][0-9]+[E e] [+ \-]? [0-9]+ !>> [0-9]
  ;

syntax FunctionDecl
  =  FunctionDeclRef: "function" !>> [0-9 A-Z _ a-z] "&" String !>> [0-9 A-Z _ a-z] "(" {Param ","}* ")" "{" TopStatement* "}" 
    |  OldFunctionDecl: "old_function" !>> [0-9 A-Z _ a-z] String !>> [0-9 A-Z _ a-z] {Param ","}* "(" Statement* ")" ";" 
    |  FunctionDecl: "function" !>> [0-9 A-Z _ a-z] String !>> [0-9 A-Z _ a-z] "(" {Param ","}* ")" "{" TopStatement* "}" 
    |  OldFunctionDeclRef: "old_function" !>> [0-9 A-Z _ a-z] "&" String !>> [0-9 A-Z _ a-z] {Param ","}* "(" Statement* ")" ";" 
  ;

syntax ObjectCVar
  =  ObjectAccess: ObjectCVar "-\>" ObjectProperty 
    | CVar 
  ;

lexical EEscape
  =  Escape: "\\" [`] 
  ;

syntax Statement
  =  DoWhile: "do" !>> [0-9 A-Z _ a-z] TopStatementBlock "while" !>> [0-9 A-Z _ a-z] "(" Expr ")" ";" 
    |  Echo: "echo" !>> [0-9 A-Z _ a-z] {Expr ","}+ ";" 
    |  AltWhile: "while" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" TopStatement* "endwhile" ";" 
    |  Continue: "continue" !>> [0-9 A-Z _ a-z] Expr? ";" 
    |  Declare: "declare" !>> [0-9 A-Z _ a-z] "(" Directive* ")" Statement 
    |  Unset: "unset" !>> [0-9 A-Z _ a-z] "(" {ObjectCVar ","}+ ")" ";" 
    |  AltSwitch: "switch" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" Case* "endswitch" !>> [0-9 A-Z _ a-z] ";" 
    |  Return: "return" !>> [0-9 A-Z _ a-z] Expr? ";" 
    |  While: "while" !>> [0-9 A-Z _ a-z] "(" Expr ")" TopStatementBlock 
    |  AltFor: "for" !>> [0-9 A-Z _ a-z] "(" {Expr ","}* ";" {Expr ","}* ";" {Expr ","}* ")" ":" Statement* "endfor" !>> [0-9 A-Z _ a-z] ";" 
    |  Expr: Expr ";" 
    |  DeclareStatic: "static" !>> [0-9 A-Z _ a-z] {StaticVariable ","}+ ";" 
    |  DeclareGlobal: "global" !>> [0-9 A-Z _ a-z] {CVar ","}+ ";" 
    |  Empty: ";" 
    |  AltIf: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" TopStatement* AltElseifStatement* "else" !>> [i] !>> [0-9 A-Z _ a-z] ":" TopStatement* "endif" !>> [0-9 A-Z _ a-z] ";" 
    |  Block: "{" Statement* "}" 
    | @NotSupported="prefer" If: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" TopStatementBlock 
    |  AltIf: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" TopStatement* "endif" !>> [0-9 A-Z _ a-z] ";" 
    |  Expr: Expr HiddenSemicolon !>> [;] 
    |  AltForEach: "foreach" !>> [0-9 A-Z _ a-z] "(" Expr "as" !>> [0-9 A-Z _ a-z] ForEachPattern ")" ":" Statement* "endforeach" !>> [0-9 A-Z _ a-z] ";" 
    |  Break: "break" !>> [0-9 A-Z _ a-z] Expr? ";" 
    | @NotSupported="prefer" If: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" TopStatementBlock ElseIfStatement+ 
    |  AltSwitch: "switch" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" ";" Case* "endswitch" !>> [0-9 A-Z _ a-z] ";" 
    |  Echo: "echo" !>> [0-9 A-Z _ a-z] {Expr ","}+ HiddenSemicolon !>> [;] 
    |  AltIf: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" ":" TopStatement* AltElseifStatement+ "endif" !>> [0-9 A-Z _ a-z] ";" 
    |  For: "for" !>> [0-9 A-Z _ a-z] "(" {Expr ","}* ";" {Expr ","}* ";" {Expr ","}* ")" Statement 
    |  Switch: "switch" !>> [0-9 A-Z _ a-z] "(" Expr ")" "{" Case* "}" 
    |  ForEach: "foreach" !>> [0-9 A-Z _ a-z] "(" Expr "as" !>> [0-9 A-Z _ a-z] ForEachPattern ")" Statement 
    |  InlineHTML: PHPCloseTag InlineHTML PHPOpenTag 
    |  Switch: "switch" !>> [0-9 A-Z _ a-z] "(" Expr ")" "{" ";" Case* "}" 
    |  If: "if" !>> [0-9 A-Z _ a-z] "(" Expr ")" TopStatementBlock ElseIfStatement* "else" !>> [i] !>> [0-9 A-Z _ a-z] TopStatementBlock 
  ;

syntax DoubleQuotedPart
  =  Literal: DoubleQuotedLit !>> ![\" $ \\ {] 
  ;

lexical HereDocLineTerminator
  = LineTerminator 
  ;

syntax ExtendsClause
  =  Extends: "extends" !>> [0-9 A-Z _ a-z] String !>> [0-9 A-Z _ a-z] 
  ;

lexical Escape
  =  Escape: "\\" [\" $ \' \\ n r t] 
  ;

lexical CommandPart
  = EEscape 
    | HexaCharacter 
    |  Literal: CommandLit !>> ![$ \\ ` {] 
    | Escape 
    | OctaCharacter 
    | EscapeVariable 
    | BracedVariable 
  ;

//lexical Comment
//  = @NotSupported="avoid""#" EOLCommentChars !>> ![\n-\013 ?] BeforeCloseTag 
//    | @NotSupported="avoid""//" EOLCommentChars !>> ![\n-\013 ?] BeforeCloseTag 
//    | "#" EOLCommentChars !>> ![\n-\013 ?] LineTerminator 
//    | "/*" CommentPart* "*/" 
//    | "//" EOLCommentChars !>> ![\n-\013 ?] LineTerminator 
//  ;

lexical Comment
	= @category="Comment" "/*" (![*] | [*] !>> [/])* "*/" 
	| @category="Comment" "//" ![\n]* [\n]
	| @category="Comment" "#" ![\n]* [\n]
	;

syntax CommonScalar
  =  Positive: "+" !>> [+] CommonScalarType 
    | CommonScalarType 
    |  Negative: "-" !>> [\-] CommonScalarType 
  ;

syntax ObjectProperty
  =  ArrayAccess: ObjectProperty "[" Expr? "]" 
    |  ObjectProperty: ObjectCVar 
    |  ObjectProperty: VariableName 
    |  StringAccess: ObjectProperty "{" Expr "}" 
  ;

syntax ObjectFunctionCall
  =  FunctionCall: ObjectCVar "-\>" ObjectProperty "(" {CallParam ","}* ")" 
  ;

lexical EscapeVariable
  =  BracedArrayAccess: EmbeddedArrayVariable "[" EmbeddedString "]" "}" 
    |  BracedArrayAccess: EmbeddedArrayVariable "[" LNumber "]" "}" 
    |  ArrayAccess: TVariable "[" String !>> [0-9 A-Z _ a-z] "]" 
    |  VariableBraced: "${" String !>> [0-9 A-Z _ a-z] "}" 
    | EscapeSimpleVariable 
    |  ArrayAccess: TVariable "[" LNumber "]" 
    |  ObjectAccess: TVariable "-\>" String !>> [0-9 A-Z _ a-z] 
    |  BracedArrayAccess: EmbeddedArrayVariable "[" CompoundVariable "]" "}" 
    |  ArrayAccess: TVariable "[" CompoundVariable "]" 
    |  BracedArrayAccess: "${" String !>> [0-9 A-Z _ a-z] "[" String !>> [0-9 A-Z _ a-z] "]" "}" 
  ;

syntax InternalFunction
  =  Eval: "eval" !>> [0-9 A-Z _ a-z] "(" Expr ")" 
    |  Include: "include" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    |  Require: "require" !>> [0-9 A-Z _ a-z] !>> [_] Expr 
    |  Isset: "isset" !>> [0-9 A-Z _ a-z] "(" {ObjectCVar ","}+ ")" 
    |  Empty: "empty" !>> [0-9 A-Z _ a-z] "(" ObjectCVar ")" 
    |  RequireOnce: "require_once" !>> [0-9 A-Z _ a-z] Expr 
    |  IncludeOnce: "include_once" !>> [0-9 A-Z _ a-z] Expr 
  ;

lexical HereDocStart
  =  HereDocStart: "\<\<\<"  !>> [\t-\n \r \ ] String !>> [0-9 A-Z _ a-z] 
  ;

//lexical Document
//  =  Document: InlineHTML PHPOpenTag  !>> [\t-\n \r \ ] TopStatement*  !>> [\t-\n \r \ ] 
//    |  Document: InlineHTML PHPOpenTag  !>> [\t-\n \r \ ] TopStatement*  !>> [\t-\n \r \ ] PHPCloseTag InlineHTML 
//    |  TemplateDocument: InlineHTML 
//  ;

syntax Document
  =  Document: InlineHTML !>> [\t-\n \r \ ] PHPOpenTag TopStatement* 
    |  Document: InlineHTML !>> [\t-\n \r \ ] PHPOpenTag TopStatement* PHPCloseTag [\t-\n \r \ ] !<< InlineHTML 
    |  TemplateDocument: InlineHTML 
  ;

syntax Case
  =  DefaultCase: "default" !>> [0-9 A-Z _ a-z] CaseSeperator TopStatement* 
    |  Case: "case" !>> [0-9 A-Z _ a-z] Expr CaseSeperator TopStatement* 
  ;

syntax InstanceVariable
  =  Default: TVariable "=" StaticScalar 
    |  Normal: TVariable 
  ;

lexical OctaCharacterThree
  =  OctaChar: "\\" [0-7] [0-7] [0-7] 
  ;

//lexical CommandPart+
//  = @NotSupported="avoid"CommandPart+ CommandPart+ 
//  ;

lexical SEscape
  =  Escape: "\\" [\' \\] 
  ;

syntax AssignmentListElem
  = ObjectCVar 
    | List 
  ;

lexical HereDocEnd
  = LineTerminator String !>> [0-9 A-Z _ a-z] 
  ;

lexical String
  = [A-Z _ a-z] [0-9 A-Z _ a-z]* 
  ;

syntax ForEachPattern
  =  Pattern: ForEachKey? ForEachVar 
  ;

syntax ArrayKey
  =  Key: Expr "=\>" 
  ;

//lexical EndOfFile
//  = 
//  ;

syntax CompoundVariable
  =  Variable: "$" VariableName 
  ;

syntax DynamicClassNameReference
  = ObjectCVar 
  ;

syntax CVar
  = ReferenceVariable 
    |  IndirectReference: "$" CVar 
  ;

syntax InlineHTML
  = InlineHtmlPart* 
  ;

syntax ConstantVariable
  =  ConstantVariable: String !>> [0-9 A-Z _ a-z] 
  ;

lexical ESlashCharLit
  = SlashCharLit !>> [0-7] !>> [\" $ \' \\ n r t] 
  ;

lexical HiddenSemicolon
  = 
  ;

lexical SingleQuotedLit
  = (SSlashCharLit | ![\' \\])+ 
  ;

//lexical CarriageReturn
//  = [\r] 
//  ;

syntax Param
  =  ParamRef: "&" TVariable 
    |  Param: TVariable 
    |  ParamConstant: "const" TVariable 
    |  ParamDefault: TVariable "=" StaticScalar 
  ;

keyword FunctionNameKeywords
  = "unset" !>> [0-9 A-Z _ a-z] 
    | "else" !>> [i] !>> [0-9 A-Z _ a-z] 
    | "global" !>> [0-9 A-Z _ a-z] 
    | "include_once" !>> [0-9 A-Z _ a-z] 
    | "require" !>> [0-9 A-Z _ a-z] !>> [_] 
    | "while" !>> [0-9 A-Z _ a-z] 
    | "isset" !>> [0-9 A-Z _ a-z] 
    | "print" !>> [0-9 A-Z _ a-z] 
    | "static" !>> [0-9 A-Z _ a-z] 
    | "include" !>> [0-9 A-Z _ a-z] !>> [_] 
    | "array" !>> [0-9 A-Z _ a-z] 
    | "echo" !>> [0-9 A-Z _ a-z] 
    | "declare" !>> [0-9 A-Z _ a-z] 
    | "empty" !>> [0-9 A-Z _ a-z] 
    | "return" !>> [0-9 A-Z _ a-z] 
    | "require_once" !>> [0-9 A-Z _ a-z] 
    | "if" !>> [0-9 A-Z _ a-z] 
    | "exit" !>> [0-9 A-Z _ a-z] 
    | "break" !>> [0-9 A-Z _ a-z] 
    | "continue" !>> [0-9 A-Z _ a-z] 
    | "die" !>> [0-9 A-Z _ a-z] 
    | "eval" !>> [0-9 A-Z _ a-z] 
    | "elseif" !>> [0-9 A-Z _ a-z] 
  ;

lexical HexaCharacter
  = HexaCharacterTwo 
    | HexaCharacterOne 
  ;

lexical SingleQuotedPart
  =  Literal: SingleQuotedLit !>> ![\' \\] 
    | SEscape 
  ;

lexical NonOpenTag
  =  Literal: "\<" !>> [\>] ![% ?] 
  ;

lexical DoubleQuotedLit
  = (DollarCharLit | CurlyBracketLit | ![\" $ \\ {] | SlashCharLit)+ 
  ;

lexical HereDocPartSpecial
  = HexaCharacter 
    | Escape 
    | OctaCharacter 
    | EscapeVariable 
    | BracedVariable 
  ;

syntax FunctionCall
  =  FunctionCall: FunctionName \ FunctionNameKeywords "(" {CallParam ","}* ")" 
    |  StaticFunctionCall: FullyQualifiedClassName "::" CVar "(" {CallParam ","}* ")" 
    |  StaticFunctionCall: FullyQualifiedClassName "::" FunctionName \ FunctionNameKeywords "(" {CallParam ","}* ")" 
    |  FunctionCall: CVar "(" {CallParam ","}* ")" 
  ;

keyword DNumberKeywords
  = [0-9]+ 
  ;

syntax TopStatementBlock
  =  Block: "{" TopStatement* "}" 
    | TopStatement 
  ;

//lexical LineTerminator
//  = CarriageReturn !>> [\n] 
//    | [\r] [\n] 
//    | EndOfFile !>> ![] 
//    | [\n] 
//  ;

lexical LineTerminator
  = [\r] !>> [\n] 
    | [\r] [\n] 
    | [\n] 
  ;

syntax TVariable
  =  Variable: "$" SimpleVariableName 
  ;

syntax InlineEcho
  =  InlineEcho: PHPEchoOpenTag Expr Semicolon PHPCloseTag 
  ;

syntax ConstantEncapsedString
  =  HereDoc: HereDocStart HereDocContent HereDocEnd !>> ![\n \r ;] 
    |  DoubleQuoted: "\"" DQContent "\"" 
    |  SingleQuoted: "\'" SingleQuotedPart* "\'" 
  ;

lexical SSlashCharLit
  = "\\" 
  ;

syntax ForEachVar
  = CVar 
  ;

syntax PHPCloseTag
  =  CloseTag: "?\>" 
    |  ASPCloseTag: "%\>" 
  ;

//lexical Asterisk
//  = "*" 
//  ;

syntax PHPOpenTag
  =  FullOpenTag: "\<?php" 
    |  ShortOpenTag: "\<?" !>> [P p] 
    |  ASPOpenTag: "\<%" 
  ;

//lexical EOLCommentQuestionMark
//  = "?" 
//  ;

lexical Semicolon
  = HiddenSemicolon !>> [;] 
    | ";" 
  ;
