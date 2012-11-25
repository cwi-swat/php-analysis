@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::BuiltIns

import Set;
import lang::php::analysis::signatures::Signatures;
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
	return { constantSummary([global(),const(cn)],ct) | <cn,ct> <- builtIns<0,1> };
}