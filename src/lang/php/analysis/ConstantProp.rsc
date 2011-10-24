@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::ConstantProp

import Set;
import Node;

// Perform a simple constant propagation just to push the strings back into include,
// include_once, require, and require_once calls. This way we can figure out which
// scripts are beign loaded, and also we can figure out which of these functions
// take actual variables, not just constant strings. 
public node propIncludesRequires(node script) {
	// First, get back all the calls
	set[str] irvars = { vn | /i:invoke(target(),method_name("require_once"),actuals([actual(ref(false),variable_name(vn))])) <- script } +
					  { vn | /i:invoke(target(),method_name("require"),actuals([actual(ref(false),variable_name(vn))])) <- script } +
					  { vn | /i:invoke(target(),method_name("include_once"),actuals([actual(ref(false),variable_name(vn))])) <- script } +
					  { vn | /i:invoke(target(),method_name("include"),actuals([actual(ref(false),variable_name(vn))])) <- script };
					    
	// Second, get all assignments where a string literal is assigned into the name
	rel[str,str] assigns = { <vn,s> | /n:assign_var(variable_name(vn),ref(false),\str(s)) <- script, vn in irvars };
	
	// Third, convert this into a map if possible
	map[str,str] assignsMap = ( );
	for (vn <- assigns<0>) if (size(assigns[vn]) == 1) assignsMap[vn] = getOneFrom(assigns[vn]);
	  
	// Fourth, substitute these literals into the invocations
	script = visit(script) {
		case invoke(target(),method_name("require_once"),actuals([actual(ref(false),variable_name(vn))])) =>
			 "invoke"("target"(),"method_name"("require_once"),"actuals"(["actual"("ref"(false),"str"(assignsMap[vn]))]))
			 when vn in assignsMap

		case invoke(target(),method_name("require"),actuals([actual(ref(false),variable_name(vn))])) =>
			 "invoke"("target"(),"method_name"("require"),"actuals"(["actual"("ref"(false),"str"(assignsMap[vn]))]))
			 when vn in assignsMap

		case invoke(target(),method_name("include_once"),actuals([actual(ref(false),variable_name(vn))])) =>
			 "invoke"("target"(),"method_name"("include_once"),"actuals"(["actual"("ref"(false),"str"(assignsMap[vn]))]))
			 when vn in assignsMap

		case invoke(target(),method_name("include"),actuals([actual(ref(false),variable_name(vn))])) =>
			 "invoke"("target"(),"method_name"("include"),"actuals"(["actual"("ref"(false),"str"(assignsMap[vn]))]))
			 when vn in assignsMap
	};
	return script;
}