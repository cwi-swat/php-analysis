Introduction
------------

This repository contains our ongoing work on PHP Analysis in Rascal
(PHP AiR).

Running Our Software
--------------------

The main prerequisites to running the PHP, Java, and Rascal code
used to implement our analysis are:

* Java JDK version 1.7, available from the [Java download][java]
* Eclipse, available on the [Eclipse download][eclipse] page
* PHP, available from the [PHP download][php] page in source format
  or as part of the Mac Xcode toolset
  
Eclipse versions 3.7, 4.2 (Juno), and 4.3 (Kepler) should both work
fine. The latest version of PHP should also work -- we use PHP to
parse PHP files, but otherwise just pick the version you need to
run the PHP software you plan to use (variants of 5.3 or greater
should all work).

Once these are installed, you can install the Eclipse Rascal plugin
by following the directions at the [Rascal download][rascal] page.

Note that we are actively developing Rascal, which means the standard
plugin is more stable, but potentially slower and missing some new
features. You can use the Rascal [unstable release channel][unstable]
to get the most recent version of Rascal which builds and passes all
unit tests. This release is available at [http://www.rascal-mpl.org/unstable-updates][unstable].

Also, the Rascal installation instructions specify that you should
allocate 1GB of RAM for Rascal; in some cases, since we are working
with large amounts of source code, this may need to be adjusted upwards
even beyond this. For most functionality in the analysis, a maximum
heap size of 4GB is fine. Some operations may require more, especially
those that work over not just one system, but multiple systems at the
same time, for instance in the work we are doing on comparing
how features are used in various systems. 

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp].

[java]: http://www.oracle.com/technetwork/java/javase/downloads/index.html
[rascal]: http://www.rascal-mpl.org
[eclipse]: http://www.eclipse.org
[unstable]: http://www.rascal-mpl.org/unstable-updates
[php]: http://www.php.net/downloads.php
[phpp]: https://github.com/cwi-swat/PHP-Parser
[icse2013]: http://www.cs.ecu.edu/hillsma/publications/hills-klint-vinju-2013-icse-submitted.pdf
[issta2013]: http://www.cs.ecu.edu/hillsma/publications/php-feature-usage.pdf
[esecfse2013]: http://www.cs.ecu.edu/hillsma/publications/resolving-php-includes.pdf

Note that we assume, for this README, that all code is being
placed in directory `~/PHPAnalysis`. To check out the parser
from Github, one would do:
    
    cd ~/PHPAnalysis
    git clone https://github.com/cwi-swat/PHP-Parser.git

Downloading the Corpus
----------------------

The corpus is rather large, so here we are providing just those
systems that we used in our experiments in our [ISSTA 2013 submission][issta2013]
(the same corpus was used in our [ICSE 2013 submission][icse2013]) and in our
[ESEC/FSE 2013 submission][esecfse2013]. The [first part of the corpus][corpus1]
is used in both papers, while [the second][corpus2] is used just in the
[ESEC/FSE 2013 submission][esecfse2013]. We have also just uploaded
a single archive containing all releases of [WordPress][corpus3] available
on the WordPress site through version 3.6. We still need to incorporate
3.6.1 and 3.7, and then will try to keep this up to date as new versions
are released. You can also download new versions and put them into the
existing directory created for WordPress, so you do not need to download
this again every time.

[corpus1]: http://www.cs.ecu.edu/hillsma/experiments/corpus-icse13.tgz
[corpus2]: http://www.cs.ecu.edu/hillsma/experiments/corpus-includes-extension.tgz
[corpus3]: http://www.cs.ecu.edu/hillsma/experiments/wordpress.tgz

Assuming that `wget` is installed:
    
    cd ~/PHPAnalysis
    wget http://www.cs.ecu.edu/hillsma/experiments/corpus-icse13.tgz
    tar -xpzvf corpus-icse13.tgz

and, if needed:

    wget http://www.cs.ecu.edu/hillsma/experiments/corpus-includes-extension.tgz
    tar -xpzvf corpus-includes-extension.tgz

To get the WordPress releases, just do:

    wget http://www.cs.ecu.edu/hillsma/experiments/wordpress.tgz
    tar -xpzvf wordpress.tgz

The first  will place the files into a subdirectory named `corpus-icse13`.
If `wget` is not installed, click on the [base corpus][corpus1]
link, save this to the `~/PHPAnalysis` directory, and extract it with the
command given above. The last will put all the WordPress releases into
a directory named WordPress. To make this easier to find, this can be
placed under the corpus directory created for the first download. If
you go this, PHP AiR will automatically find all the versions of
WordPress.

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

Setting Configuration Options
-----------------------------

Once the PHP Analysis project is imported, the paths to several files
need to be configured. This can be done in Rascal module lang::php::util::Config.
You should create this by copying file `/src/lang/php/util/Config.rsc-dist` to
`/src/lang/php/util/Config.rsc` and then making any needed changes.

* phploc points to the location of the php binary
* parserLoc points to the location of the PHP-Parser project
* analysisLoc points to the location of the php-analysis project
* astToRascal points to the location of file AST2Rascal.php inside PHP-Parser
* parserWorkingDir points to the location of the working directory for when the parser runs
* baseLoc provides the base location for a number of files created as part of
  the parsing and extraction process, including the directory where parsed
  files are stored and the root of the corpus; the remaining directories are
  subdirectories of this
