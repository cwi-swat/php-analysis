module lang::php::experiments::mscse2014::ConstraintsTest
extend lang::php::experiments::mscse2014::Constraints;
extend lang::php::experiments::mscse2014::mscse2014;

import lang::php::types::TypeConstraints;
import lang::php::util::Config;

import Set; // toList
import List; // sort

loc getFileLocation(str name) = analysisLoc + "/src/tests/resources/experiments/mscse2014/<name>/";
//loc getFileLocationFull(str name) = getFileLocation(name) + "/<name>.php";

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
	assert true == testarrayType();
	assert true == testVarious();
	assert true == testControlStructures();
	assert true == testFunction();
	assert true == testClassMethod();
	assert true == testClassConstant();
	assert true == testClassProperty();
	assert true == testMethodCall();
	assert true == testClassKeywords();
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
		"[2] \<: [$a]", "[2] = integerType()", // assign of int
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
		// floats -> floatType()
		"[0.0] = floatType()", "[0.5] = floatType()", "[1000.0382] = floatType()",
		// int -> int()
		"[0] = integerType()", "[1] = integerType()", "[2] = integerType()", "[10] = integerType()", "[100] = integerType()",
		// strings -> stringType()
		"[\"string\"] = stringType()", "[\'also a string\'] = stringType()", 
		// encapsed -> stringType()
		// also evaluate the items of the encapsed string
		"[\"$encapsed string\"] = stringType()", "[\"{$encapsed} string\"] = stringType()",
		"[$encapsed] \<: any()", "[$encapsed] \<: any()"
		
	];
	return run("scalar", expected);
}

public test bool testPredefinedConstants() {
	list[str] expected = [
		// magic constants -> stringType() (except for __LINE__ which is of type integerType()
		"[__CLASS__] = stringType()", "[__DIR__] = stringType()", "[__FILE__] = stringType()", "[__FUNCTION__] = stringType()", 
		"[__LINE__] = integerType()", "[__METHOD__] = stringType()", "[__NAMESPACE__] = stringType()", "[__TRAIT__] = stringType()",
		
		// booleans -> booleanType()
		"[TRUE] = booleanType()", "[true] = booleanType()", "[TrUe] = booleanType()",
		"[FALSE] = booleanType()", "[false] = booleanType()", "[FalSe] = booleanType()",
		
		"[DEFAULT_INCLUDE_PATH] = stringType()",
		"[E_ALL] = integerType()",
		"[E_COMPILE_ERROR] = integerType()",
		"[E_COMPILE_WARNING] = integerType()",
		"[E_CORE_ERROR] = integerType()",
		"[E_CORE_WARNING] = integerType()",
		"[E_DEPRECATED] = integerType()",
		"[E_ERROR] = integerType()",
		"[E_NOTICE] = integerType()",
		"[E_PARSE] = integerType()",
		"[E_RECOVERABLE_ERROR] = integerType()",
		"[E_STRICT] = integerType()",
		"[E_USER_DEPRECATED] = integerType()",
		"[E_USER_ERROR] = integerType()",
		"[E_USER_NOTICE] = integerType()",
		"[E_USER_WARNING] = integerType()",
		"[E_WARNING] = integerType()",
		"[E_USER_DEPRECATED] = integerType()",
		"[FALSE] = booleanType()",
		"[INF] = floatType()",
		"[M_1_PI] = floatType()",
		"[M_2_PI] = floatType()",
		"[M_2_SQRTPI] = floatType()",
		"[M_E] = floatType()",
		"[M_EULER] = floatType()",
		"[M_LN10] = floatType()",
		"[M_LN2] = floatType()",
		"[M_LNPI] = floatType()",
		"[M_LOG10E] = floatType()",
		"[M_LOG2E] = floatType()",
		"[M_PI] = floatType()",
		"[M_PI_2] = floatType()",
		"[M_PI_4] = floatType()",
		"[M_SQRT1_2] = floatType()",
		"[M_SQRT2] = floatType()",
		"[M_SQRT3] = floatType()",
		"[M_SQRTPI] = floatType()",
		"[NAN] = floatType()",
		"[NULL] = nullType()",
		"[PHP_BINARY] = stringType()",
		"[PHP_BINDIR] = stringType()",
		"[PHP_CONFIG_FILE_PATH] = stringType()",
		"[PHP_CONFIG_FILE_SCAN_DIR] = stringType()",
		"[PHP_DEBUG] = integerType()",
		"[PHP_EOL] = stringType()",
		"[PHP_EXTENSION_DIR] = stringType()",
		"[PHP_EXTRA_VERSION] = stringType()",
		"[PHP_INT_MAX] = integerType()",
		"[PHP_INT_SIZE] = integerType()",
		"[PHP_MAJOR_VERSION] = integerType()",
		"[PHP_MANDIR] = stringType()",
		"[PHP_MAXPATHLEN] = integerType()",
		"[PHP_MINOR_VERSION] = integerType()",
		"[PHP_OS] = stringType()",
		"[PHP_PREFIX] = stringType()",
		"[PHP_RELEASE_VERSION] = integerType()",
		"[PHP_ROUND_HALF_DOWN] = integerType()",
		"[PHP_ROUND_HALF_EVEN] = integerType()",
		"[PHP_ROUND_HALF_ODD] = integerType()",
		"[PHP_ROUND_HALF_UP] = integerType()",
		"[PHP_SAPI] = stringType()",
		"[PHP_SHLIB_SUFFIX] = stringType()",
		"[PHP_SYSCONFDIR] = stringType()",
		"[PHP_VERSION] = stringType()",
		"[PHP_VERSION_ID] = integerType()",
		"[PHP_ZTS] = integerType()",
		"[STDIN] = resourceType()",
		"[STDOUT] = resourceType()",
		"[STDERR] = resourceType()",
		"[TRUE] = booleanType()"
	];
	return run("predefinedConstants", expected);
}

