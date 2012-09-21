Introduction
------------

This repository contains our ongoing work on PHP program analysis.

Using Our Software
------------------

First, you will need to [download Rascal][rascal], which is
the language we use for our work. Since Rascal runs as an
Eclipse plugin, you will also need to [download Eclipse][eclipse].

[rascal]: http://www.rascal-mpl.org
[eclipse]: http://www.eclipse.org

We are currently using version 3.7 of Eclipse, although Rascal
should also work on the newest version, 4.2. Instructions for
installing Rascal are given on the Rascal download page. Note
that the instructions specify that you should allocate 1 GB
of RAM for Rascal; in some cases, since we are working with
the parsed representation of an entire system, this may need
to be adjusted upwards even beyond this. 

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp]. The current version should work,
but we have also created tags corresponding to specific points
in time. The icse13 tag corresponds to our ICSE 2013 submission.

[phpp]: https://github.com/cwi-swat/PHP-Parser

Note that we assume, for this README, that all code is being
placed in directory `~/PHPAnalysis`. To check out the parser,
one would do:
    
    cd ~/PHPAnalysis
    git clone https://github.com/cwi-swat/PHP-Parser.git

Downloading the Corpus
----------------------

The corpus is rather large, so here we are providing just those
systems that we used in our experiments in our ICSE 2013 submission.
This is what we reference as the [most recent versions][mrvicse13] 
in the paper.

[mrvicse13]: http://homepages.cwi.nl/~hills/experiments/corpus-icse13.tgz

Assuming that `wget` is installed:
    
    cd ~/PHPAnalysis
    wget http://homepages.cwi.nl/~hills/experiments/corpus-icse13.tgz
    tar -xpzvf corpus-icse13.tgz

This will place the files into a subdirectory named `corpus-icse13`.

Checking Out the PHP Analysis Project
-------------------------------------

To use the PHP Analysis code, you will first need to check it out
from its [Github repository][phpsa]. This can be done either with
the git command-line tools or using the git support built in to
Eclipse. For instance, you can import the PHP Analysis project
using the Eclipse Import functionality. There is currently only
one branch, master, which should be checked out.

[phpsa]: https://github.com/cwi-swat/php-analysis

Note that it may be the case that there are errors in the project.
This code is currently being modified, and these errors are due to
some of the code being transitioned away from Java implementations
to native Rascal implementations. They do not impact the analyses
used to extract feature usage information from the corpus.

Also, if you use the Eclipse functionality for checking out the
Github repository, make sure to NOT put the repository in the
same location that Eclipse will create the project (i.e., under
the workspace location you selected when you started Eclipse). If
you put the repository in this location, you will get an error,
since Eclipse will try to create a directory for the project with
the same name as the directory you gave for the repository.

Making Configuration Changes
----------------------------

Once the PHP Analysis project is imported, the paths to several files
need to be modified. This can be done in Rascal module lang::php::util::Config,
found in the project under src/lang/php/util in file Config.rsc.

* phploc points to the location of the php binary
* parserLoc points to the location of the PHP-Parser project
  * rgenLoc and rgenCwd then indicate the actual file and working directory used
    to perform parsing
* baseLoc provides the base location for a number of files created as part of
  the parsing and extraction process, including the directory where parsed
  files are stored and the root of the corpus

Given the working directory mentioned above, the configuration file
would contain the following lines:
    
    module lang::php::util::Config
    
    public loc phploc = |file:///usr/bin/php|;
    
    public loc parserLoc = |file:///Users/mhills/PHPAnalysis/PHP-Parser|;
    public loc rgenLoc = parserLoc + "lib/Rascal/AST2Rascal.php";
    public loc rgenCwd = parserLoc + "lib/Rascal";
    
    public loc baseLoc = |file:///Users/mhills/PHPAnalysis|;
    public loc parsedDir = baseLoc + "parsed";
    public loc statsDir = baseLoc + "stats";
    public loc corpusRoot = baseLoc + "corpus-icse13";
    public loc countsDir = baseLoc + "counts";
    
    public bool useBinaries = false;
    
Make sure that `useBinaries` is false; this should only be true in cases where you
have the binaries built and no longer have the source.

Building Binaries for Each Corpus Item
--------------------------------------

To build the binaries, first load lang::php::util::Utils in a Rascal console
(right click in an open Rascal file, such as the Utils module mentioned above,
and select Start Console, then `import lang::php::util::Utils`). Then, you
can run the command to build all the binaries:
    
    import lang::php::util::Utils;
    buildBinaries();

Running the Analysis Code
-------------------------

This information will be coming soon. We are currently adding a function
that will run all the analyses that we used while writing the paper. In
the meantime, it is possible to look through the files in the
`lang::php::stats` folder, especially `Unfriendly.rsc` (to analyze what
we referred to as the "unfriendly" features of the language, such as
variable functions and variables), `Stats.rsc`, and `Overall.rsc`.