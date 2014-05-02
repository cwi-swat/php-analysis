module lang::php::\syntax::PHP4 

lexical HereDocLit
  = (![\n \r $ \\ {] | CurlyBracketLit | SlashCharLit | DollarCharLit | HereDocLineTerminator)+ 
  ;

lexical CommandLit
  = (DollarCharLit | CurlyBracketLit | ![$ \\ ` {] | ESlashCharLit)+ 
  ;

lexical EmbeddedArrayVariable
  =  EmbeddedArrayVariable: "${" String  
  ;

syntax New
  =  ObjectCreation: "new"  ClassNameReference 
    |  ObjectCreation: "new"  ClassNameReference "(" {CallParam ","}* ")" 
  ;

lexical OctaCharacterTwo
  =  OctaChar: "\\" [0-7] [0-7] 
  ;

lexical DollarCharLit
  = "$" 
  ;

syntax Bool
  =  False: "false"  
    |  True: "true"  
  ;

lexical HexaCharacterOne
  =  HexaChar: "\\" "x" [0-9 A-F a-f] 
  ;

syntax ClassNameReference
  =  ClassName: String  
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

layout LAYOUTLIST = LAYOUT* !>> [\t-\n \r \ ] !>> "//" !>> "/*" !>> "#";

syntax Expr
  =  New:     New
  >  Array:   Array  
  |  PostDec: ObjectCVar "--" 
  |  PostInc: ObjectCVar "++"
  |  PreDec: "--" ObjectCVar 
  |  PreInc: "++" ObjectCVar
  >  Neg: "~" Expr
  |  Negative: "-" Expr
  |  Positive: "+" Expr 
  |  ErrorFree: "@" Expr 
  | Not: "!" Expr
  |  IntCast: "(" "int" ")" Expr
  |  FloatCast: "(" "double" ")" Expr 
  |  BoolCast: "(" "boolean" ")" Expr 
  |  StringCast: "(" "string" ")" Expr
  |  NullCast: "(" "unset" ")" Expr 
  |  IntCast: "(" "integer" ")" Expr 
  |  FloatCast: "(" "float" ")" Expr 
  |  BoolCast: "(" "bool" ")" Expr 
  |  ArrayCast: "(" "array" ")" Expr 
  |  ObjectCast: "(" "object" ")" Expr
  |  FloatCast: "(" "real" ")" Expr
  > left ( Mul: Expr "*" Expr
         | Mod: Expr "%" Expr
         | Div: Expr "/" Expr 
  )
  > left ( Plus: Expr "+" Expr      
         | Min: Expr "-" Expr 
         |  Concat: Expr "." Expr 
  )
  > left ( SR: Expr "\>\>" Expr 
         | SL: Expr "\<\<" Expr 
  )
  > non-assoc (  Less: Expr "\<" Expr 
              |  GreaterEqual: Expr "\>=" Expr 
              |  LessEqual: Expr "\<=" Expr
              |  Greater: Expr "\>" Expr 
              ) 
  > non-assoc (  IsEqual: Expr "==" Expr 
              |  IsIdentical: Expr "===" Expr 
              |  IsNotIdentical: Expr "!==" Expr 
              |  IsNotEqual: Expr "!=" Expr
              |  IsNotEqual: Expr "\<\>" Expr
              )          
  > left BinAnd: Expr "&" Expr
  > left BinOr: Expr "|" Expr
  > left BinXor: Expr "^" Expr 
  > left And: Expr "&&" Expr 
  > left Or: Expr "||" Expr 
  > left Ternary: Expr "?" Expr ":" Expr 
  > right (
       ReferenceAssign: ObjectCVar "=" "&" ObjectFunctionCall 
    |  ReferenceAssign: ObjectCVar "=" "&" ObjectCVar 
    |  PlusAssign: ObjectCVar "+=" Expr 
    |  SRAssign: ObjectCVar "\>\>=" Expr
    |  SLAssign: ObjectCVar "\<\<=" Expr 
    |  ReferenceAssign: ObjectCVar "=" "&" FunctionCall 
    |  ReferenceAssign: ObjectCVar "=" "&" New 
    |  OrAssign: ObjectCVar "|=" Expr 
    |  DivAssign: ObjectCVar "/=" Expr 
    |  MulAssign: ObjectCVar "*=" Expr 
    |  AndAssign: ObjectCVar "&=" Expr 
    |  Assign: ObjectCVar "=" Expr 
    |  ListAssign: List "=" Expr 
    |  MinAssign: ObjectCVar "-=" Expr 
    |  XorAssign: ObjectCVar "^=" Expr 
    |  ModAssign: ObjectCVar "%=" Expr 
    |  ConcatAssign: ObjectCVar ".=" Expr 
  )
  > left LAnd: Expr "and" Expr
  > left LXor: Expr "xor" Expr
  > left LOr: Expr "or" Expr 
  ;

syntax Expr
   = Scalar: CommonScalar 
   | Var: Variable
   | FunctionCall
   | ConstantVariable \ ConstantVariableKeywords
   | InternalFunction: InternalFunction 
   | Die: "die" 
   | Die: "die" "(" ")" 
   | Die: "die" "(" Expr ")"
   | Exit: "exit"  
   | Exit: "exit" "(" Expr ")" 
   | Exit: "exit" "(" ")" 
   | Print: "print" Expr 
   | ShellCommand: "`" CommandPart* "`" 
   | bracket "(" Expr ")" 
   ;

    
syntax ClassMember
  =  InstanceVariable: "var"  {InstanceVariable ","}+ ";" 
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
  =  Simple: String  
  ;

lexical EscapeSimpleVariable
  = TVariable 
  ;

syntax Null
  =  Null: "null"  
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
  =  Class: ClassType String  ExtendsClause? "{" ClassMember* "}" 
  ;

syntax FunctionName
  =  FunctionName: String  
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
  = "endwhile"  
    | "array"  
    | "foreach"  
    | "echo"  
    | "endfor"  
    | "old_function"  
    | "print"  
    | "__LINE__"  
    | "while"  
    | "unset"  
    | "endif"  
    | "case"  
    | "function"  
    | "include_once"  
    | "global"  
    | "require"  !>> [_] 
    | "xor"  
    | "enddeclare"  
    | "elseif"  
    | "break"  
    | "parent"  
    | "list"  
    | "eval"  
    | "class"  
    | "false"  
    | "cfunction"  
    | "exit"  
    | "and"  
    | "new"  
    | "static"  
    | "include"  !>> [_] 
    | "default"  
    | "__FILE__"  
    | "isset"  
    | "this"  
    | "__CLASS__"  
    | "var"  
    | "switch"  
    | "else" !>> [i]  
    | "endswitch"  
    | "as"  
    | "for"  
    | "continue"  
    | "die"  
    | "do"  
    | "extends"  
    | "declare"  
    | "empty"  
    | "return"  
    | "require_once"  
    | "if"  
    | "endforeach"  
    | "or"  
    | "use"  
    | "true"  
    | "null"  
    | "__FUNCTION__"  
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
  =  Directive: String  "=" StaticScalar 
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
  =  Normal: "class"  
  ;

lexical InlineHTMLChar
  = ![\<] 
  ;

lexical EmbeddedString
  =  EmbeddedString: "\'" String  "\'" 
  ;

syntax ArrayPair
  =  Pair: ArrayKey? ArrayValue 
  ;

syntax AltElseifStatement
  =  AltElseIf: "elseif"  "(" Expr ")" ":" TopStatement* 
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
  =  ClassName: String  
  ;

lexical InlineHTMLChars
  =  Literal: InlineHTMLChar+ 
  ;

syntax List
  =  List: "list"  "(" AssignmentListElem? ")" 
    |  List: "list"  "(" {AssignmentListElem? ","}+ ")" 
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
  =  ElseIf: "elseif"  "(" Expr ")" TopStatementBlock 
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
  =  Array: "array"  "(" {ArrayPair ","}* ")" 
  |  Array: "array"  "(" {ArrayPair ","}+ "," ")" 
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
  =  FunctionDeclRef: "function"  "&" String  "(" {Param ","}* ")" "{" TopStatement* "}" 
    |  OldFunctionDecl: "old_function"  String  {Param ","}* "(" Statement* ")" ";" 
    |  FunctionDecl: "function"  String  "(" {Param ","}* ")" "{" TopStatement* "}" 
    |  OldFunctionDeclRef: "old_function"  "&" String  {Param ","}* "(" Statement* ")" ";" 
  ;

syntax ObjectCVar
  =  ObjectAccess: ObjectCVar "-\>" ObjectProperty 
    | CVar 
  ;

lexical EEscape
  =  Escape: "\\" [`] 
  ;

syntax Statement
  =  DoWhile: "do"  TopStatementBlock "while"  "(" Expr ")" ";" 
    |  Echo: "echo"  {Expr ","}+ ";" 
    |  AltWhile: "while"  "(" Expr ")" ":" TopStatement* "endwhile" ";" 
    |  Continue: "continue"  Expr? ";" 
    |  Declare: "declare"  "(" Directive* ")" Statement 
    |  Unset: "unset"  "(" {ObjectCVar ","}+ ")" ";" 
    |  AltSwitch: "switch"  "(" Expr ")" ":" Case* "endswitch"  ";" 
    |  Return: "return"  Expr? ";" 
    |  While: "while"  "(" Expr ")" TopStatementBlock 
    |  AltFor: "for"  "(" {Expr ","}* ";" {Expr ","}* ";" {Expr ","}* ")" ":" Statement* "endfor"  ";" 
    |  Expr: Expr ";" 
    |  DeclareStatic: "static"  {StaticVariable ","}+ ";" 
    |  DeclareGlobal: "global"  {CVar ","}+ ";" 
    |  Empty: ";" 
    |  AltIf: "if"  "(" Expr ")" ":" TopStatement* AltElseifStatement* "else" !>> [i]  ":" TopStatement* "endif"  ";" 
    |  Block: "{" Statement* "}" 
    | @NotSupported="prefer" If: "if"  "(" Expr ")" TopStatementBlock 
    |  AltIf: "if"  "(" Expr ")" ":" TopStatement* "endif"  ";" 
    |  Expr: Expr HiddenSemicolon !>> [;] 
    |  AltForEach: "foreach"  "(" Expr "as"  ForEachPattern ")" ":" Statement* "endforeach"  ";" 
    |  Break: "break"  Expr? ";" 
    | @NotSupported="prefer" If: "if"  "(" Expr ")" TopStatementBlock ElseIfStatement+ 
    |  AltSwitch: "switch"  "(" Expr ")" ":" ";" Case* "endswitch"  ";" 
    |  Echo: "echo"  {Expr ","}+ HiddenSemicolon !>> [;] 
    |  AltIf: "if"  "(" Expr ")" ":" TopStatement* AltElseifStatement+ "endif"  ";" 
    |  For: "for"  "(" {Expr ","}* ";" {Expr ","}* ";" {Expr ","}* ")" Statement 
    |  Switch: "switch"  "(" Expr ")" "{" Case* "}" 
    |  ForEach: "foreach"  "(" Expr "as"  ForEachPattern ")" Statement 
    |  InlineHTML: PHPCloseTag InlineHTML PHPOpenTag 
    |  Switch: "switch"  "(" Expr ")" "{" ";" Case* "}" 
    |  If: "if"  "(" Expr ")" TopStatementBlock ElseIfStatement* "else" !>> [i]  TopStatementBlock 
  ;

syntax DoubleQuotedPart
  =  Literal: DoubleQuotedLit !>> ![\" $ \\ {] 
  ;

lexical HereDocLineTerminator
  = LineTerminator 
  ;

syntax ExtendsClause
  =  Extends: "extends"  String  
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
    |  ArrayAccess: TVariable "[" String  "]" 
    |  VariableBraced: "${" String  "}" 
    | EscapeSimpleVariable 
    |  ArrayAccess: TVariable "[" LNumber "]" 
    |  ObjectAccess: TVariable "-\>" String  
    |  BracedArrayAccess: EmbeddedArrayVariable "[" CompoundVariable "]" "}" 
    |  ArrayAccess: TVariable "[" CompoundVariable "]" 
    |  BracedArrayAccess: "${" String  "[" String  "]" "}" 
  ;

syntax InternalFunction
  =  Eval: "eval"  "(" Expr ")" 
    |  Include: "include"  !>> [_] Expr 
    |  Require: "require"  !>> [_] Expr 
    |  Isset: "isset"  "(" {ObjectCVar ","}+ ")" 
    |  Empty: "empty"  "(" ObjectCVar ")" 
    |  RequireOnce: "require_once"  Expr 
    |  IncludeOnce: "include_once"  Expr 
  ;

lexical HereDocStart
  =  HereDocStart: "\<\<\<"  !>> [\t-\n \r \ ] String  
  ;

//lexical Document
//  =  Document: InlineHTML PHPOpenTag  !>> [\t-\n \r \ ] TopStatement*  !>> [\t-\n \r \ ] 
//    |  Document: InlineHTML PHPOpenTag  !>> [\t-\n \r \ ] TopStatement*  !>> [\t-\n \r \ ] PHPCloseTag InlineHTML 
//    |  TemplateDocument: InlineHTML 
//  ;

start syntax Document
  =  Document: InlineHTML !>> [\t-\n \r \ ] PHPOpenTag TopStatement* 
    |  Document: InlineHTML !>> [\t-\n \r \ ] PHPOpenTag TopStatement* PHPCloseTag [\t-\n \r \ ] !<< InlineHTML
    |  Document: PHPOpenTag TopStatement* PHPCloseTag  
    |  TemplateDocument: InlineHTML 
  ;

syntax Case
  =  DefaultCase: "default"  CaseSeperator TopStatement* 
    |  Case: "case"  Expr CaseSeperator TopStatement* 
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
  = LineTerminator String  
  ;

lexical String
  = [A-Z _ a-z] !<< [A-Z _ a-z] [0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]
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
  =  ConstantVariable: String  
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
  = "unset"  
    | "else" !>> [i]  
    | "global"  
    | "include_once"  
    | "require"  !>> [_] 
    | "while"  
    | "isset"  
    | "print"  
    | "static"  
    | "include"  !>> [_] 
    | "array"  
    | "echo"  
    | "declare"  
    | "empty"  
    | "return"  
    | "require_once"  
    | "if"  
    | "exit"  
    | "break"  
    | "continue"  
    | "die"  
    | "eval"  
    | "elseif"  
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
