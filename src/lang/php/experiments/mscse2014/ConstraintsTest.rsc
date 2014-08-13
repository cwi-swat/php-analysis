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
	assert true == testVarious();
	assert true == testControlStructures();
	assert true == testFunction();
	assert true == testClassMethod();
	assert true == testClassConstant();
	assert true == testClassProperty();
	assert true == testClassKeywords();
	assert true == testMethodCall();
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
		// +$a;
		"[$a] \<: any()",
		"[+$a] \<: float()", // expression is float or int
		"neg([$a] \<: array(any()))", // $a is not an array
		
		// -$b;
		"[$b] \<: any()",
		"[-$b] \<: float()", // expression is float or int
		"neg([$b] \<: array(any()))", // $b is not an array
		
		// !$c;
		"[$c] \<: any()", 
		"[!$c] = boolean()", 
	
		// ~$d;	
		"[$d] \<: any()", 
		"or([$d] = float(), [$d] = integer(), [$d] = string())", 
		"or([~$d] = integer(), [~$d] = string())", 
		
		// $e++;	
		"[$e] \<: any()",
		"if ([$e] \<: array(any())) then ([$e++] \<: array(any()))",
		"if ([$e] = boolean()) then ([$e++] = boolean())",
		"if ([$e] = float()) then ([$e++] = float())",
		"if ([$e] = integer()) then ([$e++] = integer())",
		"if ([$e] = null()) then (or([$e++] = integer(), [$e++] = null()))",
		"if ([$e] \<: object()) then ([$e++] \<: object())",
		"if ([$e] = resource()) then ([$e++] = resource())",
		"if ([$e] = string()) then (or([$e++] = float(), [$e++] = integer(), [$e++] = string()))",
	
		// $f--;	
		"[$f] \<: any()",
		"if ([$f] \<: array(any())) then ([$f--] \<: array(any()))",
		"if ([$f] = boolean()) then ([$f--] = boolean())",
		"if ([$f] = float()) then ([$f--] = float())",
		"if ([$f] = integer()) then ([$f--] = integer())",
		"if ([$f] = null()) then (or([$f--] = integer(), [$f--] = null()))",
		"if ([$f] \<: object()) then ([$f--] \<: object())",
		"if ([$f] = resource()) then ([$f--] = resource())",
		"if ([$f] = string()) then (or([$f--] = float(), [$f--] = integer(), [$f--] = string()))",
	
		// ++$g;	
		"[$g] \<: any()",
		"if ([$g] \<: array(any())) then ([++$g] \<: array(any()))",
		"if ([$g] = boolean()) then ([++$g] = boolean())",
		"if ([$g] = float()) then ([++$g] = float())",
		"if ([$g] = integer()) then ([++$g] = integer())",
		"if ([$g] = null()) then ([++$g] = integer())",
		"if ([$g] \<: object()) then ([++$g] \<: object())",
		"if ([$g] = resource()) then ([++$g] = resource())",
		"if ([$g] = string()) then (or([++$g] = float(), [++$g] = integer(), [++$g] = string()))",
		
		// --$h;
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
		// $a and $b;
		"[$a] \<: any()", "[$b] \<: any()",
		"[$a and $b] = boolean()",
		
		// $c or $d;
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c or $d] = boolean()",
		
		// $e xor $f;
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e xor $f] = boolean()",
		
		// $g && $h;
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g && $h] = boolean()",
		
		// $i || $j;
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i || $j] = boolean()"
	];
	return run("logicalOp", expected);
}

public test bool testComparisonOp() {
	list[str] expected = [
		// $a < $b;
		"[$a] \<: any()", "[$b] \<: any()",
		"[$a \< $b] = boolean()",
		
		// $c <= $d;
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c \<= $d] = boolean()",
		
		// $e > $f;
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e \> $f] = boolean()",
		
		// $g >= $h;
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g \>= $h] = boolean()",
		
		// $i == $j;
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i == $j] = boolean()",
		
		// $k === $l;
		"[$k] \<: any()", "[$l] \<: any()",
		"[$k === $l] = boolean()",
	
		// $m != $n;
		"[$m] \<: any()", "[$n] \<: any()",
		"[$m != $n] = boolean()",
		
		// $o <> $p;
		"[$o] \<: any()", "[$p] \<: any()",
		"[$o \<\> $p] = boolean()",
		
		// $q !== $r;
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
		
		// (cast)$var;	
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
		"[[0,1,2]] = array([0], [1], [2])",
		
		// $a[0];
		"[$a[0]] \<: any()", // not very specific!!!
		"[0] = integer()",
		"[$a] \<: array(any())",
		"[$a] \<: any()", 
		"neg([$a] \<: object())",
		
		// $b["def"]
		"[$b[\"def\"]] \<: any()", // not very specific!!!
		"[\"def\"] = string()",
		"[$b] \<: array(any())",
		"[$b] \<: any()", 
		"neg([$b] \<: object())",
		
		// $c[0][0]
		"[$c[0][0]] \<: any()",
		"[0] = integer()", "[0] = integer()",
		"[$c] \<: array(any())",
		"[$c] \<: any()", 
		"[$c[0]] \<: array(any())",
		"[$c[0]] \<: any()",
		"neg([$c] \<: object())",
		"neg([$c[0]] \<: object())",
		
		// $d[] = 1;
		"[$d] \<: array(any())",
		"[$d] \<: any()", 
		"[$d[]] \<: any()", 
		"neg([$d] \<: object())",
		"[1] = integer()",
		"[1] \<: [$d[]]",
		"[$d[]] \<: [$d[] = 1]"
	];
	return run("array", expected);
}

