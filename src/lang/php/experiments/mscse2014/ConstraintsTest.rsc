module lang::php::experiments::mscse2014::ConstraintsTest
extend lang::php::experiments::mscse2014::Constraints;
extend lang::php::experiments::mscse2014::mscse2014;

import lang::php::types::TypeConstraints;
import lang::php::util::Config;

import Set; // toList
import List; // sort

loc getFileLocation(str name) = analysisLoc + "/src/tests/resources/experiments/mscse2014/<name>/";
loc getFileLocationFull(str name) = getFileLocation(name) + "/<name>.php";

public void main()
{
	// trigger all tests
	assert true == testVariable();
	assert true == testNormalAssign();
	assert true == testScalars();
	assert true == testPredefinedConstants();
	assert true == testPredefinedVariables();
	assert true == testOpAssign();
	assert true == testUnaryOp();
	assert true == testBinaryOp();
	assert true == testTernary();
	assert true == testComparisonOp();
	assert true == testLogicalOp();
	assert true == testCasts();
	assert true == testArray();
	assert true == testFunction();
}

public test bool testVariable() {
	list[str] expected = [
		"[$a] \<: any()"
	];
	return run("variable", expected);
}
public test bool testNormalAssign() {
	list[str] expected = [
		"[$a] \<: any()", "[$a] \<: any()", "[$b] \<: any()",
		"[2] \<: [$a]", "[2] = integer()", // assign of int
		"[$a] \<: [$b]", // assign assign of vars
		"[$a] \<: [$a = 2]", "[$b] \<: [$b = $a]", // type of full expr is the type of the assignment
		
		"[$c] \<: any()", "[$d] \<: any()", "[$b] \<: any()",
		"[$b] \<: [$d]", "[$d = $b] \<: [$c]",
		"[$d] \<: [$d = $b]",
		"[$c] \<: [$c = $d = $b]"
	];
	return run("normalAssign", expected);
}

public test bool testScalars() {
	list[str] expected = [
		// floats -> float()
		"[0.0] = float()", "[0.5] = float()", "[1000.0382] = float()",
		// int -> int()
		"[0] = integer()", "[1] = integer()", "[2] = integer()", "[10] = integer()", "[100] = integer()",
		// strings -> string()
		"[\"string\"] = string()", "[\'also a string\'] = string()", 
		// encapsed -> string()
		// also evaluate the items of the encapsed string
		"[\"$encapsed string\"] = string()", "[\"{$encapsed} string\"] = string()",
		"[$encapsed] \<: any()", "[$encapsed] \<: any()"
		
	];
	return run("scalar", expected);
}

