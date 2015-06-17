# gitlogviz

Use graphviz to visualize your git commit log!

First, go to [graphviz.org](http://graphviz.org/) and install the software. It's free!

Second, run this script from the top level of a git repository, like so:

    gitlogviz.rb | dot -Tpdf -o git-log.pdf

Third, open `git-log.pdf` in a PDF viewer to impress your friends and confound your enemies!

## Sample Output

![Sample Image](https://github.com/benzado/gitlogviz/raw/master/sample.png)

## Copyright Notice

Copyright 2012, 2013, 2015 Benjamin Ragheb

This file is part of GitLogViz.

GitLogViz is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GitLogViz is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GitLogViz.  If not, see <http://www.gnu.org/licenses/>.