public test bool testPredefinedVariables() {
	list[str] expected = [
		"[$argc] = integerType()",
		"[$argv] = arrayType(stringType())",
		"[$_COOKIE] \<: arrayType(any())",
		"[$_ENV] \<: arrayType(any())",
		"[$_FILES] \<: arrayType(any())",
		"[$_GET] \<: arrayType(any())",
		"[$GLOBALS] \<: arrayType(any())",
		"[$_REQUEST] \<: arrayType(any())",
		"[$_POST] \<: arrayType(any())",
		"[$_SERVER] \<: arrayType(any())",
		"[$_SESSION] \<: arrayType(any())",
    
		"[$php_errormsg] = stringType()",
		"[$HTTP_RAW_POST_DATA] = arrayType(stringType())",
		"[$http_response_header] = arrayType(stringType())"
	];
	return run("predefinedVariables", expected);
}

public test bool testOpAssign() {
	list[str] expected = [
		// LHS = integerType()
		"[$a] \<: any()", "[$b] \<: any()", "[$a] = integerType()", // $a  &= $b
		"[$c] \<: any()", "[$d] \<: any()", "[$c] = integerType()", // $c  |= $d
		"[$e] \<: any()", "[$f] \<: any()", "[$e] = integerType()", // $e  ^= $f
		"[$g] \<: any()", "[$h] \<: any()", "[$g] = integerType()", // $g  %= $h
		"[$i] \<: any()", "[$j] \<: any()", "[$i] = integerType()", // $i <<= $j
		"[$k] \<: any()", "[$l] \<: any()", "[$k] = integerType()", // $k >>= $l
	
		// LHS = stringType()	
		"[$m] \<: any()", "[$n] \<: any()", "[$m] = stringType()", // $m .= $n
		"if ([$n] \<: objectType()) then (hasMethod([$n], __tostring))", // if (n == object) => [$n] has method __tostring
	
		// LHS = integer, RHS != arrayType()	
		"[$o] \<: any()", "[$p] \<: any()", "[$o] = integerType()", "neg([$p] \<: arrayType(any()))", // $o /= $p
		"[$q] \<: any()", "[$r] \<: any()", "[$q] = integerType()", "neg([$r] \<: arrayType(any()))", // $q -= $r
	
		// LHS = integer || float => LHS <: floatType()	
		"[$s] \<: any()", "[$t] \<: any()", "[$s] \<: floatType()", // $s *= $t
		"[$u] \<: any()", "[$v] \<: any()", "[$u] \<: floatType()"  // $u += $v
	];
	return run("opAssign", expected);
}