public test bool testPredefinedConstants() {
	list[str] expected = [
		// magic constants -> string() (except for __LINE__ which is of type integer()
		"[__CLASS__] = string()", "[__DIR__] = string()", "[__FILE__] = string()", "[__FUNCTION__] = string()", 
		"[__LINE__] = integer()", "[__METHOD__] = string()", "[__NAMESPACE__] = string()", "[__TRAIT__] = string()",
		
		// booleans -> boolean()
		"[TRUE] = boolean()", "[true] = boolean()", "[TrUe] = boolean()",
		"[FALSE] = boolean()", "[false] = boolean()", "[FalSe] = boolean()",
		
		"[DEFAULT_INCLUDE_PATH] = string()",
		"[E_ALL] = integer()",
		"[E_COMPILE_ERROR] = integer()",
		"[E_COMPILE_WARNING] = integer()",
		"[E_CORE_ERROR] = integer()",
		"[E_CORE_WARNING] = integer()",
		"[E_DEPRECATED] = integer()",
		"[E_ERROR] = integer()",
		"[E_NOTICE] = integer()",
		"[E_PARSE] = integer()",
		"[E_RECOVERABLE_ERROR] = integer()",
		"[E_STRICT] = integer()",
		"[E_USER_DEPRECATED] = integer()",
		"[E_USER_ERROR] = integer()",
		"[E_USER_NOTICE] = integer()",
		"[E_USER_WARNING] = integer()",
		"[E_WARNING] = integer()",
		"[E_USER_DEPRECATED] = integer()",
		"[FALSE] = boolean()",
		"[INF] = float()",
		"[M_1_PI] = float()",
		"[M_2_PI] = float()",
		"[M_2_SQRTPI] = float()",
		"[M_E] = float()",
		"[M_EULER] = float()",
		"[M_LN10] = float()",
		"[M_LN2] = float()",
		"[M_LNPI] = float()",
		"[M_LOG10E] = float()",
		"[M_LOG2E] = float()",
		"[M_PI] = float()",
		"[M_PI_2] = float()",
		"[M_PI_4] = float()",
		"[M_SQRT1_2] = float()",
		"[M_SQRT2] = float()",
		"[M_SQRT3] = float()",
		"[M_SQRTPI] = float()",
		"[NAN] = float()",
		"[NULL] = null()",
		"[PHP_BINARY] = string()",
		"[PHP_BINDIR] = string()",
		"[PHP_CONFIG_FILE_PATH] = string()",
		"[PHP_CONFIG_FILE_SCAN_DIR] = string()",
		"[PHP_DEBUG] = integer()",
		"[PHP_EOL] = string()",
		"[PHP_EXTENSION_DIR] = string()",
		"[PHP_EXTRA_VERSION] = string()",
		"[PHP_INT_MAX] = integer()",
		"[PHP_INT_SIZE] = integer()",
		"[PHP_MAJOR_VERSION] = integer()",
		"[PHP_MANDIR] = string()",
		"[PHP_MAXPATHLEN] = integer()",
		"[PHP_MINOR_VERSION] = integer()",
		"[PHP_OS] = string()",
		"[PHP_PREFIX] = string()",
		"[PHP_RELEASE_VERSION] = integer()",
		"[PHP_ROUND_HALF_DOWN] = integer()",
		"[PHP_ROUND_HALF_EVEN] = integer()",
		"[PHP_ROUND_HALF_ODD] = integer()",
		"[PHP_ROUND_HALF_UP] = integer()",
		"[PHP_SAPI] = string()",
		"[PHP_SHLIB_SUFFIX] = string()",
		"[PHP_SYSCONFDIR] = string()",
		"[PHP_VERSION] = string()",
		"[PHP_VERSION_ID] = integer()",
		"[PHP_ZTS] = integer()",
		"[STDIN] = resource()",
		"[STDOUT] = resource()",
		"[STDERR] = resource()",
		"[TRUE] = boolean()"
	];
	return run("predefinedConstants", expected);
}

public test bool testPredefinedVariables() {
	list[str] expected = [
		"[$argc] = integer()",
		"[$argv] = array(string())",
		"[$_COOKIE] \<: array(any())",
		"[$_ENV] \<: array(any())",
		"[$_FILES] \<: array(any())",
		"[$_GET] \<: array(any())",
		"[$GLOBALS] \<: array(any())",
		"[$_REQUEST] \<: array(any())",
		"[$_POST] \<: array(any())",
		"[$_SERVER] \<: array(any())",
		"[$_SESSION] \<: array(any())",
    
		"[$php_errormsg] = string()",
		"[$HTTP_RAW_POST_DATA] = array(string())",
		"[$http_response_header] = array(string())"
	];
	return run("predefinedVariables", expected);
}

