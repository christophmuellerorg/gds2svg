Simple conversion from GDSII streams to SVG
====
Supported elements
----
* BOUNDARY
* SREF (AREF is interprated as SREF, no array yet)
* TEXT

Features
----
* CSS formatting
* Layers available as class

Dependencies
----
* [GDS2](http://search.cpan.org/~schumack/GDS2-3.00/lib/GDS2.pm) by Ken Schumack
* [SVG](http://search.cpan.org/~szabgab/SVG-2.53/) by Gábor Szabó

Usage
----
./gds2svg.pl _gdsfile_ > _gdsfile.svg_

Todo
----
* use a parser generator instead of my preliminary low quality hack
* add support for layerwise ordering instead of the current hierarchical approach to draw the layers in correct order - SVG, y u no z-index...