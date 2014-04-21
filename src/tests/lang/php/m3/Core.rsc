module tests::lang::php::m3::Core

import analysis::m3::Core;
import lang::php::m3::Core;
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
public test bool testIsParameter() = isParameter(|php+parameter:///|);
public test bool testIsFunction()  = isFunction(|php+function:///|);
public test bool testIsVariable()  = isVariable(|php+variable:///|);
public test bool testIsField()     = isField(|php+field:///|);
public test bool testIsInterface() = isInterface(|php+interface:///|);

// helpers
public loc emptyId = |file:///|;
public M3 m3 = m3(emptyId);

public M3Collection getM3s() {
	m3@names = { <"Class_1",|php+class:///Class_1|>, <"Class_2",|php+class:///Class_2|> };
	return (emptyId:m3);
}
// test getPossibleClassesInSystem 
public test bool findClass_1() = {|php+class:///Class_1|} == getPossibleClassesInSystem(getM3s(), "Class_1");
public test bool findClass_2() = {|php+class:///Class_2|} == getPossibleClassesInSystem(getM3s(), "Class_2");
public test bool findClass_3() = {|php+unknownClass:///Class_3|} == getPossibleClassesInSystem(getM3s(), "Class_3");
public test bool findUnknown() = {|php+unknownClass:///Unknown|} == getPossibleClassesInSystem(getM3s(), "Unknown");


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

public test bool testExtends() 	  = 1 == size(classM3s[classTestFolder+"ClassAExtendsB.php"]@extends);
public test bool testImplements() = 2 == size(classM3s[classTestFolder+"ClassAImplementsCD.php"]@implements);

public rel[str,Modifier] actualClassModifiers = (classM3s[classTestFolder+"ClassPopulated.php"]@names o classM3s[classTestFolder+"ClassPopulated.php"]@modifiers);
public rel[str,Modifier] expectedClassModifiers = { 
	<"publicFieldB", \public()>, 
	<"publicFieldC", \public()>, 
	<"protectedField", protected()>, 
	<"privateField", \private()>, 
	<"publicFunction", \public()>, 
	<"publicStaticFunction", \public()>, 
	<"publicStaticFunction", static()>, 
	<"publicFinalFunction", \public()>, 
	<"publicFinalFunction", final()>, 
	<"protectedFunction", protected()>,
	<"privateFunction", \private()>};
	
public test bool testClassModifiers() =  actualClassModifiers == expectedClassModifiers;

public test bool testContainment() {
	loc testFolder = analysisLoc + "src/tests/resources/m3";
	M3Collection m3s = createM3sFromDirectory(testFolder);
	for (f <- testFolder.ls) {
		if (f.extension == "containment") {
			rel[loc from, loc to] expectedContainment = readTextValueFile(#rel[loc,loc], f);
			loc phpFileName = testFolder+"<f.file[0..-12]>.php";
			if (m3s[phpFileName]@containment != expectedContainment) {
				iprintln("Test failed for file: `<phpFileName.file>`, `<f.file>` (test stopped)");
				iprintln("Not in expected/actual:");
				iprintln(m3s[phpFileName]@containment - expectedContainment);
				iprintln(expectedContainment - m3s[phpFileName]@containment);
				return false;
			}
		}
	}
	return true;
}