public test bool testOpAssign() {
	list[str] expected = [
		// LHS = integer()
		"[$a] \<: any()", "[$b] \<: any()", "[$a] = integer()", // $a  &= $b
		"[$c] \<: any()", "[$d] \<: any()", "[$c] = integer()", // $c  |= $d
		"[$e] \<: any()", "[$f] \<: any()", "[$e] = integer()", // $e  ^= $f
		"[$g] \<: any()", "[$h] \<: any()", "[$g] = integer()", // $g  %= $h
		"[$i] \<: any()", "[$j] \<: any()", "[$i] = integer()", // $i <<= $j
		"[$k] \<: any()", "[$l] \<: any()", "[$k] = integer()", // $k >>= $l
	
		// LHS = string()	
		"[$m] \<: any()", "[$n] \<: any()", "[$m] = string()", // $m .= $n
		"if ([$n] \<: object()) then (hasMethod([$n], __tostring))", // if (n == object) => [$n] has method __tostring
	
		// LHS = integer, RHS != array()	
		"[$o] \<: any()", "[$p] \<: any()", "[$o] = integer()", "neg([$p] \<: array(any()))", // $o /= $p
		"[$q] \<: any()", "[$r] \<: any()", "[$q] = integer()", "neg([$r] \<: array(any()))", // $q -= $r
	
		// LHS = integer || float => LHS <: float()	
		"[$s] \<: any()", "[$t] \<: any()", "[$s] \<: float()", // $s *= $t
		"[$u] \<: any()", "[$v] \<: any()", "[$u] \<: float()"  // $u += $v
	];
	return run("opAssign", expected);
}

public test bool testUnaryOp() {
	list[str] expected = [
		"[$a] \<: any()",
		"[+$a] \<: float()", // expression is float or int
		"neg([$a] \<: array(any()))", // $a is not an array
		
		"[$b] \<: any()",
		"[-$b] \<: float()", // expression is float or int
		"neg([$b] \<: array(any()))", // $b is not an array
		
		"[$c] \<: any()", 
		"[!$c] = boolean()", 
		
		"[$d] \<: any()", 
		"or([$d] = float(), [$d] = integer(), [$d] = string())", 
		"or([~$d] = integer(), [~$d] = string())", 
		
		"[$e] \<: any()",
		"if ([$e] \<: array(any())) then ([$e++] \<: array(any()))",
		"if ([$e] = boolean()) then ([$e++] = boolean())",
		"if ([$e] = float()) then ([$e++] = float())",
		"if ([$e] = integer()) then ([$e++] = integer())",
		"if ([$e] = null()) then (or([$e++] = integer(), [$e++] = null()))",
		"if ([$e] \<: object()) then ([$e++] \<: object())",
		"if ([$e] = resource()) then ([$e++] = resource())",
		"if ([$e] = string()) then (or([$e++] = float(), [$e++] = integer(), [$e++] = string()))",
		
		"[$f] \<: any()",
		"if ([$f] \<: array(any())) then ([$f--] \<: array(any()))",
		"if ([$f] = boolean()) then ([$f--] = boolean())",
		"if ([$f] = float()) then ([$f--] = float())",
		"if ([$f] = integer()) then ([$f--] = integer())",
		"if ([$f] = null()) then (or([$f--] = integer(), [$f--] = null()))",
		"if ([$f] \<: object()) then ([$f--] \<: object())",
		"if ([$f] = resource()) then ([$f--] = resource())",
		"if ([$f] = string()) then (or([$f--] = float(), [$f--] = integer(), [$f--] = string()))",
		
		"[$g] \<: any()",
		"if ([$g] \<: array(any())) then ([++$g] \<: array(any()))",
		"if ([$g] = boolean()) then ([++$g] = boolean())",
		"if ([$g] = float()) then ([++$g] = float())",
		"if ([$g] = integer()) then ([++$g] = integer())",
		"if ([$g] = null()) then ([++$g] = integer())",
		"if ([$g] \<: object()) then ([++$g] \<: object())",
		"if ([$g] = resource()) then ([++$g] = resource())",
		"if ([$g] = string()) then (or([++$g] = float(), [++$g] = integer(), [++$g] = string()))",
		
		"[$h] \<: any()",
		"if ([$h] \<: array(any())) then ([--$h] \<: array(any()))",
		"if ([$h] = boolean()) then ([--$h] = boolean())",
		"if ([$h] = float()) then ([--$h] = float())",
		"if ([$h] = integer()) then ([--$h] = integer())",
		"if ([$h] = null()) then ([--$h] = integer())",
		"if ([$h] \<: object()) then ([--$h] \<: object())",
		"if ([$h] = resource()) then ([--$h] = resource())",
		"if ([$h] = string()) then (or([--$h] = float(), [--$h] = integer(), [--$h] = string()))"
	];
	return run("unaryOp", expected);
}