public test bool testUnaryOp() {
	list[str] expected = [
		// +$a;
		"[$a] \<: any()",
		"[+$a] \<: floatType()", // expression is float or int
		"neg([$a] \<: arrayType(any()))", // $a is not an array
		
		// -$b;
		"[$b] \<: any()",
		"[-$b] \<: floatType()", // expression is float or int
		"neg([$b] \<: arrayType(any()))", // $b is not an array
		
		// !$c;
		"[$c] \<: any()", 
		"[!$c] = booleanType()", 
	
		// ~$d;	
		"[$d] \<: any()", 
		"or([$d] = floatType(), [$d] = integerType(), [$d] = stringType())", 
		"or([~$d] = integerType(), [~$d] = stringType())", 
		
		// $e++;	
		"[$e] \<: any()",
		"if ([$e] \<: arrayType(any())) then ([$e++] \<: arrayType(any()))",
		"if ([$e] = booleanType()) then ([$e++] = booleanType())",
		"if ([$e] = floatType()) then ([$e++] = floatType())",
		"if ([$e] = integerType()) then ([$e++] = integerType())",
		"if ([$e] = nullType()) then (or([$e++] = integerType(), [$e++] = nullType()))",
		"if ([$e] \<: objectType()) then ([$e++] \<: objectType())",
		"if ([$e] = resourceType()) then ([$e++] = resourceType())",
		"if ([$e] = stringType()) then (or([$e++] = floatType(), [$e++] = integerType(), [$e++] = stringType()))",
	
		// $f--;	
		"[$f] \<: any()",
		"if ([$f] \<: arrayType(any())) then ([$f--] \<: arrayType(any()))",
		"if ([$f] = booleanType()) then ([$f--] = booleanType())",
		"if ([$f] = floatType()) then ([$f--] = floatType())",
		"if ([$f] = integerType()) then ([$f--] = integerType())",
		"if ([$f] = nullType()) then (or([$f--] = integerType(), [$f--] = nullType()))",
		"if ([$f] \<: objectType()) then ([$f--] \<: objectType())",
		"if ([$f] = resourceType()) then ([$f--] = resourceType())",
		"if ([$f] = stringType()) then (or([$f--] = floatType(), [$f--] = integerType(), [$f--] = stringType()))",
	
		// ++$g;	
		"[$g] \<: any()",
		"if ([$g] \<: arrayType(any())) then ([++$g] \<: arrayType(any()))",
		"if ([$g] = booleanType()) then ([++$g] = booleanType())",
		"if ([$g] = floatType()) then ([++$g] = floatType())",
		"if ([$g] = integerType()) then ([++$g] = integerType())",
		"if ([$g] = nullType()) then ([++$g] = integerType())",
		"if ([$g] \<: objectType()) then ([++$g] \<: objectType())",
		"if ([$g] = resourceType()) then ([++$g] = resourceType())",
		"if ([$g] = stringType()) then (or([++$g] = floatType(), [++$g] = integerType(), [++$g] = stringType()))",
		
		// --$h;
		"[$h] \<: any()",
		"if ([$h] \<: arrayType(any())) then ([--$h] \<: arrayType(any()))",
		"if ([$h] = booleanType()) then ([--$h] = booleanType())",
		"if ([$h] = floatType()) then ([--$h] = floatType())",
		"if ([$h] = integerType()) then ([--$h] = integerType())",
		"if ([$h] = nullType()) then ([--$h] = integerType())",
		"if ([$h] \<: objectType()) then ([--$h] \<: objectType())",
		"if ([$h] = resourceType()) then ([--$h] = resourceType())",
		"if ([$h] = stringType()) then (or([--$h] = floatType(), [--$h] = integerType(), [--$h] = stringType()))"
	];
	return run("unaryOp", expected);
}

