# regroup_gui.tcl
#!/bin/sh
# the next line restarts using wish \
exec wish8.6 "$0" "$@"
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

# usage
# wish8.6 regroup_gui 



source joiner.tcl
source jgui.tcl

