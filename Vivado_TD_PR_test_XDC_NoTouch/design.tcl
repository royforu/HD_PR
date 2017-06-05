###############################################################
###   Tcl Variables
###############################################################
#set tclParams [list <param1> <value> <param2> <value> ... <paramN> <value>]
set tclParams [list hd.visual 1 \
              ]

#Define location for "Tcl" directory. Defaults to "./Tcl"
set tclHome "./Tcl"
if {[file exists $tclHome]} {
   set tclDir $tclHome
} elseif {[file exists "./Tcl"]} {
   set tclDir  "./Tcl"
} else {
   error "ERROR: No valid location found for required Tcl scripts. Set \$tclDir in design.tcl to a valid location."
}

###############################################################
### vc707 board - Part Variables - Define Device, Package, Speedgrade 
###############################################################
set device       "xc7vx485t"
set package      "ffg1761"
set speed        "-2"
set part         $device$package$speed
set xboard       "vc707"
###############################################################
###  Setup Variables
###############################################################
####flow control
set run.topSynth   1
set run.oocSynth   1
set run.tdImpl     0
set run.oocImpl    1
set run.topImpl    0
set run.flatImpl   0

####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      1
set dcpLevel     1

####Output Directories
set synthDir  "./Synth"
set implDir   "./Implement"
set dcpDir    "./Checkpoint"

####Input Directories
set srcDir     "./Sources"
set rtlDir     "$srcDir/hdl"
set prjDir     "$srcDir/prj"
set xdcDir     "$srcDir/xdc"
set coreDir    "$srcDir/cores"
set netlistDir "$srcDir/netlist"

####Source required Tcl Procs
source $tclDir/design_utils.tcl
source $tclDir/synth_utils.tcl
source $tclDir/impl_utils.tcl
source $tclDir/hd_floorplan_utils.tcl

###############################################################
### Top Definition
###############################################################
set top "top"
add_module $top
set_attribute module $top    top_level     1
set_attribute module $top    vlog          [list [glob $rtlDir/$top/*.v]]

set_attribute module $top    synth         ${run.topSynth}

add_implementation $top
set_attribute impl $top      top           $top
set_attribute impl $top      implXDC       [list $xdcDir/${top}_$xboard.xdc] 
set_attribute impl $top      impl          ${run.topImpl}
set_attribute impl $top      hd.impl       1

####################################################################
### ### OOC Module Definition and OOC Implementation
####################################################################
set module1 "shift"

set module1_variant1 "shift_right"
add_module ${module1_variant1}
set_attribute module ${module1_variant1} moduleName   $module1
set_attribute module ${module1_variant1} vlog         [list [glob $rtlDir/${module1_variant1}/*.v]]
#set_attribute module ${module1_variant1} prj          $prjDir/${module1_variant1}.prj
set_attribute module ${module1_variant1} synth        ${run.oocSynth}

set instance "inst_shift"
add_ooc_implementation $instance
set_attribute ooc $instance    module       ${module1_variant1}
set_attribute ooc $instance    inst         $instance
set_attribute ooc $instance    hierInst     $instance
set_attribute ooc $instance    implXDC      [list $xdcDir/${instance}_phys.xdc         \
                                                  $xdcDir/${instance}_ooc_timing.xdc   \
                                                  $xdcDir/${instance}_ooc_budget.xdc   \
                                                  $xdcDir/${instance}_ooc_optimize.xdc \
                                            ]
set_attribute ooc $instance    impl         ${run.oocImpl} 
set_attribute ooc $instance    preservation routing 
####################################################################
### ### OOC Module Definition and OOC Implementation
####################################################################
set module2 "count"

set module2_variant1 "count_up"
add_module ${module2_variant1}
set_attribute module ${module2_variant1} moduleName   $module2
set_attribute module ${module2_variant1} vlog         [list $rtlDir/${module2_variant1}/${module2_variant1}.v]
set_attribute module ${module2_variant1} synth        ${run.oocSynth}

set instance "inst_count"
add_ooc_implementation $instance
set_attribute ooc $instance    module       ${module2_variant1}
set_attribute ooc $instance    inst         $instance
set_attribute ooc $instance    hierInst     $instance
set_attribute ooc $instance    implXDC      [list $xdcDir/${instance}_phys.xdc         \
                                                  $xdcDir/${instance}_ooc_timing.xdc   \
                                                  $xdcDir/${instance}_ooc_budget.xdc   \
                                                  $xdcDir/${instance}_ooc_optimize.xdc \
                                            ]
set_attribute ooc $instance    impl         ${run.oocImpl} 
set_attribute ooc $instance    preservation routing 
####################################################################
### Create TopDown implementation run 
####################################################################
add_implementation TopDown
set_attribute impl TopDown      top          $top
set_attribute impl TopDown      implXDC      [list $xdcDir/${top}_$xboard.xdc]
set_attribute impl TopDown      td.impl      1
set_attribute impl TopDown      cores        [list [get_attribute module $top cores]     \
                                                   [get_attribute module ${module1_variant1} cores] \
                                                   [get_attribute module ${module2_variant1} cores] \
                                             ] 
set_attribute impl TopDown      impl         ${run.tdImpl}
# Build the designs
source $tclDir/run.tcl

exit