public test bool testBinaryOp() {
	list[str] expected = [
		// $a + $b;
		"[$a] \<: any()", "[$b] \<: any()",
		"or([$a + $b] \<: arrayType(any()), [$a + $b] \<: floatType())", // always array, or subtype of floatType()
		"if (and([$a] \<: arrayType(any()), [$b] \<: arrayType(any()))) then ([$a + $b] \<: arrayType(any()))", // ($a = array && $b = array) => [E] = array
		"if (or(neg([$a] \<: arrayType(any())), neg([$b] \<: arrayType(any())))) then ([$a + $b] \<: floatType())", // ($a != array || $b = array) => [E] <: float 
		
		// $c - $d;	
		"[$c] \<: any()", "[$d] \<: any()",
		"neg([$c] \<: arrayType(any()))",
		"neg([$d] \<: arrayType(any()))",
		"[$c - $d] \<: floatType()",
	
		// $e * $f;	
		"[$e] \<: any()", "[$f] \<: any()",
		"neg([$e] \<: arrayType(any()))",
		"neg([$f] \<: arrayType(any()))",
		"[$e * $f] \<: floatType()",
	
		// $g / $h;	
		"[$g] \<: any()", "[$h] \<: any()",
		"neg([$g] \<: arrayType(any()))",
		"neg([$h] \<: arrayType(any()))",
		"[$g / $h] \<: floatType()",
	
		// $i % $j;	
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i % $j] = integerType()",

		// $k & $l;	
		"[$k] \<: any()", "[$l] \<: any()",
		"if (and([$k] = stringType(), [$l] = stringType())) then ([$k & $l] = stringType())",
		"if (or(neg([$k] = stringType()), neg([$l] = stringType()))) then ([$k & $l] = integerType())",
		"or([$k & $l] = integerType(), [$k & $l] = stringType())",
		
		// $m | $n;	
		"[$m] \<: any()", "[$n] \<: any()",
		"if (and([$m] = stringType(), [$n] = stringType())) then ([$m | $n] = stringType())",
		"if (or(neg([$m] = stringType()), neg([$n] = stringType()))) then ([$m | $n] = integerType())",
		"or([$m | $n] = integerType(), [$m | $n] = stringType())",
		
		// $o ^ $p;	
		"[$o] \<: any()", "[$p] \<: any()",
		"if (and([$o] = stringType(), [$p] = stringType())) then ([$o ^ $p] = stringType())",
		"if (or(neg([$o] = stringType()), neg([$p] = stringType()))) then ([$o ^ $p] = integerType())",
		"or([$o ^ $p] = integerType(), [$o ^ $p] = stringType())",
		
		// $q << $r;	
		"[$q] \<: any()", "[$r] \<: any()",
		"[$q \<\< $r] = integerType()",
		
		// $s >> $t;	
		"[$s] \<: any()", "[$t] \<: any()",
		"[$s \>\> $t] = integerType()"
		
	];
	return run("binaryOp", expected);
}

public test bool testTernary() {
	list[str] expected = [
		// $a = true ? $b : "string";
		"[$a] \<: any()", "[$b] \<: any()", // $a and $b
		"[true] = booleanType()", "[\"string\"] = stringType()", // true and "string"
		"or([true ? $b : \"string\"] \<: [\"string\"], [true ? $b : \"string\"] \<: [$b])", // [E] = [E2] OR [E3]
		"[true ? $b : \"string\"] \<: [$a]", // [E] <: $a
		"[$a] \<: [$a = true ? $b : \"string\"]", // result of the whole expression is a subtype of $a
		
		// $c = TRUE ? : "str";
		"[$c] \<: any()", 
		"[TRUE] = booleanType()", "[\"str\"] = stringType()", // TRUE and "string"
		"or([TRUE ? : \"str\"] \<: [\"str\"], [TRUE ? : \"str\"] \<: [TRUE])", // [E] = [E1] OR [E3]
		"[TRUE ? : \"str\"] \<: [$c]", // [E] <: $c
		"[$c] \<: [$c = TRUE ? : \"str\"]", // result of the whole expression is a subtype of $c
	
		// $d = $e = 3 ? "l" : "r";
		"[$d] \<: any()", "[$e] \<: any()", 
		"[3] = integerType()", "[\"l\"] = stringType()", "[\"r\"] = stringType()", // 3, "l" and "r"
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
		"[$a and $b] = booleanType()",
		
		// $c or $d;
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c or $d] = booleanType()",
		
		// $e xor $f;
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e xor $f] = booleanType()",
		
		// $g && $h;
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g && $h] = booleanType()",
		
		// $i || $j;
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i || $j] = booleanType()"
	];
	return run("logicalOp", expected);
}