public test bool testBinaryOp() {
	list[str] expected = [
		// $a + $b;
		"[$a] \<: any()", "[$b] \<: any()",
		"or([$a + $b] \<: array(any()), [$a + $b] \<: float())", // always array, or subtype of float()
		"if (and([$a] \<: array(any()), [$b] \<: array(any()))) then ([$a + $b] \<: array(any()))", // ($a = array && $b = array) => [E] = array
		"if (or(neg([$a] \<: array(any())), neg([$b] \<: array(any())))) then ([$a + $b] \<: float())", // ($a != array || $b = array) => [E] <: float 
		
		// $c - $d;	
		"[$c] \<: any()", "[$d] \<: any()",
		"neg([$c] \<: array(any()))",
		"neg([$d] \<: array(any()))",
		"[$c - $d] \<: float()",
	
		// $e * $f;	
		"[$e] \<: any()", "[$f] \<: any()",
		"neg([$e] \<: array(any()))",
		"neg([$f] \<: array(any()))",
		"[$e * $f] \<: float()",
	
		// $g / $h;	
		"[$g] \<: any()", "[$h] \<: any()",
		"neg([$g] \<: array(any()))",
		"neg([$h] \<: array(any()))",
		"[$g / $h] \<: float()",
	
		// $i % $j;	
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i % $j] = integer()",

		// $k & $l;	
		"[$k] \<: any()", "[$l] \<: any()",
		"if (and([$k] = string(), [$l] = string())) then ([$k & $l] = string())",
		"if (or(neg([$k] = string()), neg([$l] = string()))) then ([$k & $l] = integer())",
		"or([$k & $l] = integer(), [$k & $l] = string())",
		
		// $m | $n;	
		"[$m] \<: any()", "[$n] \<: any()",
		"if (and([$m] = string(), [$n] = string())) then ([$m | $n] = string())",
		"if (or(neg([$m] = string()), neg([$n] = string()))) then ([$m | $n] = integer())",
		"or([$m | $n] = integer(), [$m | $n] = string())",
		
		// $o ^ $p;	
		"[$o] \<: any()", "[$p] \<: any()",
		"if (and([$o] = string(), [$p] = string())) then ([$o ^ $p] = string())",
		"if (or(neg([$o] = string()), neg([$p] = string()))) then ([$o ^ $p] = integer())",
		"or([$o ^ $p] = integer(), [$o ^ $p] = string())",
		
		// $q << $r;	
		"[$q] \<: any()", "[$r] \<: any()",
		"[$q \<\< $r] = integer()",
		
		// $s >> $t;	
		"[$s] \<: any()", "[$t] \<: any()",
		"[$s \>\> $t] = integer()"
		
	];
	return run("binaryOp", expected);
}

public test bool testTernary() {
	list[str] expected = [
		// $a = true ? $b : "string";
		"[$a] \<: any()", "[$b] \<: any()", // $a and $b
		"[true] = boolean()", "[\"string\"] = string()", // true and "string"
		"or([true ? $b : \"string\"] \<: [\"string\"], [true ? $b : \"string\"] \<: [$b])", // [E] = [E2] OR [E3]
		"[true ? $b : \"string\"] \<: [$a]", // [E] <: $a
		"[$a] \<: [$a = true ? $b : \"string\"]", // result of the whole expression is a subtype of $a
		
		// $c = TRUE ? : "str";
		"[$c] \<: any()", 
		"[TRUE] = boolean()", "[\"str\"] = string()", // TRUE and "string"
		"or([TRUE ? : \"str\"] \<: [\"str\"], [TRUE ? : \"str\"] \<: [TRUE])", // [E] = [E1] OR [E3]
		"[TRUE ? : \"str\"] \<: [$c]", // [E] <: $c
		"[$c] \<: [$c = TRUE ? : \"str\"]", // result of the whole expression is a subtype of $c
	
		// $d = $e = 3 ? "l" : "r";
		"[$d] \<: any()", "[$e] \<: any()", 
		"[3] = integer()", "[\"l\"] = string()", "[\"r\"] = string()", // 3, "l" and "r"
		"or([3 ? \"l\" : \"r\"] \<: [\"l\"], [3 ? \"l\" : \"r\"] \<: [\"r\"])", // [E] = [E1] OR [E3]
		"[3 ? \"l\" : \"r\"] \<: [$e]", // [E] <: $e
		"[$e = 3 ? \"l\" : \"r\"] \<: [$d]", // $e <: $d
		"[$d] \<: [$d = $e = 3 ? \"l\" : \"r\"]", // result of the whole expression is a subtype of $c
		"[$e] \<: [$e = 3 ? \"l\" : \"r\"]" // result of the whole expression is a subtype of $c
	];
	return run("ternary", expected);
}