public test bool testVarious() {
	list[str] expected = [
		// $a = clone($b);
		"[$a] \<: any()", 
		"[$a] \<: object()", 
		"[clone($a)] \<: object()",
		
		// new ABC();	
		"[new ABC()] = class(|php+class:///abc|)",
		// new \DEF();	
		"[new \\DEF()] = class(|php+class:///def|)",
		// new \GHI\JKL;	
		"[new \\GHI\\JKL] = class(|php+class:///ghi/jkl|)",
		// new MNO\PQR;	
		"[new MNO\\PQR] = class(|php+class:///qwerty/mno/pqr|)",
		
		// new $b();
		"[$b] \<: any()",
		"[new $b()] \<: object()"
	];
	return run("various", expected);
}

public test bool testControlStructures() {
	list[str] expected = [
		// if ($a1) {"10";}
		"[$a1] \<: any()", "[\"10\"] = string()", 
		// if ($b1) {"20";} else {"30";}
		"[$b1] \<: any()", "[\"20\"] = string()", "[\"30\"] = string()", 
		// if ($c1) {"40";} else if ("50") {$d1;} else {$e1;}
		// if ($c1) {"40";} elseif ("50") {$d1;} else {$e1;}
		"[$c1] \<: any()", 		"[$c1] \<: any()", 
		"[\"40\"] = string()",	"[\"40\"] = string()", 
		"[\"50\"] = string()",	"[\"50\"] = string()", 
		"[$d1] \<: any()",		"[$d1] \<: any()", 
		"[$e1] \<: any()",		"[$e1] \<: any()", 
		// if ($a2) "11";
		"[$a2] \<: any()", "[\"11\"] = string()", 
		// if ($b2) "21"; else "31";
		"[$b2] \<: any()", "[\"21\"] = string()", "[\"31\"] = string()", 
		// if ($c2) "41"; else if ("51") $d2; else $e2;
		"[$c2] \<: any()", "[$d2] \<: any()", "[$e2] \<: any()",
		"[\"41\"] = string()", "[\"51\"] = string()", 
		// if ($a1): "12"; endif;
		"[$a1] \<: any()", "[\"12\"] = string()", 
		
		// while($f1) { "60"; }
		"[$f1] \<: any()", "[\"60\"] = string()", 
		// while($f2)  "61";
		"[$f2] \<: any()", "[\"61\"] = string()", 
		// while ($f3): "62"; endwhile;	
		"[$f3] \<: any()", "[\"62\"] = string()", 
		
		// do { $g1; } while ($h1);
		"[$g1] \<: any()", "[$h1] \<: any()", 
		// do $g2; while ($h2);
		"[$g2] \<: any()", "[$h2] \<: any()", 
	
		// for ($i1=0; $i2<10; $i3++) { "70"; }	
		"[$i1] \<: any()", "[$i2] \<: any()", "[$i3] \<: any()", "[\"70\"] = string()", 
		// for ($i4; ;$i5) { "71"; }
		"[$i4] \<: any()", "[$i5] \<: any()", "[\"71\"] = string()", 
		// for (; ; ) { "72"; }
		"[\"72\"] = string()", 
		// for ($i6, $j7; $i8; $j9, $i11, $i12);
		"[$i6] \<: any()", "[$j7] \<: any()", "[$i8] \<: any()", 
		"[$j9] \<: any()", "[$i11] \<: any()", "[$i12] \<: any()", 
		
		// foreach ($k as $v) foreach ($kk as $vv) "80";
		"[$k] \<: any()", "[$v] \<: any()", 
		"[$kk] \<: any()", "[$vv] \<: any()", "[\"80\"] = string()", 
		// foreach ($arr as $key => $value) { "statement"; }
		"[$arr] \<: any()", "[$key] \<: any()", "[$value] \<: any()", "[\"statement\"] = string()",
		// foreach ($array as $element): "81"; endforeach;
		"[$array] \<: any()", "[$element] \<: any()", "[\"81\"] = string()", 
	
		// switch ($l2) { case 10; case "1str": "string"; break; default: "def"; }
		"[$l2] \<: any()", "[10] = integer()", 
		"[\"1str\"] = string()", "[\"string\"] = string()", "[\"def\"] = string()", 
		// switch ($l2): case 20: "zero2"; break; case "2str": "string"; break; default: "def"; endswitch;	
		"[$l2] \<: any()", "[20] = integer()", "[\"2str\"] = string()",
		"[\"zero2\"] = string()", "[\"string\"] = string()", "[\"def\"] = string()", 
		
		// declare(ticks=1) { $m; }
		"[$m] \<: any()",
		
		// goto a; 'Foo';  a: 'Bar';
		"[\'Foo\'] = string()", "[\'Bar\'] = string()",
		
		// try { $n1; } catch (\Exception $e) { $n2; };
		"[$n1] \<: any()", "[$n2] \<: any()",
		// try { $n3; } catch (\Exception $e) { $n4; } finally { $n5; };
		"[$n3] \<: any()", "[$n4] \<: any()", "[$n5] \<: any()"
	];
	return run("controlStructures", expected);
}

