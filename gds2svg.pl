#!/usr/bin/perl
# Convert GDS2 Streams to SVG
#
# Christoph Mueller 2013
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

use GDS2;
use SVG;

if (@ARGV == 0){
    print "gds2svg.pl <input.gds>\n";
    exit;
}

my $inputfile = $ARGV[0];
my $g = new GDS2(-fileName => $inputfile);
my $svg = (new SVG);

if (-f "gds2svg.css") {
    local $/=undef;
    open FILE, "gds2svg.css" or die "Couldn't open file: $!";
    $css = <FILE>;
    close FILE;

    $def = $svg->defs();
    $def->tag('style', 'type', 'text/css')->CDATA($css);
}

my $main = $svg->group(id=>"temp");
my $SVGsymbol = "";
my $SVGpolygon = "";
my $curel = "";
my @xy = ();
my $curname = "";
my $sname = "";
my $strname = "";
my $layer = -1;
my $string = "";
my $angle = 0;
my $strans = "";
my %usagecount = ();

while ($g -> readGds2Record) 
{
    
      if ($g -> isStrname){
	  $strname = $g->returnStrname;
	  $SVGsymbol = $main->tag('g', id => $strname);
	  # keep track how often we have been instanciated
	  if ($usagecount{$strname} < 1) {$usagecount{$strname} = 0};
      }

      if ($g -> isSname) { $sname = $g -> returnSname; }
      if ($g -> isLayer) { $layer = $g -> returnLayer; }
      if ($g -> isString) { $string = $g -> returnString; }
      if ($g -> isAngle) { 
	  my @arr = split(' ', $g->returnRecordAsString);
	  $angle = $arr[@arr-1];
      }
      if ($g -> isStrans) {
	   my @arr = split(' ', $g->returnRecordAsString);
	  $str = $arr[@arr-1];
	   if (substr($str, 0,1) eq '1') {
	       $strans = "scale(1, -1)";
	   }
      }
      
      if ($g -> isBoundary) { $curel = "BOUNDARY"; }
      if ($g -> isAref) { $curel = "AREF"; }
      if ($g -> isSref) { $curel = "SREF"; } 
      if ($g -> isText) { $curel = "TEXT"; }
      

      if ($g -> isXy) {
	  @xy = $g -> returnXyAsArray;
      }
    
      # Element closes, generate appropriate svg tag
      if ($g -> isEndel) {
	  
	  # Reference (AREF incomplete!)
	  if ($curel eq "SREF" || $curel eq "AREF"){
	      $SVGsymbol->group(transform =>"translate($xy[0], $xy[1]) rotate($angle) $strans")->use('-href'=>"#".$sname, 'class'=>"$sname");
	      $usagecount{$sname}++; 
	  }

	  # Boundary
	  if ($curel eq "BOUNDARY") {
	      $points = $xy[0].','.$xy[1];
	      for ($i = 2; $i < @xy; $i+=2){
		  $points = $points.' '.$xy[$i].','.$xy[$i+1];
	      }
	      $SVGsymbol->polygon(points=>$points,'class',"layer l$layer $strname");
	  }

	  if ($curel eq "TEXT") {
	      $SVGsymbol->group(transform =>"translate($xy[0], $xy[1]) rotate($angle) $strans")->text(class=>'layer l$layer text', style=>'font-size:144px;')->cdata($string);
	  }

	  # cleanup
	  $symbol = "";
	  $curel = "";
	  @xy = ();
	  $sname = "";
	  $layer = 0;
	  $string = "";
	  $angle = 0;
	  $strans = "";
      }
}

# instanciate not yet used cells (main cell)
while (($key, $value) = each(%usagecount)){
    if ($value == 0) {
	$svg->use(x=>0,y=>0,'-href'=>"#".$key, 'class', $key);
	}
}

# resolve uses, replace with instances
foreach my $use ($svg->getElements("use")){
    $parent = $use->getParentElement();
    $replacewithname = $use->getAttribute('class');
    $replacewith = $svg->getElementByID($replacewithname);   
    if ($replacewith != undef){
	$replacewith->setAttribute("id", undef);
	$replacewith->setAttribute("class", $replacewithname);
	$parent->insertBefore($replacewith, $use);
    }
    $parent->removeChild($use);
}

# drop initial instances
$par=$main->getParentElement();
$par->removeChild($main);

# return svg
print $svg->xmlify;