* logLevel indicates how much debugging information will be seen, and can be set to
  0 to turn output of this information off

Given the working directory mentioned above, the configuration file
would contain the following lines. Obviously, `/Users/hillsma` should
be substituted for the location of your home directory, or whichever
other directory `PHPAnalysis` has been installed in:
    
    module lang::php::util::Config

    @doc{Indicates whether to use the parser contained in a distributed jar file or from the directory given below}
    public bool usePhpParserJar = false;

    @doc{The location of the PHP executable}
    public loc phploc = |file:///usr/local/php5/bin/php|;

    @doc{The base install location for the PHP-Parser project}
    public loc parserLoc = |file:///Users/hillsma/Projects/phpsa/PHP-Parser|;

    @doc{The base install location for the php-analysis project}
    public loc analysisLoc = |file:///Users/hillsma/Projects/phpsa/rascal/php-analysis/|;

    @doc{The memory limit for PHP when the parser is run}
    public str parserMemLimit = "1024M";

    @doc{The location of the AST2Rascal.php file, inside the PHP-Parser directories}
    public str astToRascal = "lib/Rascal/AST2Rascal.php";

    @doc{The working directory for when the parser runs}
    public loc parserWorkingDir = (parserLoc + astToRascal).parent;

    @doc{The base location for the corpus and any serialized files}
    public loc baseLoc = |home:///PHPAnalysis|;

    @doc{Where to put the binary representations of parsed systems}
    public loc parsedDir = baseLoc + "serialized/parsed";

    @doc{Where to put the binary representations of extracted statistics}
    public loc statsDir = baseLoc + "serialized/stats";

    @doc{Where the PHP sources for the corpus reside}
    public loc corpusRoot = baseLoc + "systems";

    @doc{Where to put extracted counts (e.g., SLOC)}
    public loc countsDir = baseLoc + "serialized/counts";

    @doc{This should only ever be true if we don't have source, we only have the extracted binaries for parsed systems}
    public bool useBinaries = false;

    @doc{Parser options, setting these to true can result in additional annotations on ASTs}
    public bool includePhpDocs = false;
    public bool includeLocationInfo = false;
    public bool resolveNamespaces = false;

    @doc{Debugging options}
    @logLevel {
        Log level 0 => no logging;
        Log level 1 => main logging;
        Log level 2 => debug logging;
    }
    public int logLevel = 2;
  
Make sure that `useBinaries` is false; this should only be true in cases where you
have the binaries built and no longer have the source.

To check to ensure that the directories are properly set up, you can run the following:

    import lang::php::util::Utils;
    checkConfiguration();

This will run several checks to make sure the directories can be found and that the parser
can parse a simple PHP expression. 

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
source of this bug and repair it. Note: if you have installed the WordPress
systems as well, this step will take a while, since there are more than 75
releases of WordPress included in the download.

Building Binaries with Includes Information
-------------------------------------------

At runtime, the actual program is the PHP page that is visited with all
includes resolved. We have developed an analysis that tries to resolve
these includes statically, and are currently working on improving this.
To use this information in the analysis, we first build binaries (as
above), but with includes resolved, where possible, to literal paths.
To do this, run the following code:

	import lang::php::stats::Unfriendly;
	writeIncludeBinaries();
	
This will generate a new binary, with includes resolved, for each
product in the corpus. Note that this is needed to recreate the feature
usage information, since that accounts for features included transitively
where possible.

Running the PHP Feature Usage Analysis Code
-------------------------------------------

The code to extract information on PHP feature usage is in folder
`lang/php/stats`, shown as package `lang.php.stats` in Eclipse. Most
of this code is in the Rascal module `lang::php::stats::Unfriendly`,
in file `Unfriendly.rsc`. This module contains code that measures the
use of "analysis unfriendly" features such as variable variables and
magic methods. This code also uses a number of functions defined
in `Stats.rsc` for extracting information on the uses of individual
features from PHP files.

To make our experiments easily reproducible, folder `lang/php/experiments`
contains a subdirectory for each set of experiments, categorized by the
paper in which they were collected, with a file containing calls that
build the figures and tables. For instance, module `lang::php::experiments::issta2013::ISSTA2013`
contains one function for each table and figure in the submitted
paper. Tracing through these functions shows the analysis steps
taken to yield the results we reported.

Comparing Multiple Releases
---------------------------

One project we are currently working on is to compare feature usage,
especially with dynamic features, across multiple versions of
WordPress. A current example, that simply shows how many "eval-like"
features (``eval`` and calls to ``create_function``) are present
in WordPress, is shown in module ``lang::php::experiments::wcre2014::WCRE2014``.
This can be run by calling ``printEvalLike("WordPress")``, which will
extract all the uses of ``eval`` and ``create_function`` and summarize
them by system. Note: one point of unsoundness here is that, since
``create_function`` is just a function, it could be invoked inside an
``eval``, using variable functions, or using dynamic invocation,
but those cases are not checked here (and, in extreme cases, cannot
be checked at all). 
