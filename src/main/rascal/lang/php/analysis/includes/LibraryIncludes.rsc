@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::includes::LibraryIncludes

data LibItem = library(str name, str path, str desc);

public set[LibItem] getKnownLibraries() {
	// These need to be moved into configuration, but just put them here for now
	return {
		//library("Mail", "Mail.php", "Mailer")
	};	
}

private map[str, set[loc]] standardLibraries =
	( "PearMail" : { |php+lib:///Mail.php|, |php+lib:///Mail/RFC822.php| },
	  "PearMailMime" : { |php+lib:///Mail/mime.php| },
	  "PHPUnit" : { |php+lib:///PHPUnit/Autoload.php|, 
	  				|php+lib:///PHPUnit/Runner/Version.php|, 
	  				|php+lib:///PHPUnit/TextUI/Command.php|, 
	  				|php+lib:///PHPUnit/TextUI/ResultPrinter.php|, 
	  				|php+lib:///PHPUnit/TextUI/TestRunner.php|, 
	  				|php+lib:///PHPUnit/Framework/TestListener.php|, 
	  				|php+lib:///PHPUnit/Framework/TestResult.php|, 
	  				|php+lib:///PHPUnit/Framework.php|,
	  				|php+lib:///PHPUnit/Util/Report.php|, 
	  				|php+lib:///PHPUnit/Framework/TestCase.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint.php|,
	  				|php+lib:///PHPUnit/Framework/TestSuite.php|, 
	  				|php+lib:///PHPUnit/Framework/MockObject/Stub/Exception.php|,
	  				|php+lib:///PHPUnit/Util/Filter.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint/TraversableContainsOnly.php|,
	  				|php+lib:///PHPUnit/Framework/ExpectationFailedException.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint/IsEqual.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint/IsInstanceOf.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint/IsNull.php|,
	  				|php+lib:///PHPUnit/Framework/Constraint/IsTrue.php| },
	  "PHPUnitDB" : { |php+lib:///PHPUnit/Extensions/Database/DataSet/FlatXmlDataSet.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/Operation/IDatabaseOperation.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DB/IDatabaseConnection.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/IDataSet.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/Operation/Exception.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/Operation/Factory.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DefaultTester.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DB/IMetaData.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/QueryDataSet.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/AbstractTable.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/DefaultTableMetaData.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/QueryTable.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DB/DefaultDatabaseConnection.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/TestCase.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/DataSet/CompositeDataSet.php|,
	  				  |php+lib:///PHPUnit/Extensions/Database/Autoload.php|  },
	  "PHPUnitException" : { |php+lib:///PHPUnit/Extensions/ExceptionTestCase.php| },
	  "Benchmark" : { |php+lib:///Benchmark/Timer.php|, |php+lib:///Benchmark/Iterate.php|,
	  				  |php+lib:///Benchmark/Profiler.php| },
	  "CodeCoverage" : { |php+lib:///PHP/CodeCoverage.php|, |php+lib:///PHP/CodeCoverage/Filter.php|,
	  					 |php+lib:///PHP/CodeCoverage/Report/HTML.php| },
	  "PearCache" : { |php+lib:///Cache.php| },
	  "PearCacheLite" : { |php+lib:///Cache/Lite.php| },
	  "PearDB" : { |php+lib:///DB.php| },
	  "PearSOAP" : { |php+lib:///SOAP/Client.php| },
	  "PearOpenID" : { |php+lib:///OpenID/RelyingParty.php| },
	  "PearCrypt" : { |php+lib:///Crypt/Hash.php| },
	  "PearArchiveTar" : { |php+lib:///Archive/Tar.php| },
	  "PearBase" : { |php+lib:///PEAR/FTP.php|,|php+lib:///PEAR/PackageFile/v1.php|, 
	  				 |php+lib:///PEAR/PackageFile/Generator/v1.php|, |php+lib:///PEAR/PackageFile/v2.php|, 
	  				 |php+lib:///PEAR/PackageFile/v2/rw.php|,  |php+lib:///PEAR/PackageFile/v2/Validator.php|,
	  				 |php+lib:///PEAR/PackageFile/Generator/v2.php|, |php+lib:///PEAR/FixPHP5PEARWarnings.php|,
	  				 |php+lib:///PEAR.php|, |php+lib:///PEAR/Frontend.php|,
	  				 |php+lib:///PEAR/Registry.php|, |php+lib:///PEAR/Config.php|,
	  				 |php+lib:///PEAR/Command.php|, |php+lib:///PEAR/Exception.php|,
	  				 |php+lib:///PEAR/Frontend.php|, |php+lib:///PEAR/Package.php|},
	  "PearStructuresGraph" : { |php+lib:///Structures/Graph.php|, |php+lib:///Structures/Graph/Node.php|,
	  							|php+lib:///Structures/Graph/Manipulator/TopologicalSorter.php|,
	  							|php+lib:///Structures/Graph/Manipulator/AcyclicSorter.php| },
	  "PearConsoleGetopt" : { |php+lib:///Console/Getopt.php| },
	  "PearXMLUtil" : { |php+lib:///XML/Util.php| },
	  "PearCommandPackaging" : { |php+lib:///PEAR/Command/Packaging.php| },
	  "PearPackageFileManager" : { |php+lib:///PEAR/PackageFileManager.php| },
	  "PearPackageFileManager2" : { |php+lib:///PEAR/PackageFileManager2.php| },
	  "PearNetDIME" : { |php+lib:///Net/DIME.php| }
	);

public set[loc] getStandardLibraries(str libname...) = { *standardLibraries[ln] | ln <- libname };
 