public test bool testLogicalOp() {
	list[str] expected = [
		"[$a] \<: any()", "[$b] \<: any()",
		"[$a and $b] = boolean()",
		
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c or $d] = boolean()",
		
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e xor $f] = boolean()",
		
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g && $h] = boolean()",
		
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i || $j] = boolean()"
	];
	return run("logicalOp", expected);
}

public test bool testComparisonOp() {
	list[str] expected = [
		"[$a] \<: any()", "[$b] \<: any()",
		"[$a \< $b] = boolean()",
		
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c \<= $d] = boolean()",
		
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e \> $f] = boolean()",
		
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g \>= $h] = boolean()",
		
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i == $j] = boolean()",
		
		"[$k] \<: any()", "[$l] \<: any()",
		"[$k === $l] = boolean()",
	
		"[$m] \<: any()", "[$n] \<: any()",
		"[$m != $n] = boolean()",
		
		"[$o] \<: any()", "[$p] \<: any()",
		"[$o \<\> $p] = boolean()",
		
		"[$q] \<: any()", "[$r] \<: any()",
		"[$q !== $r] = boolean()"
	];
	return run("comparisonOp", expected);
}

public test bool testCasts() {
	list[str] expected = [
		"[$a] \<: any()", "[$b] \<: any()", "[$c] \<: any()", "[$d] \<: any()", 
		"[$e] \<: any()", "[$f] \<: any()", "[$g] \<: any()", "[$h] \<: any()", 
		"[$i] \<: any()", "[$j] \<: any()", "[$k] \<: any()", 
		
		"[(array)$a] \<: array(any())",
		"[(bool)$b] = boolean()",
		"[(boolean)$c] = boolean()",
		"[(int)$d] = integer()",
		"[(integer)$e] = integer()",
		"[(float)$f] = float()",
		"[(double)$g] = float()",
		"[(real)$h] = float()",
		
		"[(string)$i] = string()",
		"if ([$i] \<: object()) then (hasMethod([$i], __tostring))",
		
		"[(object)$j] \<: object()",
		"[(unset)$k] = null()"
	];
	return run("casts", expected);
}

public test bool testArray() {
	list[str] expected = [
		// array(); [];
		"[array()] = array()",
		"[[]] = array()",
		
		// array("a", "b", "c");
		"[\"a\"] = string()", "[\"b\"] = string()", "[\"c\"] = string()",
		"[array(\"a\", \"b\", \"c\")] = array([\"a\"], [\"b\"], [\"c\"])",
	
		// array(0, "b", 3.4); 
		"[0] = integer()", "[\"b\"] = string()", "[3.4] = float()",
		"[array(0, \"b\", 3.4)] = array([\"b\"], [0], [3.4])",
		
		// [0,1,2];
		"[0] = integer()", "[1] = integer()", "[2] = integer()", 
		"[[0,1,2]] = array([0], [1], [2])"
		
	];
	return run("array", expected);
}