public test bool testComparisonOp() {
	list[str] expected = [
		// $a < $b;
		"[$a] \<: any()", "[$b] \<: any()",
		"[$a \< $b] = booleanType()",
		
		// $c <= $d;
		"[$c] \<: any()", "[$d] \<: any()",
		"[$c \<= $d] = booleanType()",
		
		// $e > $f;
		"[$e] \<: any()", "[$f] \<: any()",
		"[$e \> $f] = booleanType()",
		
		// $g >= $h;
		"[$g] \<: any()", "[$h] \<: any()",
		"[$g \>= $h] = booleanType()",
		
		// $i == $j;
		"[$i] \<: any()", "[$j] \<: any()",
		"[$i == $j] = booleanType()",
		
		// $k === $l;
		"[$k] \<: any()", "[$l] \<: any()",
		"[$k === $l] = booleanType()",
	
		// $m != $n;
		"[$m] \<: any()", "[$n] \<: any()",
		"[$m != $n] = booleanType()",
		
		// $o <> $p;
		"[$o] \<: any()", "[$p] \<: any()",
		"[$o \<\> $p] = booleanType()",
		
		// $q !== $r;
		"[$q] \<: any()", "[$r] \<: any()",
		"[$q !== $r] = booleanType()"
	];
	return run("comparisonOp", expected);
}

public test bool testCasts() {
	list[str] expected = [
		"[$a] \<: any()", "[$b] \<: any()", "[$c] \<: any()", "[$d] \<: any()", 
		"[$e] \<: any()", "[$f] \<: any()", "[$g] \<: any()", "[$h] \<: any()", 
		"[$i] \<: any()", "[$j] \<: any()", "[$k] \<: any()", 
		
		// (cast)$var;	
		"[(array)$a] \<: arrayType(any())",
		"[(bool)$b] = booleanType()",
		"[(boolean)$c] = booleanType()",
		"[(int)$d] = integerType()",
		"[(integer)$e] = integerType()",
		"[(float)$f] = floatType()",
		"[(double)$g] = floatType()",
		"[(real)$h] = floatType()",
		
		"[(string)$i] = stringType()",
		"if ([$i] \<: objectType()) then (hasMethod([$i], __tostring))",
		
		"[(object)$j] \<: objectType()",
		"[(unset)$k] = nullType()"
	];
	return run("casts", expected);
}

public test bool testarrayType() {
	list[str] expected = [
		// arrayType(); [];
		"[array()] = arrayType()",
		"[[]] = arrayType()",
		
		// arrayType("a", "b", "c");
		"[\"a\"] = stringType()", "[\"b\"] = stringType()", "[\"c\"] = stringType()",
		"[array(\"a\", \"b\", \"c\")] = arrayType([\"a\"], [\"b\"], [\"c\"])",
	
		// arrayType(0, "b", 3.4); 
		"[0] = integerType()", "[\"b\"] = stringType()", "[3.4] = floatType()",
		"[array(0, \"b\", 3.4)] = arrayType([\"b\"], [0], [3.4])",
		
		// [0,1,2];
		"[0] = integerType()", "[1] = integerType()", "[2] = integerType()", 
		"[[0,1,2]] = arrayType([0], [1], [2])",
		
		// $a[0];
		"[$a[0]] \<: any()", // not very specific!!!
		"[0] = integerType()",
		"[$a] \<: arrayType(any())",
		"[$a] \<: any()", 
		"neg([$a] \<: objectType())",
		
		// $b["def"]
		"[$b[\"def\"]] \<: any()", // not very specific!!!
		"[\"def\"] = stringType()",
		"[$b] \<: arrayType(any())",
		"[$b] \<: any()", 
		"neg([$b] \<: objectType())",
		
		// $c[0][0]
		"[$c[0][0]] \<: any()",
		"[0] = integerType()", "[0] = integerType()",
		"[$c] \<: arrayType(any())",
		"[$c] \<: any()", 
		"[$c[0]] \<: arrayType(any())",
		"[$c[0]] \<: any()",
		"neg([$c] \<: objectType())",
		"neg([$c[0]] \<: objectType())",
		
		// $d[] = 1;
		"[$d] \<: arrayType(any())",
		"[$d] \<: any()", 
		"[$d[]] \<: any()", 
		"neg([$d] \<: objectType())",
		"[1] = integerType()",
		"[1] \<: [$d[]]",
		"[$d[]] \<: [$d[] = 1]"
	];
	return run("array", expected);
}

public test bool testVarious() {
	list[str] expected = [
		// $a = clone($b);
		"[$a] \<: any()", 
		"[$a] \<: objectType()", 
		"[clone($a)] \<: objectType()",
		
		// new ABC();	
		"[new ABC()] = classType(|php+class:///abc|)",
		// new \DEF();	
		"[new \\DEF()] = classType(|php+class:///def|)",
		// new \GHI\JKL;	
		"[new \\GHI\\JKL] = classType(|php+class:///ghi/jkl|)",
		// new MNO\PQR;	
		"[new MNO\\PQR] = classType(|php+class:///qwerty/mno/pqr|)",
		
		// new $b();
		"[$b] \<: any()",
		"[new $b()] \<: objectType()"
	];
	return run("various", expected);
}

