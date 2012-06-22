@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::pp::PrettyPrinter

import List;
import String;

private str pp(node nd) {
	switch(nd) {
		case script(l) : 
			return intercalate("\n",[pp(li)|li<-l]);

		case class_def(abstract(a),final(f),cn,extends(),implements(il),members(ml)) :
			return "<a?"abstract ":""><f?"final ":"">class <pp(cn)> <(size(il) != 0) ?"implements ":""><intercalate(",",[pp(ili)|ili<-il])>{
				   '  <intercalate("\n\n",[pp(mli)|mli<-ml])>
				   '}";		

		case class_def(abstract(a),final(f),cn,extends(en),implements(il),members(ml)) :
			return "<a?"abstract ":""><f?"final ":"">class <pp(cn)> extends <pp(en)> <(size(il) != 0) ?"implements ":""><intercalate(",",[pp(ili)|ili<-il])>{
				   '  <intercalate("\n\n",[pp(mli)|mli<-ml])>
				   '}";		

		case interface_def(inm,extends(el),members(ml)) :
			return "interface <pp(inm)> <(size(el) != 0) ?"extends ":""><intercalate(",",[pp(eli)|eli<-el])>{
				   '  <intercalate("\n\n",[pp(mli)|mli<-ml])>
				   '}";		

		case method(signature(\public(pb),protected(pr),\private(pv),static(st),abstract(a),final(f),pass_rest_by_ref(pbr),return_by_ref(rr),mn,parameters(fpl)),body(b)) :
			// TODO: When do we use pass_rest_by_ref
			return "<pb?"public ":""><pr?"protected ":""><pv?"private ":""><st?"static ":""><a?"abstract ":""><f?"final ":""><rr?"?":""><pp(mn)>(<intercalate(", ",[pp(fpli)|fpli<-fpl])>) {
				   '  <intercalate("\n",[pp(bi)|bi<-b])>
				   '}";
			
		case formal_parameter(\type(),ref(r),nwd) :
			return "<r?"&":""><pp(nwd)>";
			
		case formal_parameter(\type(t),ref(r),nwd) :
			return "<pp(t)> <r?"&":""><pp(nwd)>";
		
		case attribute(\public(pb),protected(pr),\private(pv),static(st),const(c),nwd) :
			return "<pb?"public ":""><pr?"protected ":""><pv?"private ":""><st?"static ":""><c?"const ":""><pp(nwd)>";
			
		case name(vn,\default()) :
			return "<pp(vn)>";
			
		case name(vn,\default(d)) :
			return "<pp(vn)> = <pp(d)>";
			
		case class_alias(\alias(c1),c2) :
			return "class <pp(c1)> = <pp(c2)>;";
			
		case interface_alias(\alias(i1),i2) :
			return "interface <pp(i1)> = <pp(i2)>;";
			
		case method_alias(\alias(m1),m2) :
			return "method <pp(m1)> = <pp(m2)>;";
			
		case \return() :
			return "return;";
			
		case \return(rv) :
			return "return(<pp(rv)>);";
			
		case static_decl(v) :
			return "static <pp(v)>;";
			
		case \global(g) :
			return "global <pp(g)>;";
			
		case \try(body(tb),catches(cs)) :
			return "try {
				   '  <intercalate("\n",[pp(tbi)|tbi<-tb])>
				   '}
				   '<intercalate("\n",[pp(csi)|csi<-cs])>
				   '";
				   
		case \catch(catch_type(ct),catch_name(cn),body(cb)) :
			return "catch (<pp(ct)> <pp(cn)>) {
				   '  <intercalate("\n",[pp(cbi)|cbi<-cb])>
				   '}";
			
		case \throw(v) :
			return "throw <pp(v)>;";
			
		case assign_var(vn,ref(r),e) :
			return "<pp(vn)> <r?"?":"">= <pp(e)>;";
			
		case assign_field(t,fn,ref(r),e) :
			return "<pp(t)>-\><pp(fn)> <r?"?":"">= <pp(e)>;";
			
		case assign_array(v,rv,ref(r),e) :
			return "<pp(v)>[<pp(rv)>] <r?"?":"">= <pp(e)>;";
			
		case assign_var_var(v,ref(r),e) :
			return "$<pp(v)> <r?"?":"">= <pp(e)>;";
			
		case assign_next(vn,ref(r),e) :
			// TODO: What does this do?
			return "<pp(vn)> <r?"?":"">= <pp(e)>;";
			
		case pre_op(op,vn) :
			return "<pp(op)><pp(vn)>;";
			
		case eval_expr(e) :
			return "<pp(e)>;";
			
		case unset(target(),name(v),indices(idxs)) :
			return "unset(<pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";

		case unset(target(t),name(v),indices(idxs)) :
			return "unset(<pp(t)>-\><pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";

		case isset(target(),name(v),indices(idxs)) :
			return "isset(<pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">)";

		case isset(target(t),name(v),indices(idxs)) :
			return "isset(<pp(t)>-\><pp(v)><(size(idxs)!=0)?"[":""><intercalate(":",[pp(i)|i<-idxs])><(size(idxs)!=0)?"]":"">);";

		case \int(z) :
			return "<z>";
		
		case \real(r) :
			return "<r>";
		
		case \str(s) :
			return "\"<s>\"";
		
		case \bool(b) :
			return "<b>";
		
		case nil() : 
			return "nil";
		
		case field_access(t,f) : 
			return "<pp(t)>-\><pp(f)>";
		
		case array_access(v,idx) :
			return "<pp(v)>[<pp(idx)>]";
			
		case array_next(v) :
			return "arraynext(<pp(v)>)";
			
		case cast(c,v) :
			return "(<pp(c)>) <pp(v)>";
			
		case unary_op(op,v) :
			return "<pp(op)><pp(v)>";
			
		case bin_op(l,op,r) :
			return "<pp(l)> <pp(op)> <pp(r)>";
			
		case constant(class(),cn) :
			return "<pp(cn)>";
			
		case constant(class(cln),cn) :
			return "<pp(cln)>-\><pp(cn)>";
			
		case instanceof(v,c) :
			return "<pp(v)> instanceof <pp(c)>";
			
		case invoke(target(), mn, actuals(al)) :
			return "<pp(mn)>(<intercalate(",",[pp(ali)|ali<-al])>)";
		
		case invoke(target(t), mn, actuals(al)) :
			return "<pp(t)>-\><pp(mn)>(<intercalate(",",[pp(ali)|ali<-al])>)";

		case new(cn, actuals(al)) :
			return "new <pp(cn)>(<intercalate(",",[pp(ali)|ali<-al])>)";
		
		case actual(ref(r),rv) :
			return "<r?"?":""><pp(rv)>";
			
		case variable_method(v) :
			return "$<pp(v)>";
			
		case variable_variable(v) :
			return "$<pp(v)>";
			
		case variable_class(v) :
			return "$<pp(v)>";
			
		case variable_field(v) :
			return "$<pp(v)>";
			
		case static_array(l) :
			return "array(<intercalate(",", [pp(li)|li<-l])>)";
			
		case static_array_elem(key(),ref(b),v) :
			return "<b?"?":""><pp(v)>";
					
		case static_array_elem(key(k),ref(b),v) :
			return "<pp(k)> =\> <b?"?":""><pp(v)>";

		case branch(vn,tb,fb) :
			return "branch(<pp(vn)>,<pp(tb)>,<pp(fb)>);";
			
		case goto(l) :
			return "goto <pp(l)>;";
			
		case label(l) :
			return "<pp(l)>:";
			
		case foreach_reset(vn,ht) :
			return "fe_reset(<pp(vn)>,<pp(ht)>);";
					
		case foreach_next(vn,ht) :
			return "fe_next(<pp(vn)>,<pp(ht)>);";

		case foreach_end(vn,ht) :
			return "fe_end(<pp(vn)>,<pp(ht)>);";

		case foreach_has_key(vn,ht) :
			return "fe_has_key(<pp(vn)>,<pp(ht)>)";
					
		case foreach_get_key(vn,ht) :
			return "fe_get_key(<pp(vn)>,<pp(ht)>)";

		case foreach_get_val(vn,ht) :
			return "fe_get_val(<pp(vn)>,<pp(ht)>)";
			
		case param_is_ref(target(), mn, n) :
			return "param_is_ref(<pp(mn)>,<n>)";

		case param_is_ref(target(t), mn, n) :
			return "param_is_ref(<pp(t)>-\><pp(mn)>,<n>)";

		case interface_name(inm) : 
			return "<inm>";
			
		case class_name(cn) : 
			return "<cn>";
			
		case method_name(mn) : 
			return "<mn>";
			
		case variable_name(vn) : 
			return "$<vn>";
			
		case field_name(fn) : 
			return "<fn>";
			
		case cast(cn) :
			return "<cn>";
			
		case op(x) :
			return "<x>";
			
		case constant_name(cn) : 
			return "<cn>";
			
		case label_name(ln) :
			return "<ln>";
			
		case ht_iterator(itn) :
			return "<itn>";
			
		default : return "<nd>";
	}
}

public str prettyPrinter(node n) {
	return pp(n);
}