public test bool testFunction() {
	list[str] expected = [
		"[function a() {}] = null()",
		"[function &b() {}] = null()",
		"or([function c() { return; }] = null())",
		"or([function d() { return true; return false; }] = [false], [function d() { return true; return false; }] = [true])",
		"[function f() { function g() { return \"string\"; } }] = null()",
		"or([function g() { return \"string\"; }] = [\"string\"])",
		
		"[\"str\"] \<: [$a]",
		"[\"str\"] = string()",
		"[$a] \<: any()",
		"[$a] \<: any()",
		"[100] \<: [$a]",
		"[100] = integer()",
		"[function h() { $a = \"str\"; $a = 100; }] = null()",
		"[$a] \<: [$a = \"str\"]",
		"[$a] \<: [$a = 100]"
	];
	return run("function", expected);
}
public bool run(str fileName, list[str] expected)
{
	loc l = getFileLocation(fileName);
	
	System system = getSystem(l, false);
	resetModifiedSystem();
	M3 m3 = getM3ForSystem(system, false);
	system = getModifiedSystem();

	set[Constraint] actual = getConstraints(system, m3);

	// for debugging purposes
	//printResult(fileName, expected, actual);
	
	// assert that expectedConstraints is a subset of ActualConstraints
	return comparePrettyPrinted(expected, actual);
}

//
// Assert pretty printed
//
private bool comparePrettyPrinted(list[str] expected, set[Constraint] actual) 
{
	list[str] actualPP = [ toStr(a) | a <- actual ];

	a = sort(actualPP);
	e = sort(expected);
	
	notInActual = e - a;
	notInExpected = a - e;	
	
	if (!isEmpty(notInActual) || !isEmpty(notInExpected))	
	{
		iprintln("Actual: <a>");
		iprintln("Expected: <e>");
		iprintln("Not in actual:");
		for (nia <- notInActual) println(nia);
		iprintln("Not in expected:");
		for (nie <- notInExpected) println(nie);
	}
	
	return a == e;
}


//
// Printer functions:
//

private void printResult(str fileName, list[str] expected, set[Constraint] actual)
{
	println();
	println("----------File Content: <fileName>----------");
	println(readFile(getFileLocationFull(fileName)));
	println();
	println("---------------- Actual: -------------------");
	for (a <- actual) println(toStr(a));
	println("--------------------------------------------");
	println();
	println("--------------- Expected: ------------------");
	for (e <- expected) println(e);
	println("--------------------------------------------");
	println();
}

// Pretty Print the constraints
private str toStr(eq(TypeOf t1, TypeOf t2)) 			= "<toStr(t1)> = <toStr(t2)>";
private str toStr(eq(TypeOf t1, TypeSymbol ts)) 		= "<toStr(t1)> = <toStr(ts)>";
private str toStr(subtyp(TypeOf t1, TypeOf t2)) 		= "<toStr(t1)> \<: <toStr(t2)>";
private str toStr(subtyp(TypeOf t1, TypeSymbol ts)) 	= "<toStr(t1)> \<: <toStr(ts)>";
private str toStr(disjunction(set[Constraint] cs))		= "or(<intercalate(", ", sort([ toStr(c) | c <- sort(toList(cs))]))>)";
private str toStr(exclusiveDisjunction(set[Constraint] cs))	= "xor(<intercalate(", ", sort([ toStr(c) | c <- sort(toList(cs))]))>)";
private str toStr(conjunction(set[Constraint] cs))		= "and(<intercalate(", ", sort([ toStr(c) | c <- sort(toList(cs))]))>)";
private str toStr(negation(Constraint c)) 				= "neg(<toStr(c)>)";
private str toStr(conditional(Constraint c, Constraint res)) = "if (<toStr(c)>) then (<toStr(res)>)";
private str toStr(hasMethod(TypeOf t, str name))		= "hasMethod(<toStr(t)>, <name>)";
default str toStr(Constraint c) { throw "Please implement toStr for node :: <c>"; }

private str toStr(typeOf(loc i)) 				= isFile(i) ? "["+readFile(i)+"]" : "[<i>]";
private str toStr(arrayType(set[TypeOf] expr))	= "array(<intercalate(", ", sort([ toStr(e) | e <- sort(toList(expr))]))>)";
private str toStr(TypeSymbol t) 				= "<t>";
default str toStr(TypeOf to) { throw "Please implement toStr for node :: <to>"; }