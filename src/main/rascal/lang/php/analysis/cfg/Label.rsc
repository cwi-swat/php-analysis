@license{

  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::Label

import lang::php::ast::AbstractSyntax;

@doc{Labels are added to expressions and statements to give us a 
     shorthand to refer to the various statements, expressions, and
     sub-statements/sub-expressions in the code.}
data Lab = lab(int id);

public data Expr(Lab lab=lab(-1));
public data Stmt(Lab lab=lab(-1));
