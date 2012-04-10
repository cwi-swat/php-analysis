module lang::php::stats::Stats

import Set;
import String;
import List;
import lang::php::util::Utils;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;

public list[Expr] methodCalls(Script scr) = [ m | /m:methodCall(_,_,_) := scr ];
public list[Expr] methodCallsVV(Script scr) = [ m | m:methodCall(_,expr(_),_) <- methodCalls(scr) ];

public list[Expr] staticCalls(Script scr) = [ m | /m:staticCall(_,_,_) := scr ];
public list[Expr] staticCallsVV(Script scr) = [ m | m:staticCall(_,expr(_),_) <- staticCalls(scr) ];
public list[Expr] staticTargets(Script scr) = [ m | m:staticCall(expr(_),_,_) <- staticCalls(scr) ];

public list[Expr] classConstFetches(Script scr) = [ f | /f:fetchClassConst(_,_) := scr ];
public list[Expr] classConstFetchesVV(Script scr) = [ f | f:fetchClassConst(expr(_),_) <- classConstFetches(scr) ];

public list[Expr] newCalls(Script scr) = [ f | /f:new(_,_) := scr ];
public list[Expr] newCallsVV(Script scr) = [ f | f:new(expr(_),_) <- newCalls(scr) ];

public list[Expr] closureUses(Script scr) = [ c | /c:closure(_,_,_,_,_) := scr ];

public rel[str product, str version, loc fileloc, Expr call] gatherExprStats(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version, list[Expr](Script) f) {
	rel[loc fileloc, Script scr] scriptsByLoc = corpus[product,version];
	rel[str product, str version, loc fileloc, Expr call] res = { };
	for (l <- scriptsByLoc.fileloc, s <- scriptsByLoc[l], e <- f(s)) {
		res = res + < product, version, l, e >;
	}
	return res;
}

public rel[str product, str version, loc fileloc, Expr call] gatherVVMethodCalls(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, methodCallsVV);
}

public rel[str product, str version, loc fileloc, Expr call] gatherVVStaticCalls(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, staticCallsVV);
}

public rel[str product, str version, loc fileloc, Expr call] gatherStaticCallsVVTargets(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, staticTargets);
}

public rel[str product, str version, loc fileloc, Expr call] gatherClassConstsVVTargets(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, classConstFetchesVV);
}

public rel[str product, str version, loc fileloc, Expr call] gatherNewVVTargets(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, newCallsVV);
}

public rel[str product, str version, loc fileloc, Expr call] gatherClosureUses(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	return gatherExprStats(corpus, product, version, closureUses);
}

public map[str,int] stmtCounts(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	map[str,int] counts = ( );
	rel[loc fileloc, Script scr] scriptsByLoc = corpus[product,version];
	for (l <- scriptsByLoc.fileloc, s <- scriptsByLoc[l]) {
		visit(s) {
			case Stmt stmt : {
				stmtKey = getStmtKey(stmt);
				if (stmtKey in counts)
					counts[stmtKey] += 1;
				else
					counts[stmtKey] = 1;
			}
		}
	} 
	return counts;
}

public map[str,int] exprCounts(rel[str product, str version, loc fileloc, Script scr] corpus, str product, str version) {
	map[str,int] counts = ( );
	rel[loc fileloc, Script scr] scriptsByLoc = corpus[product,version];
	for (l <- scriptsByLoc.fileloc, s <- scriptsByLoc[l]) {
		visit(s) {
			case Expr expr : {
				exprKey = getExprKey(expr);
				if (exprKey in counts)
					counts[exprKey] += 1;
				else
					counts[exprKey] = 1;
			}
		}
	} 
	return counts;
}

