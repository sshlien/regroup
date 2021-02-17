# joiner.tcl
#
# sourced in by regroup.tcl and regroup_gui.tcl


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
# tclsh joiner.tcl  myfile.abc > output.abc


array set meter2beat { 4/4 384
                      2/4 384
                      3/4 384
                      3/8 192
                      6/8 576
                      2/2 384
                      6/4 384
                      9/8 576
                      3/2 768
                     12/8 576
                     12/16 288
                      6/16 288
                      4/2  768
                     24/16 576

    }          

set debug 0

# setup_meter {line}
# Handles M: command
proc setup_meter {line} {
  global default_gchord
  global gchordstring
  global barunits
  global gcstringlist
  global noteunits
  global beatunits
  global meter2beat
  if {[string first "C|" $line] >= 0} {
    set m1 2
    set m2 2} elseif {
      [string first "C" $line] >= 0} {
    set m1 4
    set m2 4} else {
    set r [scan $line "M:%d/%d" m1 m2]}
  set barunits [expr 4*384 * $m1 /$m2]
  set meter $m1/$m2
  if {[info exist default_gchord($meter)]} {
    set gchordstring $default_gchord($meter)
    set gcstringlist [scangchordstring $gchordstring]
    }
  if {[info exist meter2beat($meter)]} {
     set beatunits $meter2beat($meter)
     }
  if {[info exists noteunits]} return
  if {[expr double($m1)/$m2] < 0.75} {
    setup_unitlength L:1/16} else {
    setup_unitlength L:1/8}
  }

#Handles L: command
proc setup_unitlength {line} {
  global noteunits
  set r [scan $line "L:%d/%d" m1 m2]
  set noteunits [expr 384 *4* $m1 /$m2]
  #puts "setup_unitlength $m1 $m2 $noteunits"
  }

#end tempo.tcl




       
proc process_barline {token} {
  global bar_accumulator
  global spaceafter
  global noteunits
  global beatunits
  #puts "barline--"
  set bar_accumulator 0
  set spaceafter $beatunits
  }






proc appendtext {line} {
global replacements
set replacements $replacements$line\n
}