public test bool testControlStructures() {
	list[str] expected = [
		// if ($a1) {"10";}
		"[$a1] \<: any()", "[\"10\"] = stringType()", 
		// if ($b1) {"20";} else {"30";}
		"[$b1] \<: any()", "[\"20\"] = stringType()", "[\"30\"] = stringType()", 
		// if ($c1) {"40";} else if ("50") {$d1;} else {$e1;}
		// if ($c1) {"40";} elseif ("50") {$d1;} else {$e1;}
		"[$c1] \<: any()", 		"[$c1] \<: any()", 
		"[\"40\"] = stringType()",	"[\"40\"] = stringType()", 
		"[\"50\"] = stringType()",	"[\"50\"] = stringType()", 
		"[$d1] \<: any()",		"[$d1] \<: any()", 
		"[$e1] \<: any()",		"[$e1] \<: any()", 
		// if ($a2) "11";
		"[$a2] \<: any()", "[\"11\"] = stringType()", 
		// if ($b2) "21"; else "31";
		"[$b2] \<: any()", "[\"21\"] = stringType()", "[\"31\"] = stringType()", 
		// if ($c2) "41"; else if ("51") $d2; else $e2;
		"[$c2] \<: any()", "[$d2] \<: any()", "[$e2] \<: any()",
		"[\"41\"] = stringType()", "[\"51\"] = stringType()", 
		// if ($a1): "12"; endif;
		"[$a1] \<: any()", "[\"12\"] = stringType()", 
		
		// while($f1) { "60"; }
		"[$f1] \<: any()", "[\"60\"] = stringType()", 
		// while($f2)  "61";
		"[$f2] \<: any()", "[\"61\"] = stringType()", 
		// while ($f3): "62"; endwhile;	
		"[$f3] \<: any()", "[\"62\"] = stringType()", 
		
		// do { $g1; } while ($h1);
		"[$g1] \<: any()", "[$h1] \<: any()", 
		// do $g2; while ($h2);
		"[$g2] \<: any()", "[$h2] \<: any()", 
	
		// for ($i1=0; $i2<10; $i3++) { "70"; }	
		"[$i1] \<: any()", "[$i2] \<: any()", "[$i3] \<: any()", "[\"70\"] = stringType()", 
		// for ($i4; ;$i5) { "71"; }
		"[$i4] \<: any()", "[$i5] \<: any()", "[\"71\"] = stringType()", 
		// for (; ; ) { "72"; }
		"[\"72\"] = stringType()", 
		// for ($i6, $j7; $i8; $j9, $i11, $i12);
		"[$i6] \<: any()", "[$j7] \<: any()", "[$i8] \<: any()", 
		"[$j9] \<: any()", "[$i11] \<: any()", "[$i12] \<: any()", 
		
		// foreach ($k as $v) foreach ($kk as $vv) "80";
		"[$k] \<: any()", "[$v] \<: any()", 
		"[$kk] \<: any()", "[$vv] \<: any()", "[\"80\"] = stringType()", 
		// foreach ($arr as $key => $value) { "statement"; }
		"[$arr] \<: any()", "[$key] \<: any()", "[$value] \<: any()", "[\"statement\"] = stringType()",
		// foreach ($array as $element): "81"; endforeach;
		"[$array] \<: any()", "[$element] \<: any()", "[\"81\"] = stringType()", 
	
		// switch ($l2) { case 10; case "1str": "string"; break; default: "def"; }
		"[$l2] \<: any()", "[10] = integerType()", 
		"[\"1str\"] = stringType()", "[\"string\"] = stringType()", "[\"def\"] = stringType()", 
		// switch ($l2): case 20: "zero2"; break; case "2str": "string"; break; default: "def"; endswitch;	
		"[$l2] \<: any()", "[20] = integerType()", "[\"2str\"] = stringType()",
		"[\"zero2\"] = stringType()", "[\"string\"] = stringType()", "[\"def\"] = stringType()", 
		
		// declare(ticks=1) { $m; }
		"[$m] \<: any()",
		
		// goto a; 'Foo';  a: 'Bar';
		"[\'Foo\'] = stringType()", "[\'Bar\'] = stringType()",
		
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
		"[function a() {}] = nullType()",
		// function &b() {}
		"[function &b() {}] = nullType()",
		// function c() { return; }
		"or([function c() { return; }] = nullType())",
		// function d() { return true; return false; }
		"or([function d() { return true; return false; }] = [false], [function d() { return true; return false; }] = [true])",
		"[false] = booleanType()", "[true] = booleanType()",
		// function f() { function g() { return "string"; } }
		"[function f() { function g() { return \"string\"; } }] = nullType()",
		"or([function g() { return \"string\"; }] = [\"string\"])",
		"[\"string\"] = stringType()",
		
		// function h() { $a = "str"; $a = 100; }
		"[\"str\"] \<: [$a]",
		"[\"str\"] = stringType()",
		"[$a] \<: any()",
		"[$a] \<: any()",
		"[100] \<: [$a]",
		"[100] = integerType()",
		"[function h() { $a = \"str\"; $a = 100; }] = nullType()",
		"[$a] \<: [$a = \"str\"]",
		"[$a] \<: [$a = 100]",
		"[|php+functionVar:///h/a|] = [$a]",
		"[|php+functionVar:///h/a|] = [$a]",
		
		// function i() { $i = "str"; function j() { $i = 100; } }
		"[\"str\"] \<: [$i]",
		"[\"str\"] = stringType()",
		"[$i] \<: any()",
		"[$i] \<: any()",
		"[100] \<: [$i]",
		"[100] = integerType()",
		"[function i() { $i = \"str\"; function j() { $i = 100; } }] = nullType()",
		"[function j() { $i = 100; }] = nullType()",
		"[$i] \<: [$i = \"str\"]",
		"[$i] \<: [$i = 100]",
		"[|php+functionVar:///i/i|] = [$i]",
		"[|php+functionVar:///j/i|] = [$i]",
	
		// if (true) { function k() { $k1; } } else { function k() { $k2; } }	
		"[$k1] \<: any()",
		"[$k2] \<: any()",
		"[function k() { $k1; }] = nullType()",
		"[function k() { $k2; }] = nullType()",
		"[true] = booleanType()",
		
		// a();	
		"[a()] \<: [function a() {}]",
		// b();
		"[b()] \<: [function &b() {}]",
		// x(); // function does not exist
		// no constraints.... function does not exists
		
		//$x(); // variable call
		"[$x()] \<: any()",
		"or([$x] \<: objectType(), [$x] = stringType())",
		"if ([$x] \<: objectType()) then (hasMethod([$x], __invoke))"
	];
	return run("function", expected);
}

