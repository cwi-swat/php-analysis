@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::BuiltIns

import Set;
import lang::php::analysis::signatures::Summaries;
import lang::php::analysis::NamePaths;

@doc{List from http://www.php.net/manual/en/reserved.constants.php}
private rel[str constName, str constType, str constVersion] builtIns = {
		< "PHP_VERSION","string","" >,
		< "PHP_MAJOR_VERSION","integer","5.2.7" >,
		< "PHP_MINOR_VERSION","integer","5.2.7" >,
		< "PHP_RELEASE_VERSION","integer","5.2.7" >,
		< "PHP_VERSION_ID","integer","5.2.7" >,
		< "PHP_EXTRA_VERSION","string","5.2.7" >,
		< "PHP_ZTS","integer","5.2.7" >,
		< "PHP_DEBUG","integer","5.2.7" >,
		< "PHP_MAXPATHLEN","integer","5.3.0" >,
		< "PHP_OS","string","" >,
		< "PHP_SAPI","string","4.2.0" >,
		< "PHP_EOL","string","4.3.10" >,
		< "PHP_EOL","string","5.0.2" >,
		< "PHP_INT_MAX","integer","4.4.0" >,
		< "PHP_INT_MAX","integer","5.0.5" >,
		< "PHP_INT_SIZE","integer","4.4.0" >,
		< "PHP_INT_SIZE","integer","5.0.5" >,
		< "DEFAULT_INCLUDE_PATH","string","" >,
		< "PEAR_INSTALL_DIR","string","" >,
		< "PEAR_EXTENSION_DIR","string","" >,
		< "PHP_EXTENSION_DIR","string","" >,
		< "PHP_PREFIX","string","4.3.0" >,
		< "PHP_BINDIR","string","" >,
		< "PHP_BINARY","string","5.4" >,
		< "PHP_MANDIR","string","5.3.7" >,
		< "PHP_LIBDIR","string","" >,
		< "PHP_DATADIR","string","" >,
		< "PHP_SYSCONFDIR","string","" >,
		< "PHP_LOCALSTATEDIR","string","" >,
		< "PHP_CONFIG_FILE_PATH","string","" >,
		< "PHP_CONFIG_FILE_SCAN_DIR","string","" >,
		< "PHP_SHLIB_SUFFIX","string","4.3.0" >,
		< "E_ERROR","integer","" >,
		< "E_WARNING","integer","" >,
		< "E_PARSE","integer","" >,
		< "E_NOTICE","integer","" >,
		< "E_CORE_ERROR","integer","" >,
		< "E_CORE_WARNING","integer","" >,
		< "E_COMPILE_ERROR","integer","" >,
		< "E_COMPILE_WARNING","integer","" >,
		< "E_USER_ERROR","integer","" >,
		< "E_USER_WARNING","integer","" >,
		< "E_USER_NOTICE","integer","" >,
		< "E_DEPRECATED","integer","5.3.0" >,
		< "E_USER_DEPRECATED","integer","5.3.0" >,
		< "E_ALL","integer","" >,
		< "E_STRICT","integer","5.0.0" >,
		< "__COMPILER_HALT_OFFSET__","integer","5.1.0" >,
		< "TRUE","boolean","" >,
		< "FALSE","boolean","" >,
		< "NULL","boolean","" >
	};

@doc{Get the names of all built-in constants.}
public set[str] getBuiltInConstants() = builtIns<0>;

@doc{Given a constant name, get the type of the constant.}
public str getBuiltInConstantType(str builtInConstant) = getOneFrom(builtIns[builtInConstant]<0>);

@doc{Given a constant name, get the versions at which this constant was first available}
public set[str] getBuiltInConstantVersions(str builtInConstant) = builtIns[builtInConstant,_];
	
@doc{Get constant summaries for each of the built-in constants.}	
public set[Summary] getBuiltInConstantSummaries() {
	return { constantSummary(constPath(cn),ct) | <cn,ct> <- builtIns<0,1> };
}