public str getExprKey(Expr::array(_)) = "array";
public str getExprKey(fetchArrayDim(_,_)) = "fetch array dim";
public str getExprKey(fetchClassConst(_,_)) = "fetch class const";
public str getExprKey(assign(_,_)) = "assign";
public str getExprKey(assignWOp(_,_,Op op)) = "assign with operation: <getOpKey(op)>";
public str getExprKey(listAssign(_,_)) = "list assign";
public str getExprKey(refAssign(_,_)) = "ref assign";
public str getExprKey(binaryOperation(_,_,Op op)) = "binary operation: <getOpKey(op)>";
public str getExprKey(unaryOperation(_,Op op)) = "unary operation: <getOpKey(op)>";
public str getExprKey(new(_,_)) = "new";
public str getExprKey(classConst(_)) = "class const";
public str getExprKey(cast(_,_)) = "cast";
public str getExprKey(clone(_)) = "clone";
public str getExprKey(closure(_,_,_,_,_)) = "closure";
public str getExprKey(fetchConst(_)) = "fetch const";
public str getExprKey(empty(_)) = "empty";
public str getExprKey(suppress(_)) = "suppress";
public str getExprKey(eval(_)) = "eval";
public str getExprKey(exit(_)) = "exit";
public str getExprKey(call(_,_)) = "call";
public str getExprKey(methodCall(_,_,_)) = "method call";
public str getExprKey(staticCall(_,_,_)) = "static call";
public str getExprKey(Expr::include(_,_)) = "include";
public str getExprKey(instanceOf(_,_)) = "instanceOf";
public str getExprKey(isSet(_)) = "isSet";
public str getExprKey(print(_)) = "print";
public str getExprKey(propertyFetch(_,_)) = "property fetch";
public str getExprKey(shellExec(_)) = "shell exec";
public str getExprKey(ternary(_,_,_)) = "exit";
public str getExprKey(fetchStaticProperty(_,_)) = "fetch static property";
public str getExprKey(scalar(_)) = "scalar";
public str getExprKey(var(_)) = "var";

public str getOpKey(bitwiseAnd()) = "bitwise and";
public str getOpKey(bitwiseOr()) = "bitwise or";
public str getOpKey(bitwiseXor()) = "bitwise xor";
public str getOpKey(concat()) = "concat";
public str getOpKey(div()) = "div";
public str getOpKey(minus()) = "minus";
public str getOpKey(\mod()) = "mod";
public str getOpKey(mul()) = "mul";
public str getOpKey(plus()) = "plus";
public str getOpKey(rightShift()) = "right shift";
public str getOpKey(leftShift()) = "left shift";
public str getOpKey(booleanAnd()) = "boolean and";
public str getOpKey(booleanOr()) = "boolean or";
public str getOpKey(booleanNot()) = "boolean not";
public str getOpKey(bitwiseNot()) = "bitwise not";
public str getOpKey(gt()) = "gt";
public str getOpKey(geq()) = "geq";
public str getOpKey(logicalAnd()) = "logical and";
public str getOpKey(logicalOr()) = "logical or";
public str getOpKey(logicalXor()) = "logical xor";
public str getOpKey(notEqual()) = "not equal";
public str getOpKey(notIdentical()) = "not identical";
public str getOpKey(postDec()) = "post dec";
public str getOpKey(preDec()) = "pre dec";
public str getOpKey(postInc()) = "post inc";
public str getOpKey(preInc()) = "pre inc";
public str getOpKey(lt()) = "lt";
public str getOpKey(leq()) = "leq";
public str getOpKey(unaryPlus()) = "unary plus";
public str getOpKey(unaryMinus()) = "unary minus";
public str getOpKey(equal()) = "equal";
public str getOpKey(identical()) = "identical";

public str getStmtKey(\break(_)) = "break";
public str getStmtKey(classDef(_)) = "class def";
public str getStmtKey(Stmt::const(_)) = "const";
public str getStmtKey(\continue(_)) = "continue";
public str getStmtKey(declare(_,_)) = "declare";
public str getStmtKey(do(_,_)) = "do";
public str getStmtKey(echo(_)) = "echo";
public str getStmtKey(exprstmt(_)) = "expression statement (chain rule)";
public str getStmtKey(\for(_,_,_,_)) = "for";
public str getStmtKey(foreach(_,_,_,_,_)) = "foreach";
public str getStmtKey(function(_,_,_,_)) = "function def";
public str getStmtKey(global(_)) = "global";
public str getStmtKey(goto(_)) = "goto";
public str getStmtKey(haltCompiler(_)) = "halt compiler";
public str getStmtKey(\if(_,_,_,_)) = "if";
public str getStmtKey(inlineHTML(_)) = "inline HTML";
public str getStmtKey(interfaceDef(_)) = "interface def";
public str getStmtKey(traitDef(_)) = "trait def";
public str getStmtKey(label(_)) = "label";
public str getStmtKey(namespace(_,_)) = "namespace";
public str getStmtKey(\return(_)) = "return";
public str getStmtKey(Stmt::static(_)) = "static";
public str getStmtKey(\switch(_,_)) = "switch";
public str getStmtKey(\throw(_)) = "throw";
public str getStmtKey(tryCatch(_,_)) = "try/catch";
public str getStmtKey(Stmt::unset(_)) = "unset";
public str getStmtKey(Stmt::use(_)) = "use";
public str getStmtKey(\while(_,_)) = "while def";