public test bool testClassMethod() {
	list[str] expected = [
		// [public function m1() {}] = nullType()
		"[public function m1() {}] = nullType()",
		
		// class C2 { public function m2() { function f1() { return "a"; } return true; } }
		"[\"a\"] = stringType()", "[true] = booleanType()",
		"or([public function m2() { function f1() { return \"a\"; } return true; }] = [true])",
		"or([function f1() { return \"a\"; }] = [\"a\"])",
		
		// class C3 { public function m3() { $a = 2; function f1() { $a = "a"; } return $a; } }
		"[$a] \<: any()", "[$a] \<: any()", "[$a] \<: any()", // variables
		"[2] = integerType()", "[\"a\"] = stringType()",  // int/string
		"[2] \<: [$a]", "[\"a\"] \<: [$a]", // assignment
		"[$a] \<: [$a = 2]", "[$a] \<: [$a = \"a\"]", // result of assignment
		"or([public function m3() { $a = 2; function f1() { $a = \"a\"; } return $a; }] = [$a])", // type of method
		"[function f1() { $a = \"a\"; }] = nullType()", // type of function
		"[|php+methodVar:///ns/c3/m3/a|] = [$a]",
		"[|php+functionVar:///ns/f1/a|] = [$a]"
	];
	return run("classMethod", expected);
}

