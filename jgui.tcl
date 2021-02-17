# sourced in by regrouper_gui.tcl

proc joinergui {} {
global inputfile xref debug outputfile
global xref
frame  .gui
frame  .gui.1
button .gui.1.0 -text input\
    -command {set inputfile [tk_getOpenFile -filetypes {{{abc files} {*.abc *.ABC}}} ]
              title_index $inputfile}
entry  .gui.1.1 -width 20 -textvariable inputfile
button .gui.1.2 -text output -command {set outputfile [tk_getSaveFile]}
entry  .gui.1.3 -width 20 -textvariable outputfile 
pack .gui
pack .gui.1
button .gui.1.4 -text regroup -command join
button .gui.1.5 -text save -command {Text_Dump $outputfile}
pack .gui.1.0 .gui.1.1  .gui.1.2 .gui.1.3 .gui.1.4 .gui.1.5 -side left


bind .gui.1.1 <Return> {$abctxtw delete 1.0 end
			title_index $inputfile}
wm title . "ReGrouper 2021-02-16"
}




proc arranger_gui {} {
global abctxtw
panedwindow .pane -sashwidth 8
frame .pane.tframe
set abctxtw .pane.tframe.t
text $abctxtw -wrap none \
     -yscrollcommand {.pane.tframe.ysbar set} \
     -xscrollcommand {.pane.tframe.xsbar set} 
 scrollbar .pane.tframe.ysbar -orient vertical -command {$abctxtw yview}
 scrollbar .pane.tframe.xsbar -orient horizontal -command {$abctxtw xview}
label .mesg  -width 60 -text regrouper
pack .mesg -side top -anchor w -fill x
pack .pane.tframe.ysbar -side right -fill y 
pack $abctxtw -fill both -expand 1
pack .pane.tframe.xsbar -side bottom -fill x 
$abctxtw configure -undo 1 
$abctxtw edit modified 0
focus 
frame .pane.toolbox
listbox .pane.toolbox.list -yscrollcommand {.pane.toolbox.tsbar set} -width 42 
scrollbar .pane.toolbox.tsbar -command {.pane.toolbox.list yview}
.pane add .pane.toolbox .pane.tframe
pack .pane.toolbox.list .pane.toolbox.tsbar -side left -fill y -expand y
 pack .pane -fill both -expand 1
}


proc title_index {abcfile} {
global fileseek
global nrepeats
set titlehandle [open $abcfile r]
set pat {[0-9]+}
set srch X
.pane.toolbox.list delete 0 end
set filepos 0
set i 0
while {[gets $titlehandle line] >=0 } {
  set lastfilepos $filepos
  set filepos [tell $titlehandle]
  switch -- $srch {
  X {if {[string compare -length 2 $line "X:"] == 0} {
     regexp $pat $line number
     set fileseek($number) $lastfilepos
     set srch T
     }
   }
  T {if {[string compare -length 2 $line "T:"] == 0} {
     set name [string range $line 2 end]
     set name [string trim $name]
     set listentry [format "%4s  %s" $number $name]
     incr i
     .pane.toolbox.list insert end $listentry
     set srch X
     }
   }
 }
}
close $titlehandle
bind .pane.toolbox.list <Button> {set selection [.pane.toolbox.list index @%x,%y]
   set item [.pane.toolbox.list get $selection]
   set xref [lindex $item 0]
   set title [lindex $item 1]
   set u _
   for {set i 2} {$i < [llength $item]} {incr i} {
      set title $title$u[lindex $item $i]
       }
   set title [string trimright $title]
   if {[string length $title] <1} {set title notitle}
# remove any apostrophe's
    set pat \'
    regsub -all $pat $title "" result
    #set outputfile $result
    set outputfile tmp.abc
    load_abc_file $inputfile $xref 
    }
if {$i == 1} {load_abc_file $abcfile $number}
}


proc load_abc_file {abcfile number} {
global abctxtw fileseek
global xref
set xref $number
 $abctxtw delete 1.0 end
 set edit_handle [open $abcfile r]
 if {[eof $edit_handle] !=1} {
 set loc  $fileseek($number)
 seek  $edit_handle $loc
 gets $edit_handle line
 $abctxtw insert end $line\n 
 }
 while {[string length $line] > 0} {
	gets $edit_handle line
	$abctxtw insert end $line\n 
        } 
 close $edit_handle
}


proc find_tune {refno inputhandle} {
# To handle files which may contain a compilation of tunes
# we call this function to  position the scanner on the X:
# reference number matching refno. If refno is "none" then
# we position the scanner on the first X: field command we find.
  while {[gets $inputhandle line] >= 0} {
    if {[string first "X:" $line] != 0} continue
      if {$refno == "none"} {
                             set tunestring ""
                             break}
      if {[string range $line 2 end] == $refno} {
                             set tunestring ""
                             break}
   }
   if {[eof $inputhandle]} {puts "end of file encountered" 
                            exit}

# copy tune to tunestring
  set tunestring $line\n
  while {[gets $inputhandle line] >0}  {
    set tunestring $tunestring$line\n
    }
  close $inputhandle
  return $tunestring
}






arranger_gui 
#load_abc_file outcl.abc



# MAIN program
set xref "none"
set debug 0
set preservegchord 0
joinergui

if {$tcl_platform(platform) == "unix"} {
  set abc2midi_path abc2midi
  set midiplayer_path timidity
  } else {
  set abc2midi_path abc2midi.exe
  set midiplayer_path "C:/Program Files/Windows Media Player/wmplayer.exe"
  }
#set midiplayer_path C:/timidity/timw32g.exe

set tempo 160
global replacements

proc join {} {
global inputfile xref 
global bodyvoice
global abctxtw
global nrepeats
global midi_descriptors
global tempo
global replacements


set inputhandle [open $inputfile r]
set tunestring [find_tune $xref $inputhandle]
process_tune $tunestring
$abctxtw delete 1.0 end
$abctxtw insert end $replacements
}


proc messages {msg} {
    global df
    if {[winfo exists .msg] != 0} {destroy .msg}
    toplevel .msg
    message .msg.out -text $msg -width 300
    pack .msg.out
}


proc Text_Dump {outputfile {start 1.0} {end end}} {
global abctxtw
  if {[file extension $outputfile] == ".abc"} {
    set outhandle [open $outputfile w] } else {
    set outhandle [open $outputfile.abc w]}


  foreach {key value index} [$abctxtw dump $start $end] {
    if {$key == "text"} {
      puts -nonewline $outhandle $value}
    }
  close $outhandle
  messages "File $outputfile was saved"
}




