#!/bin/sh -f
xv_path="/opt/Xilinx/Vivado/2015.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 4acfdb88bad74a6dadb198e33b085589 -m64 --debug typical --relax --mt 8 --include "../../../../../../svn4/trunk/xci/crossbar_128m/axi_infrastructure_v1_1/hdl/verilog" -L xil_defaultlib -L axi_lite_ipif_v3_0 -L lib_cdc_v1_0 -L blk_mem_gen_v8_2 -L lib_bmg_v1_0 -L fifo_generator_v12_0 -L lib_fifo_v1_0 -L axi_ethernetlite_v3_0 -L generic_baseblocks_v2_1 -L axi_infrastructure_v1_1 -L axi_register_slice_v2_1 -L axi_data_fifo_v2_1 -L axi_crossbar_v2_1 -L unisims_ver -L unimacro_ver -L secureip --snapshot tb_top_behav xil_defaultlib.tb_top xil_defaultlib.glbl -log elaborate.log
