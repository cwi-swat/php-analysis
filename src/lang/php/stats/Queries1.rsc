module lang::php::stats::Queries1

import Prelude;
import lang::csv::IO;
import lang::php::util::Utils;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=csvExprs|;
import Stmts = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/stmts.csv?funname=csvStmts|;

int firstCnt = 2;
int lastCnt = 30;
 
alias FeatureType = tuple[str \product, str \version, int \array, int \fetcharraydim, int \fetchclassconst, int \assign, int \assignwithoperationbitwiseand, int \assignwithoperationbitwiseor, int \assignwithoperationbitwisexor, int \assignwithoperationconcat, int \assignwithoperationdiv, int \assignwithoperationminus, int \assignwithoperationmod, int \assignwithoperationmul, int \assignwithoperationplus, int \assignwithoperationrightshift, int \assignwithoperationleftshift, int \assignwithoperationbooleanand, int \assignwithoperationbooleanor, int \assignwithoperationlogicaland, int \assignwithoperationlogicalor, int \assignwithoperationlogicalxor, int \listassign, int \refassign, int \binaryoperationbitwiseand, int \binaryoperationbitwiseor, int \binaryoperationbitwisexor, int \binaryoperationconcat, int \binaryoperationdiv, int \binaryoperationminus, int \binaryoperationmod, int \binaryoperationmul, int \binaryoperationplus, int \binaryoperationrightshift, int \binaryoperationleftshift, int \binaryoperationbooleanand, int \binaryoperationbooleanor, int \binaryoperationgt, int \binaryoperationgeq, int \binaryoperationlogicaland, int \binaryoperationlogicalor, int \binaryoperationlogicalxor, int \binaryoperationnotequal, int \binaryoperationnotidentical, int \binaryoperationlt, int \binaryoperationleq, int \binaryoperationequal, int \binaryoperationidentical, int \unaryoperationbooleannot, int \unaryoperationbitwisenot, int \unaryoperationpostdec, int \unaryoperationpredec, int \unaryoperationpostinc, int \unaryoperationpreinc, int \unaryoperationunaryplus, int \unaryoperationunaryminus, int \new, int \classconst, int \casttoint, int \casttobool, int \casttofloat, int \casttostring, int \casttoarray, int \casttoobject, int \casttounset, int \clone, int \closure, int \fetchconst, int \empty, int \suppress, int \eval, int \exit, int \call, int \methodcall, int \staticcall, int \include, int \instanceOf, int \isSet, int \print, int \propertyfetch, int \shellexec, int \exit, int \fetchstaticproperty, int \scalar, int \var,
 int \break, int \classdef, int \const, int \continue, int \declare, int \do, int \echo, int \expressionstatementchainrule, int \for, int \foreach, int \functiondef, int \global, int \goto, int \haltcompiler, int \if, int \inlineHTML, int \interfacedef, int \traitdef, int \label, int \namespace, int \return, int \static, int \switch, int \throw, int \trycatch, int \unset, int \use, int \whiledef];

alias FeatureRel = set[FeatureType];

list[int] getCounts(FeatureType tp){
  return 
    for(i <- [firstCnt .. lastCnt])
      append tp[i];
}

public void q1(){

   exprs = csvExprs();
   stmts = csvStmts();
  
   FeatureRel features = {   e + s  | e <- exprs, {s} := stmts[e.product,e.version] };
   featureUsage = [<f.product, f.version, sum(getCounts(f))> | FeatureType f <- features];
   
   featureUsage = sort(featureUsage, bool (&T a, &T b) { return a[2] > b[2]; });
   for( u <- featureUsage)
     println(u);
}
