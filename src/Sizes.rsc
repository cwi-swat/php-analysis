@generated
module Sizes
import lang::csv::IO;

alias getLinesType = rel[str \product,str \version,str \file,int \phplines];

public getLinesType getLines() {
   return readCSV(#rel[str \product,str \version,str \file,int \phplines], |project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|, ());
}
