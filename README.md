## Regrouper

### Introduction

The program fixes the grouping of notes in an abc music notation file so that
they align with the beats. This makes the music score easier to read. For
example, a line of music

    
    
    [V:1] E G B e d e !uppermordent!c B ce3 |
    

will be converted to

    
    
    [V:1]EGB ede !uppermordent!cBc e3 |
    

There are two instances of this program -- regroup.tcl and regroup_gui.tcl.

**regroup.tcl** runs without a user interface and is designed to run in a
batch file. To run it from a command window you would enter:

    
    
    tclsh regroup.tcl my_input_file.abc > my_output_file.abc.
    

where my_input_file.abc is the name of your input abc file, and
my_output_file.abc is the name of the output abc file with the notes
regrouped. You may prefix either files with the name of the folder where they
are contained or to be created.

**regroup_gui.tcl** runs with a user interface. To start it,

    
    
    wish8.6 regroup_gui.tcl
    

or alternatively just enter

    
    
    regroup_gui.tcl
    

assuming that the file can be executed.

Once the user interface appears, click the input button and browse to the
input abc file. A list of all tunes in that file should appear in the left
frame. When you select one of the tunes, the contents of that tune should
appear in the right frame. Click the regroup button, to regroup the notes in
that selection. The contents of the right text frame should be updated with
the notes regrouped. The contents of this text window can be saved to your
designated output file using the save button. I do not recommend overwriting
the input abc file unless you have a backup.  

### Requirements

The program requires the tcl/tk 8.6 interpreter in order to run. Tcl/tk is
usually available with Posix (Linux) systems and can installed for free on
Windows operating systems from
<https://www.activestate.com/products/tcl/downloads/>. There are no other
dependencies at this time.

### Test File

I have include wtc1p09.abc in this repository.  

### Method

The program recognizes the following meters: 4/4, 2/4, 3/4, 3/8, 6/8, 2/2/
6/4, 9/8, 3/2, 12/8, 12/16, 6/16, 4/2, and 24/16, and selects the appropriate
beat size. All white spaces are removed from a text line in the body. The
program scans through the text line, adding up the note (rest) lengths, and
inserts a space at the end of each beat.

* * *

This page was created on February 17 2021.

