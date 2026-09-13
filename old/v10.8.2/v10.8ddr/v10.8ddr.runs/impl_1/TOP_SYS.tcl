proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  debug::add_scope template.lib 1
  create_project -in_memory -part xc7a100tcsg324-1
  set_property board_part digilentinc.com:nexys4_ddr:part0:1.1 [current_project]
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.cache/wt [current_project]
  set_property parent.project_path /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.xpr [current_project]
  set_property ip_repo_paths /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.cache/ip [current_project]
  set_property ip_output_repo /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.cache/ip [current_project]
  add_files -quiet /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/synth_1/TOP_SYS.dcp
  add_files -quiet /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/axi_ethernetlite_0_synth_1/axi_ethernetlite_0.dcp
  set_property netlist_only true [get_files /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/axi_ethernetlite_0_synth_1/axi_ethernetlite_0.dcp]
  add_files -quiet /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/ddr_axi_synth_1/ddr_axi.dcp
  set_property netlist_only true [get_files /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/ddr_axi_synth_1/ddr_axi.dcp]
  add_files -quiet /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/axi_crossbar_0_synth_1/axi_crossbar_0.dcp
  set_property netlist_only true [get_files /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.runs/axi_crossbar_0_synth_1/axi_crossbar_0.dcp]
  read_xdc -mode out_of_context -ref axi_ethernetlite_0 /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_ooc.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_ooc.xdc]
  read_xdc -prop_thru_buffers -ref axi_ethernetlite_0 /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_board.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_board.xdc]
  read_xdc -ref axi_ethernetlite_0 /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0.xdc]
  read_xdc -mode out_of_context -ref ddr_axi /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.srcs/sources_1/ip/ddr_axi/ddr_axi/user_design/constraints/ddr_axi_ooc.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.srcs/sources_1/ip/ddr_axi/ddr_axi/user_design/constraints/ddr_axi_ooc.xdc]
  read_xdc -ref ddr_axi /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.srcs/sources_1/ip/ddr_axi/ddr_axi/user_design/constraints/ddr_axi.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/vault.memo/v10.8ddr/v10.8ddr/v10.8ddr.srcs/sources_1/ip/ddr_axi/ddr_axi/user_design/constraints/ddr_axi.xdc]
  read_xdc -mode out_of_context -ref axi_crossbar_0 -cells inst /home/leo/cpu/svn4/trunk/xci/crossbar_128m/axi_crossbar_0_ooc.xdc
  set_property processing_order EARLY [get_files /home/leo/cpu/svn4/trunk/xci/crossbar_128m/axi_crossbar_0_ooc.xdc]
  read_xdc /home/leo/cpu/vault.memo/v10.8ddr/TOP_SYS.xdc
  read_xdc -ref axi_ethernetlite_0 /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_clocks.xdc
  set_property processing_order LATE [get_files /home/leo/cpu/svn4/trunk/xci/etherlite/axi_ethernetlite_0_clocks.xdc]
  link_design -top TOP_SYS -part xc7a100tcsg324-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force TOP_SYS_opt.dcp
  catch {report_drc -file TOP_SYS_drc_opted.rpt}
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file TOP_SYS.hwdef}
  place_design 
  write_checkpoint -force TOP_SYS_placed.dcp
  catch { report_io -file TOP_SYS_io_placed.rpt }
  catch { report_utilization -file TOP_SYS_utilization_placed.rpt -pb TOP_SYS_utilization_placed.pb }
  catch { report_control_sets -verbose -file TOP_SYS_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force TOP_SYS_routed.dcp
  catch { report_drc -file TOP_SYS_drc_routed.rpt -pb TOP_SYS_drc_routed.pb }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file TOP_SYS_timing_summary_routed.rpt -rpx TOP_SYS_timing_summary_routed.rpx }
  catch { report_power -file TOP_SYS_power_routed.rpt -pb TOP_SYS_power_summary_routed.pb }
  catch { report_route_status -file TOP_SYS_route_status.rpt -pb TOP_SYS_route_status.pb }
  catch { report_clock_utilization -file TOP_SYS_clock_utilization_routed.rpt }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  write_bitstream -force TOP_SYS.bit 
  catch { write_sysdef -hwdef TOP_SYS.hwdef -bitfile TOP_SYS.bit -meminfo TOP_SYS.mmi -ltxfile debug_nets.ltx -file TOP_SYS.sysdef }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

