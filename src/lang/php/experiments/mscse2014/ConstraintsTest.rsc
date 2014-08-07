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
	assert true == testOpAssign();
}

public test bool testVariable() {
	str name = "variable";
	list[str] expected = [
		"[$a] \<: any()"
	];
	return run(name, expected);
}
public test bool testNormalAssign() {
	list[str] expected = [
		"[2] \<: [$a]",
		"[2] = int()",
		"[$a] \<: [$b]",
		"[$a] \<: any()", // twice because the variable occurs at two different places
		"[$a] \<: any()", 
		"[$b] \<: any()"
	];
	return run("normalAssign", expected);
}
public test bool testScalars() {
	list[str] expected = [
		"[__CLASS__] = string()",
		"[__DIR__] = string()",
		"[__FILE__] = string()",
		"[__FUNCTION__] = string()",
		"[__LINE__] = string()",
		"[__METHOD__] = string()",
		"[__NAMESPACE__] = string()",
		"[__TRAIT__] = string()",
		"[0.0] = float()",
		"[0.5] = float()",
		"[1000.0382] = float()",
		"[0] = int()",
		"[1] = int()",
		"[2] = int()",
		"[10] = int()",
		"[100] = int()",
		"[\"string\"] = string()",
		"[\'also a string\'] = string()",
		"[\"$encaped string\"] = string()",
		"[\"{$encaped} string\"] = string()"
	];
	return run("scalar", expected);
}
public test bool testOpAssign() {
	list[str] expected = [
		"[$a] \<: any()", "[$b] \<: any()", "[$a] = int()",
		"[$c] \<: any()", "[$d] \<: any()", "[$c] = int()",
		"[$e] \<: any()", "[$f] \<: any()", "[$e] = int()", 
		"[$g] \<: any()", "[$h] \<: any()", "[$g] = int()", 
		"[$i] \<: any()", "[$j] \<: any()", "[$i] = int()", 
		"[$k] \<: any()", "[$l] \<: any()", "[$k] = int()",
		
		"[$m] \<: any()", "[$n] \<: any()", "[$m] = string()",
		
		"[$o] \<: any()", "[$p] \<: any()", "[$o] = int()",
		"[$q] \<: any()", "[$r] \<: any()", "[$q] = int()"
	];
	return run("opAssign", expected);
}

public bool run(str fileName, list[str] expected)
{
	loc l = getFileLocation(fileName);
	
	System system = getSystem(l, false);
	M3 m3 = getM3ForSystem(system, false);

	set[Constraint] actual = getConstraints(system, m3);

	// for debugging purposes
	//printResult(fileName, expected, actual);
	
	// assert that expectedConstraints is a subset of ActualConstraints
	return assertPrettyPrinted(expected, actual);
}

//
// Assert pretty printed
//
private bool assertPrettyPrinted(list[str] expected, set[Constraint] actual) 
{
	list[str] actualPP = [ toStr(a) | a <- actual ];

	a = sort(actualPP);
	e = sort(expected);
	
	notInActual = a - e;
	notInExpected = e - a;	
	
	if (!isEmpty(notInActual) || !isEmpty(notInExpected))	
	{
		iprintln("Actual: <a>");
		iprintln("Expected: <e>");
		iprintln("Not in actual: <a-e>");
		iprintln("Not in expected: <e-a>");
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

private str toStr(eq(TypeOf a, TypeOf b)) 		= "<toStr(a)> = <toStr(b)>";
private str toStr(eq(TypeOf a, TypeSymbol ts)) 	= "<toStr(a)> = <toStr(ts)>";
private str toStr(subtyp(TypeOf a, TypeOf b)) 	= "<toStr(a)> \<: <toStr(b)>";
private str toStr(subtyp(TypeOf a, TypeSymbol ts)) 	= "<toStr(a)> \<: <toStr(ts)>";
default str toStr(Constraint c) { throw "Please implement toStr for node :: <c>"; }

private str toStr(typeOf(loc i)) 	= isFile(i) ? "["+readFile(i)+"]" : "[<i>]";
private str toStr(TypeSymbol t) 	= "<t>";