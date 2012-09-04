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

We are currently using version 3.7 of Eclipse. Instructions for
installing Rascal are given on the Rascal download page.

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp]. The current version should work,
but we have also created tags corresponding to specific points
in time. The icse13 tag corresponds to our ICSE 2013 submission.

[phpp]: https://github.com/cwi-swat/PHP-Parser

You will also need to checkout this repository. Again, the icse13
tag corresponds to the software as it stood at the time of the
submission. While the current master should work, if you have
any problems, and want to replicate our experiments, you should use
the tagged versions.

Downloading the Corpus
----------------------

The corpus is rather large, so here we are providing just those
systems that we used in our experiments in our ICSE 2013 submission.
This is what we reference as the [most recent versions][mrvicse13] 
in the paper.

[mrvicse13]: http://homepages.cwi.nl/~hills/experiments/corpus-icse13.tgz

Coming Soon...
--------------

More information will be posted soon to provide the final setup
instructions.
