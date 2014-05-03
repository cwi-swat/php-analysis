module tests::lang::php::m3::Core

import lang::php::m3::Core;
import lang::php::m3::FillM3;
import lang::php::m3::Containment;
import lang::php::m3::Uses;
import lang::php::util::Config;
import lang::php::ast::AbstractSyntax;

import IO;
import List;
import Map;
import Node;
import Relation;
import Set;

import ValueIO;

// test PHP Schemes
public test bool testIsNamespace() = isNamespace(|php+namespace:///|);
public test bool testIsClass()     = isClass(|php+class:///|);
public test bool testIsMethod()    = isMethod(|php+method:///|);
public test bool testIsTrait()     = isTrait(|php+trait:///|);
public test bool testIsParameter() = isParameter(|php+functionParam:///|) && isParameter(|php+methodParam:///|);
public test bool testIsFunction()  = isFunction(|php+function:///|);
public test bool testIsVariable()  = isVariable(|php+globalVar:///|) && isVariable(|php+functionVar:///|) && isVariable(|php+methodVar:///|);
public test bool testIsField()     = isField(|php+field:///|);
public test bool testIsInterface() = isInterface(|php+interface:///|);

// helpers
public loc emptyId = |file:///|;
public M3 m3 = m3(emptyId);

public M3Collection getM3s() {
	m3@names = { <"Class_1",|php+class:///Class_1|>, <"Class_2",|php+class:///Class_2|> };
	return (emptyId:m3);
}

// helpers 
public loc classTestFolder = analysisLoc + "src/tests/resources/class/";
public M3Collection classM3s = createM3sFromDirectory(classTestFolder);

// test createM3sFromDirectory
public test bool testFilesInModel() = size(classM3s) == size(classTestFolder.ls); 
public test bool testFileInModelPerFile() = classTestFolder+"Class.php" in classM3s;
public test bool testFileInModel2() = classTestFolder+"ClassAbstract.php" in classM3s;
public test bool testFileInModel3() = classTestFolder+"ClassFinal.php" in classM3s;

public test bool testModifierInModel1() = isEmpty(classM3s[classTestFolder+"Class.php"]@modifiers);
public test bool testModifierInModel2() = {abstract()}== range(classM3s[classTestFolder+"ClassAbstract.php"]@modifiers);
public test bool testModifierInModel3() = {final()} == range(classM3s[classTestFolder+"ClassFinal.php"]@modifiers);

public rel[str,Modifier] actualClassModifiers = (classM3s[classTestFolder+"ClassPopulated.php"]@names o classM3s[classTestFolder+"ClassPopulated.php"]@modifiers);
public rel[str,Modifier] expectedClassModifiers = { 
    <"publicFieldC", \public()>,
    <"publicFieldB", \public()>,
	<"protectedField", protected()>, 
	<"privateField", \private()>, 
	<"publicfunction", \public()>, 
	<"publicstaticfunction", \public()>, 
	<"publicstaticfunction", static()>, 
	<"publicfinalfunction", \public()>, 
	<"publicfinalfunction", final()>, 
	<"protectedfunction", protected()>,
	<"privatefunction", \private()>
	};
	
public test bool testClassModifiers() =  actualClassModifiers == expectedClassModifiers;

public loc testFolder = analysisLoc + "src/tests/resources/m3";

public test bool testContainment() {
	M3Collection m3s = createM3sFromDirectory(testFolder);
	for (f <- testFolder.ls) {
		if (f.extension == "containment") {
			rel[loc from, loc to] expected = readTextValueFile(#rel[loc,loc], f);
			loc phpFile = getPhpFileNameFromContainmentFile(f);
			if (m3s[phpFile]@containment != expected) {
				printFailedTest(phpFile, f, expected, m3s[phpFile]@containment);
				return false;
			}
		}
		if (f.extension == "uses") {
			rel[loc from, loc to] expected = readTextValueFile(#rel[loc,loc], f);
			loc phpFile = getPhpFileNameFromUsesFile(f);
			if (m3s[phpFile]@uses != expected) {
				printFailedTest(phpFile, f, expected, m3s[phpFile]@uses);
				return false;
			}
		}
	}
	return true;
}

private loc getPhpFileNameFromContainmentFile(loc f) = testFolder+"<f.file[0..-12]>.php";
private loc getPhpFileNameFromUsesFile(loc f) = testFolder+"<f.file[0..-5]>.php";

private void printFailedTest(loc phpFile, loc testFile, rel[loc,loc] expected, rel[loc,loc] actual) {
    println("Test failed for file: `<phpFile.file>`, `<testFile.file>` (test stopped)");
    println("Not in expected/actual:");
    println(actual - expected);
    println(expected - actual);
}