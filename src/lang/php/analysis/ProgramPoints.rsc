@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::ProgramPoints

import lang::php::analysis::Split;
import IO;

data ProgramPoint = pp(int pp);
public ProgramPoint newProgramPoint() { return pp(1); }
public ProgramPoint nextProgramPoint(ProgramPoint p) { return pp(p.pp + 1); }
public anno ProgramPoint node@pp;

private tuple[node,ProgramPoint] addPoint(node n, ProgramPoint p) {
	switch(n) { 
		case class_def(abstract(a),final(f),cn,extends(),implements(il),members(ml)) : {
			< ml, p > = addPoint(ml,p);
			return < "class_def"("abstract"(a),"final"(f),cn,"extends"(),"implements"(il),"members"(ml)), p >;
		}
		
		case class_def(abstract(a),final(f),cn,extends(en),implements(il),members(ml)) : {
			< ml, p > = addPoint(ml,p);
			return < "class_def"("abstract"(a),"final"(f),cn,"extends"(en),"implements"(il),"members"(ml)), p >;
		}
		
		case interface_def(inm,extends(el),members(ml)) : {
			< ml, p > = addPoint(ml,p);
			return < "interface_def"(inm,"extends"(el),"members"(ml)), p >;
		}
		
		case method(signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)),body(b)) : {
			< b, p > = addPoint(b, p);
			return < "method"("signature"("public"(pb),"protected"(pr),"private"(pv),"static"(st),"abstract"(a),"final"(f),"pass_rest_by_ref"(pbr),"return_by_ref"(rr),mn,"parameters"(fpl)),"body"(b)), p >;
		}
		
		case \try(body(tb),catches(cs)) : {
			< tb, p > = addPoint(tb, p);
			< tc, p > = addPoint(cs, p);
			n = "try"("body"(tb),"catches"(cs));
		}
		
		case \catch(catch_type(ct),catch_name(cn),body(cb)) : {
			< cb, p > = addPoint(cb, p);
			n = "catch"("catch_type"(ct),"catch_name"(cn),"body"(cb));
		}
	}
	return < n[@pp=p],nextProgramPoint(p) >; 
}

private tuple[list[node],ProgramPoint] addPoint(list[node] nl, ProgramPoint p) {
	list[node] res = [ ];
	for (n <- nl) { < n, p > = addPoint(n,p); res = res + n; }
	return < res, p >;
}
   
public rel[Owner,str,list[node]] addProgramPoints(rel[Owner,str,list[node]] ss) {
	println("Adding program points");
	rel[Owner,str,list[node]] res = { };
	ProgramPoint p = newProgramPoint();
	for (<o,s,list[node] b> <- ss) {
		< b, p > = addPoint(b,p);
		res = res + < o, s, b >;
	}
	return res;
}

public node addProgramPoints(node n) {
	println("Adding program points");
	ProgramPoint p = newProgramPoint();
	if (script(scr) := n) { < scr, p > = addPoint(scr, p); return "script"(scr); }
	throw "Unexpected node passed, expected script";
}