public test bool testClassConstant() {
	list[str] expected = [
		// class C1 { const c1 = 100; }
		"[c1 = 100] = [100]",
		"[100] = integerType()",
		"[|php+classConstant:///classconstant/c1/c1|] = [c1 = 100]",
		// class C2 { const c21 = 21, c22 = 22; }
		"[c21 = 21] = [21]",
		"[21] = integerType()",
		"[c22 = 22] = [22]",
		"[22] = integerType()",
		"[|php+classConstant:///classconstant/c2/c21|] = [c21 = 21]",
		"[|php+classConstant:///classconstant/c2/c22|] = [c22 = 22]",
		 //interface C3 { const cInterface = "interface constant"; }
		"[cInterface = \"interface constant\"] = [\"interface constant\"]",
		"[\"interface constant\"] = stringType()",
		"[|php+classConstant:///classconstant/c3/cInterface|] = [cInterface = \"interface constant\"]" 
	];
	return run("classConstant", expected);
}

public test bool testClassProperty() {
	list[str] expected = [
		// class cl1 { public $pub1; public $pub2 = 2; }
		"[2] = integerType()",
		"[$pub2 = 2] = [2]",
		"[|php+field:///randomnamespace/cl1/pub1|] = [$pub1]",
		"[|php+field:///randomnamespace/cl1/pub2|] = [$pub2 = 2]",
		// class cl2 { private $priv1; private $priv2 = 2; }
		"[2] = integerType()",
		"[$priv2 = 2] = [2]",
		"[|php+field:///randomnamespace/cl2/priv1|] = [$priv1]",
		"[|php+field:///randomnamespace/cl2/priv2|] = [$priv2 = 2]",
		// class cl3 { protected $pro1; protected $pro2 = 2; }
		"[2] = integerType()",
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
		"[public function se() { self::foo(); }] = nullType()",
		"[self] = classType(|php+class:///ns/c|)",
		"or(hasMethod([self], foo, { static() }))",
		// public function pa() { parent::foo(); }
		"[public function pa() { parent::foo(); }] = nullType()",
		"or([parent] = classType(|php+class:///ns/p|))",
		"or(hasMethod([parent], foo, { static() }))",
		// public function st() { static::foo(); }	
		"[public function st() { static::foo(); }] = nullType()",
		"or([static] = classType(|php+class:///ns/c|), [static] = classType(|php+class:///ns/p|))",
		"or(hasMethod([static], foo, { static() }))"
    ];
	return run("classKeywords", expected);
}

public test bool testMethodCall() {
	// information is retreived from m3, declares in uses
	list[str] expected = [
		// $a->b();
		//"[$a] \<: any()",
		//"or(hasMethod([$a], b, { !static() })",
		
		// c::d(); // static call of (static) method d off class c
		"[c] \<: objectType()",
		"[c] \<: [class C { public static function d() {} }]",
		"[public static function d() {}] = nullType()",
		//"or(hasMethod([$c], d, { static() })",
		// if LHS is of type: current class -> 
		// if LHS is of one of the parent classes ->
		""
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
	m3 = calculateAfterM3Creation(m3, system);

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
	loc l = getFileLocation(fileName);
	
	for (f <- l.ls) {
		println();
		println("----------File Content: <f>----------");
		println(readFile(f));
		println();
	}
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
private str toStr(isMethodName(TypeOf t, str n))		= "isMethodName(<toStr(t)>, <n>)";
private str toStr(hasMethod(TypeOf t, str n))			= "hasMethod(<toStr(t)>, <n>)";
private str toStr(hasMethod(TypeOf t, str n, set[ModifierConstraint] mcs))	= "hasMethod(<toStr(t)>, <n>, { <intercalate(", ", sort([ toStr(mc) | mc <- sort(toList(mcs))]))> })";
private str toStr(required(set[Modifier] mfs))			= "<intercalate(", ", sort([ toStr(mf) | mf <- sort(toList(mfs))]))>";
private str toStr(notAllowed(set[Modifier] mfs))		= "<intercalate(", ", sort([ "!"+toStr(mf) | mf <- sort(toList(mfs))]))>";
default str toStr(Constraint c) { throw "Please implement toStr for node :: <c>"; }

private str toStr(typeOf(loc i)) 						= isFile(i) ? "["+readFile(i)+"]" : "[<i>]";
private str toStr(TypeOf::arrayType(set[TypeOf] expr))	= "arrayType(<intercalate(", ", sort([ toStr(e) | e <- sort(toList(expr))]))>)";
private str toStr(TypeSymbol t) 						= "<t>";
private str toStr(Modifier m) 							= "<m>";
default str toStr(TypeOf to) { throw "Please implement toStr for node :: <to>"; }