public test bool testFunction() {
	list[str] expected = [
		// function a() {}
		"[function a() {}] = null()",
		// function &b() {}
		"[function &b() {}] = null()",
		// function c() { return; }
		"or([function c() { return; }] = null())",
		// function d() { return true; return false; }
		"or([function d() { return true; return false; }] = [false], [function d() { return true; return false; }] = [true])",
		"[false] = boolean()", "[true] = boolean()",
		// function f() { function g() { return "string"; } }
		"[function f() { function g() { return \"string\"; } }] = null()",
		"or([function g() { return \"string\"; }] = [\"string\"])",
		"[\"string\"] = string()",
		
		// function h() { $a = "str"; $a = 100; }
		"[\"str\"] \<: [$a]",
		"[\"str\"] = string()",
		"[$a] \<: any()",
		"[$a] \<: any()",
		"[100] \<: [$a]",
		"[100] = integer()",
		"[function h() { $a = \"str\"; $a = 100; }] = null()",
		"[$a] \<: [$a = \"str\"]",
		"[$a] \<: [$a = 100]",
		"[|php+functionVar:///h/a|] = [$a]",
		"[|php+functionVar:///h/a|] = [$a]",
		
		// function i() { $i = "str"; function j() { $i = 100; } }
		"[\"str\"] \<: [$i]",
		"[\"str\"] = string()",
		"[$i] \<: any()",
		"[$i] \<: any()",
		"[100] \<: [$i]",
		"[100] = integer()",
		"[function i() { $i = \"str\"; function j() { $i = 100; } }] = null()",
		"[function j() { $i = 100; }] = null()",
		"[$i] \<: [$i = \"str\"]",
		"[$i] \<: [$i = 100]",
		"[|php+functionVar:///i/i|] = [$i]",
		"[|php+functionVar:///j/i|] = [$i]",
	
		// if (true) { function k() { $k1; } } else { function k() { $k2; } }	
		"[$k1] \<: any()",
		"[$k2] \<: any()",
		"[function k() { $k1; }] = null()",
		"[function k() { $k2; }] = null()",
		"[true] = boolean()",
		
		// a();	
		"[a()] \<: [|php+function:///a|]",
		// b();
		"[b()] \<: [|php+function:///b|]",
		// x(); // function does not exist
		"[x()] \<: [|php+function:///x|]",
		
		//$x(); // variable call
		"[$x()] \<: any()",
		"or([$x] \<: object(), [$x] = string())",
		"if ([$x] \<: object()) then (hasMethod([$x], __invoke))"
	];
	return run("function", expected);
}

