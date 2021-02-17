# regroup.tcl
#!/bin/sh
# the next line restarts using wish \
exec tclsh "$0" "$@"
#


# The functions in this file scan a tune in a
# abc file and produce a new tune with the 
# with the notes properly grouped
#
# V:1
#|: c B |A2 F E F A G F|
# is replaced with
# V:1
# |: cB | A2F2 FAGF |

# usuage
# tclsh regroup.tcl  myfile.abc > output.abc

cd [pwd]
source joiner.tcl



if {$argc > 0} {
  set inputfile [lindex $argv 0]
  set inputhandle [open $inputfile r]
  #set inputhandle [open haydn.abc r]
  set tunestring [load_tune $inputhandle]
  process_tune $tunestring
  puts $replacements
  } else {
  puts "tclsh regroup.tcl inputfile"
  }