proc process_line {line} {
# processes the notes in a single line of the body in sequence.
# We only care about the duration of the note and position of
# the guitar chord indications. Thus we need to recognize
# barlines eg. | || :| |: |[1 |[2
# chords eg. [CEG]
# triplets eg. (3CDD
# gchords (anything enclosed by double quotes)
# notes eg. A3/2 A/ A3 A
# Each of these entities are handled by different functions.
#set barpat {\||:\|\[\d|:\||\|:|\|\[\d|\||::}
set barpat {\|\||\|[0-9]?|:\|\[\d|:\|[0-9]?|:\||\|:|\|\[\d|\||::}
set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]\'*|z)(/?[0-9]*|[0-9]*/*[0-9]*)(-?)}
set gchordpat {\"[^\"]+\"}
set curlypat {\{[^\}]*\}}
set chordpat {(\[[^\]\[]*\])(/?[0-9]*|[0-9]*/*[0-9]*)}
set instructpat {![^!]*!}
set tupletpat  {\(\d(\:\d)*}
set sectpat {\[[0-9]+}
global debug

global bar_accumulator
global spaceafter
global preservegchord
global noteunits
global beatunits

set line [string map {" " ""} $line]
#puts $line
#puts "process_line  $line"
# scan through the whole line (including gchords)
set i 0
set spaceafter $beatunits
while {$i < [string length $line]} {
# search for bar lines
 set success [regexp -indices -start $i $barpat $line location]
 if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {
     process_barline [string range $line $loc1 $loc2]
     set i [expr $loc2+1]
     #puts "barline at $loc1"
     continue}
   }

# for repeat sections
 set success [regexp -indices -start $i $sectpat $line location]
 if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {
     set sect [string range $line $loc1 $loc2]
     set i [expr $loc2+1]
     continue
     }
  }



 set success [regexp -indices -start $i $gchordpat $line location]
# search for guitar chords
  if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {
     set i [expr $loc2+1]
     continue}
   }

 set success [regexp -indices -start $i $curlypat $line location]
# search for grace note sequences
  if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
#  ignore grace notes in curly brackets
   if {$loc1 == $i} {
     set i [expr $loc2+1]
     continue}
   }


 set success [regexp -indices -start $i $tupletpat $line location]
# search for triplet indication
  if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {process_tuplet $location $line
     set i [expr $loc2+1]
     continue
     }
   }

 set success [regexp -indices -start $i $instructpat $line location]
# search for embedded instructions like !fff!
  if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {
#    skip !fff! and similar instructions embedded in body
     set i [expr $loc2+1]
     continue}
   }

 set success [regexp -indices -start $i $notepat $line location]
 #puts "success = $success for $line at $location"
# search for notes
 if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {process_note [string range $line $loc1 $loc2]
     set i [expr $loc2+1]
     if {$bar_accumulator >= $spaceafter} {
         set c [string index $line $i]
         set line [string replace $line $i $i " $c"]
         set spaceafter [expr (1 + $bar_accumulator/$beatunits) * $beatunits]
         if {$debug} {puts "insert space  $line bar_accumulator $bar_accumulator spaceafter $spaceafter"}
         }
     continue}
   }

 set success [regexp -indices -start $i $chordpat $line location]
# search for chords
  if {$success} {
   set loc1  [lindex $location 0]
   set loc2  [lindex $location 1]
   if {$loc1 == $i} {process_chord [string range $line $loc1 $loc2]
     set i [expr $loc2+1]
     if {$bar_accumulator >= $spaceafter} {
         set c [string index $line $i]
         set line [string replace $line $i $i " $c"]
         set spaceafter [expr (1 + $bar_accumulator/$beatunits) * $beatunits]
         if {$debug} {puts "insert space  $line bar_accumulator $bar_accumulator spaceafter $spaceafter"}
        }
     continue}
     }

 incr i
 }
return $line
}




# set flag to adjust the duration of the next three notes
proc process_tuplet {location line} {
global triplet_running
global tuplenotes
global nequiv
global tupletscalefactor
set tuplet [string range $line [lindex $location 0] [lindex $location 1]]
set n [scan $tuplet "(%d:%d:%d" n1 n2 n3]
#puts "tuplet = $tuplet n = $n"
set triplet_running 1
if {$n == 1} {
  set tuplesize $n1
  set tuplenotes $tuplesize
  switch $n1 {
    2 {set nequiv 3}
    3 {set nequiv 2}
    4 {set nequiv 3}
    6 {set nequiv 2}
    }
} elseif {$n == 2} {
   set tuplesize $n1
   set tuplenotes $tuplesize
   set nequiv $n2
} elseif {$n == 3} {
   set tuplesize $n1
   set nequiv $n2
   set tuplenotes $n3
}
set tupletscalefactor [expr $nequiv/double($tuplesize)]
}



 

# determine the duration of the note. We ignore broken
# notes (eg A > C) because the two notes usually complete
# a beat. We also do not need to pay attention to tied
# notes.
proc process_note {token} {
  global bar_accumulator
  global noteunits
  global tupletscalefactor
  global triplet_running
  global tuplenotes
  global nequiv
  global debug
  if {[string first "\[V:" $token] == 0} return
  set num 1
  set den 1
  set nslash 0
  set tokenlist [split $token {}]
  set l [llength $tokenlist]  
  if {$debug} {puts "process_note $token = $tokenlist ... length = $l"}
  for {set i 1} {$i < $l} {incr i} {
    set tok [lindex $tokenlist $i]
    set tok1 [lindex $tokenlist [expr $i +1]]
    if {[string is digit $tok]} {
        if {$nslash < 1} {
          set num $tok
          if {[string is digit -strict $tok1]} {
            set num [expr $tok1*10 + $tok]
            incr i
            }
         } else { #past slash
            set den $tok
            if {[string is digit -strict $tok1 ]} {
               set den [expr $tok1*10 + $tok]
               incr i
               }
         }
       }
    if {$tok == "/"} {
       incr nslash
       }
    }
    if {$nslash > 0 && $den == 1} {set den [expr pow(2,$nslash)]}
    if {$debug} {puts "num = $num den = $den nslash = $nslash"}


  set increment [expr $noteunits * $num / $den]
     
     
  if {$triplet_running} {
     set increment [expr round($tupletscalefactor * $increment)]
     incr triplet_running
     if {$triplet_running > $tuplenotes} {set triplet_running 0}
     }
  incr bar_accumulator [expr round($increment)]
  if {$debug} {puts "process_note $token increment $increment bar_accumulator $bar_accumulator"}
  return
 }


# We hope all the notes in the chord are of equal.
# We get the time value of the chord from the time
# value of the first note in the chord.
proc process_chord {token} {
  #puts "process_chord $token"
  process_note $token
  }


# This is the function which processes the tune.
# Assume only one tune per file.
proc process_tune {tunestring} {
 global replacements
 global bar_accumulator
 global triplet_running
 global npart
 global body
 global debug
 global nvoices
 global abctxtw

 set npart 0
 set nvoices 0
 set fieldpat {^X:|^T:|^C:|^O:|^A:|^Q:|^Z:|^N:|^H:|^S:|^R:|^P:}
 set triplet_running 0
 set replacements ""
 set body 0
 foreach line [split $tunestring \n]  {
   if {$debug > 0} {puts ">>$line"}
   if {[string length $line] < 1} break
   if {
   [string index $line 0] == "%"} {
      appendtext $line
      continue
      } elseif {
    [regexp $fieldpat $line] } {
      appendtext $line
      } elseif {
   [string first "K:" $line] == 0} {
       appendtext $line
       set kfield [string range $line 2 end]
       set bar_accumulator 0
      } elseif {
   [string first "V:" $line] == 0} {
       appendtext $line
      } elseif {
   [string first "M:" $line] == 0} {
       appendtext $line
       setup_meter $line
      } elseif {
   [string first "L:" $line] == 0} {
       appendtext $line
       setup_unitlength $line
      } else  {
       set line [process_line $line]
       #puts $line
       appendtext $line
   }
 }  
}





proc load_tune {inputhandle} {
# copy tune to tunestring
  set tunestring ""
  while {[gets $inputhandle line] >0}  {
    set tunestring $tunestring$line\n
    }
  close $inputhandle
  return $tunestring
}


