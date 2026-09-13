#!/usr/bin/tclsh

set fbin [open bin2v.bin r]
fconfigure $fbin -translation binary
set f_out1 [open bin2v-1.mem w]
set f_out2 [open bin2v-2.mem w]
set f_out3 [open bin2v-3.mem w]
set f_out4 [open bin2v-4.mem w]

while (1) {
    set line [read  $fbin 1]

    if {[eof $fbin]} {
        break
    }

    binary scan $line H* value
    puts $f_out1 $value 


    set line [read  $fbin 1]

    if {[eof $fbin]} {
        break
    }

    binary scan $line H* value
    puts $f_out2 $value 

    set line [read  $fbin 1]

    if {[eof $fbin]} {
        break
    }

    binary scan $line H* value
    puts $f_out3 $value 

    set line [read  $fbin 1]

    if {[eof $fbin]} {
        break
    }

    binary scan $line H* value
    puts $f_out4 $value 


}

close $f_out1
close $f_out2
close $f_out3
close $f_out4
close $fbin

exit 0