public test bool testClassMethod() {
	list[str] expected = [
		// [public function m1() {}] = null()
		"[public function m1() {}] = null()",
		
		// class C2 { public function m2() { function f1() { return "a"; } return true; } }
		"[\"a\"] = string()", "[true] = boolean()",
		"or([public function m2() { function f1() { return \"a\"; } return true; }] = [true])",
		"or([function f1() { return \"a\"; }] = [\"a\"])",
		
		// class C3 { public function m3() { $a = 2; function f1() { $a = "a"; } return $a; } }
		"[$a] \<: any()", "[$a] \<: any()", "[$a] \<: any()", // variables
		"[2] = integer()", "[\"a\"] = string()",  // int/string
		"[2] \<: [$a]", "[\"a\"] \<: [$a]", // assignment
		"[$a] \<: [$a = 2]", "[$a] \<: [$a = \"a\"]", // result of assignment
		"or([public function m3() { $a = 2; function f1() { $a = \"a\"; } return $a; }] = [$a])", // type of method
		"[function f1() { $a = \"a\"; }] = null()", // type of function
		"[|php+methodVar:///ns/c3/m3/a|] = [$a]",
		"[|php+functionVar:///ns/f1/a|] = [$a]"
	];
	return run("classMethod", expected);
}

public test bool testClassConstant() {
	list[str] expected = [
		// class C1 { const c1 = 100; }
		"[c1 = 100] = [100]",
		"[100] = integer()",
		"[|php+classConstant:///classconstant/c1/c1|] = [c1 = 100]",
		// class C2 { const c21 = 21, c22 = 22; }
		"[c21 = 21] = [21]",
		"[21] = integer()",
		"[c22 = 22] = [22]",
		"[22] = integer()",
		"[|php+classConstant:///classconstant/c2/c21|] = [c21 = 21]",
		"[|php+classConstant:///classconstant/c2/c22|] = [c22 = 22]",
		 //interface C3 { const cInterface = "interface constant"; }
		"[cInterface = \"interface constant\"] = [\"interface constant\"]",
		"[\"interface constant\"] = string()",
		"[|php+classConstant:///classconstant/c3/cInterface|] = [cInterface = \"interface constant\"]" 
	];
	return run("classConstant", expected);
}

public test bool testClassProperty() {
	list[str] expected = [
		// class cl1 { public $pub1; public $pub2 = 2; }
		"[2] = integer()",
		"[$pub2 = 2] = [2]",
		"[|php+field:///randomnamespace/cl1/pub1|] = [$pub1]",
		"[|php+field:///randomnamespace/cl1/pub2|] = [$pub2 = 2]",
		// class cl2 { private $priv1; private $priv2 = 2; }
		"[2] = integer()",
		"[$priv2 = 2] = [2]",
		"[|php+field:///randomnamespace/cl2/priv1|] = [$priv1]",
		"[|php+field:///randomnamespace/cl2/priv2|] = [$priv2 = 2]",
		// class cl3 { protected $pro1; protected $pro2 = 2; }
		"[2] = integer()",
		"[$pro2 = 2] = [2]",
		"[|php+field:///randomnamespace/cl3/pro1|] = [$pro1]",
		"[|php+field:///randomnamespace/cl3/pro2|] = [$pro2 = 2]"
	];
	return run("classProperty", expected);
}

public test bool testClassKeywords() {
	// information is retreived from m3, declares in uses
	list[str] expected = [
		// public function se() { self::foo(); }
		"[public function se() { self::foo(); }] = null()",
		// public function pa() { parent::foo(); }
		"[public function pa() { parent::foo(); }] = null()",
		// public function st() { static::foo(); }	
		"[public function st() { static::foo(); }] = null()",
		"[self] = class(|php+class:///ns/c|)",
		//"[self::foo()] = null()",
		"or([parent] = class(|php+class:///ns/p|))",
		//"[parent::foo()] = null()",
		"or([static] = class(|php+class:///ns/c|), [static] = class(|php+class:///ns/p|))"
		//"[static::foo()] = null()",
    ];
	return run("classKeywords", expected);
}

public test bool testMethodCall() {
	// information is retreived from m3, declares in uses
	list[str] expected = [
		// public function se() { self::foo(); }
		"[public function se() { self::foo(); }] = null()",
		// public function pa() { parent::foo(); }
		"[public function pa() { parent::foo(); }] = null()",
		// public function st() { static::foo(); }	
		"[public function st() { static::foo(); }] = null()",
		"[self] = class(|php+class:///ns/c|)",
		//"[self::foo()] = null()",
		"or([parent] = class(|php+class:///ns/p|))",
		//"[parent::foo()] = null()",
		"or([static] = class(|php+class:///ns/c|), [static] = class(|php+class:///ns/p|))"
		//"[static::foo()] = null()",
    ];
	return run("methodCall", expected);
}

public bool run(str fileName, list[str] expected)
{
	loc l = getFileLocation(fileName);
	
	System system = getSystem(l, false);
	resetModifiedSystem(); // this is only needed for the tests
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