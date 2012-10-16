Introduction
------------

This repository contains our ongoing work on PHP program analysis.

Running Our Software
--------------------

The main prerequisites to running the PHP and Rascal code used
to implement our analysis are:

* the Java JDK, available from the [Java download][java] page or as
  part of the Mac Xcode toolset
* Eclipse, available on the [Eclipse download][eclipse] page
* PHP, available from the [PHP download][php] page in source format
  or as part of the Mac Xcode toolset
  
We still use Eclipse version 3.7 in most of our development, but 
are also using version 4.2 (Juno). Both should work fine.

Once these are installed, you can install the Eclipse Rascal plugin
by following the directions at the [Rascal download][rascal] page.

Note that we have made some changes since the last Rascal release to
increase the performance of reading and writing binary forms of
Rascal values, functionality which is used to store and load the parsed
forms of the PHP code we analyze. To take advantage of these changes,
you should use the Rascal [unstable release channel][unstable] instead
of the standard URL given in the downloading instructions. This release
is available at [http://www.rascal-mpl.org/unstable-updates][unstable].
If you use the normal release, it will still work, but saving the
parsed versions of the PHP systems inside the `buildBinaries`
call, shown below, will take much longer.

Also, the instructions specify that you should allocate 1GB
of RAM for Rascal; in some cases, since we are working with
the parsed representation of an entire system, this may need
to be adjusted upwards even beyond this. I currently have the
maximum heap size set to 4GB. This is needed especially for working
with Moodle, which is quite large.

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp]. The current version should work,
but we have also created tags corresponding to specific points
in time. For instance, the icse13 tag corresponds to the version
of the parser used for our [ICSE 2013 submission][icse2013].

[java]: http://www.oracle.com/technetwork/java/javase/downloads/index.html
[rascal]: http://www.rascal-mpl.org
[eclipse]: http://www.eclipse.org
[unstable]: http://www.rascal-mpl.org/unstable-updates
[php]: http://www.php.net/downloads.php
[phpp]: https://github.com/cwi-swat/PHP-Parser
[icse2013]: http://homepages.cwi.nl/~hills/publications/hills-klint-vinju-2013-icse-submitted.pdf

Note that we assume, for this README, that all code is being
placed in directory `~/PHPAnalysis`. To check out the parser
from Github, one would do:
    
    cd ~/PHPAnalysis
    git clone https://github.com/cwi-swat/PHP-Parser.git

Downloading the Corpus
----------------------

The corpus is rather large, so here we are providing just those
systems that we used in our experiments in our [ICSE 2013 submission][icse2013].
This is what we reference as the [most recent versions][mrvicse13] 
in the paper.

[mrvicse13]: http://homepages.cwi.nl/~hills/experiments/corpus-icse13.tgz

Assuming that `wget` is installed:
    
    cd ~/PHPAnalysis
    wget http://homepages.cwi.nl/~hills/experiments/corpus-icse13.tgz
    tar -xpzvf corpus-icse13.tgz

This will place the files into a subdirectory named `corpus-icse13`. If
`wget` is not installed, click on the [most recent versions][mrvicse13]
link, save this to the `~/PHPAnalysis` directory, and extract it with the
command given above.

Checking Out the PHP Analysis Project
-------------------------------------

To use the PHP Analysis code, you will first need to check it out
from its [Github repository][phpsa]. This can be done either with
the git command-line tools or using the git support built in to
Eclipse. For instance, you can import the PHP Analysis project
using the Eclipse Import functionality. There is currently only
one branch, master, which should be checked out.

[phpsa]: https://github.com/cwi-swat/php-analysis

If you use the Eclipse functionality for checking out the
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
would contain the following lines. Obviously, `/Users/mhills` should
be substituted for the location of your home directory, or whichever
other directory `PHPAnalysis` has been installed in:
    
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

Several of the files do not parse, so parse errors are reported in the console.
These are expected errors: one of the files, part of the Zend Framework, is
intended to trigger a parsing error, while the others are template files that
are intended to be filled in and are not valid PHP. There are also several files
that show the error `Expected Script, but got node`; this did not occur during
our tests with Eclipse 3.7 running on Linux, but this occurred with 3 files
while running with Eclipse 4.2 on Mac OS X. We are working to track down the
source of this bug and repair it.

Running the PHP Feature Usage Analysis Code
-------------------------------------------

The code to extract information on PHP feature usage is in folder
`lang/php/stats`, shown as package `lang.php.stats` in Eclipse. Most
of this code is in the Rascal module `lang::php::stats::Unfriendly`,
in file `Unfriendly.rsc`. This module contains code that measures the
use of "analysis unfriendly" features such as variable variables and
magic methods. This code also uses a number of functions defined
in `Stats.rsc` for extracting information on the uses of individual
features from PHP files. We ran this code ourselves, in the Rascal
console, to generate the information that appears in our ICSE 2013
submission; we are adding functions to automate this process to make
it easier for reviews to check. These functions should be added over
the next several days.