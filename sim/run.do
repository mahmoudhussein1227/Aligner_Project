# ==============================================================================
# QuestaSim / ModelSim UVM Run Script (run.do)
# ==============================================================================

# 1. Close previous simulation session if active
quit -sim

# 2. Create and map the work library
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work
vmap mtiUvm C:/questasim64_2021.1/uvm-1.2

# 3. Compilation
# -sv: Enables SystemVerilog features
# +acc: Enables full visibility for waveform debugging
# -timescale: Sets default timescale
# +incdir+: Include paths for header/interface files
vlog -sv -timescale "1ns/1ps" +acc \
    +incdir+../RTL \
    +incdir+../testbench \
    ../RTL/design.sv \
    ../testbench/testbench.sv



# 4. Elaboration & Simulation
# Set UVM test name and verbosity as needed:
# +UVM_VERBOSITY=UVM_LOW | UVM_MEDIUM | UVM_HIGH | UVM_FULL | UVM_DEBUG
vsim -voptargs="+acc" -assertdebug -sv_seed random work.testbench -suppress ILLEGALNAME \
    +UVM_TESTNAME=cfs_algn_illegal_rx_tr_test \
    +uvm_set_verbosity=uvm_test_top*,_ALL_,UVM_NONE,time,0 \
    +uvm_set_verbosity=uvm_test_top.env.apb_agent.monitor,APB_ITEM_START,UVM_LOW,time,0 \
    +uvm_set_verbosity=uvm_test_top.env.md_agent_master.monitor,MD_ITEM_END,UVM_LOW,time,0 \
    +uvm_set_verbosity=uvm_test_top.env.md_agent_master.driver,MD_ITEM_START,UVM_LOW,time,0 \
    +uvm_set_verbosity=uvm_test_top.env.md_agent_slave.monitor,MD_ITEM_END,UVM_LOW,time,0 \
    +uvm_set_verbosity=uvm_test_top.env.model,INC_DROP_CNT,UVM_LOW,time,0 \
    +uvm_set_verbosity=*,CONFIG_REGS,UVM_LOW,time,0 \
    +UVM_MAX_QUIT_COUNT=1 \
    +uvm_set_config_int=uvm_test_top.env.md_agent_master.monitor,recording_detail,400 -uvmcontrol=all \
    +uvm_set_action=*,ILLEGALNAME,UVM_WARNING,UVM_NO_ACTION \
    +uvm_set_action=*,ILLEGALNAME,UVM_INFO,UVM_NO_ACTION


# 5. Add Waveforms

# Add APB interface signals to waveform
# dut signals
add wave -position insertpoint sim:/testbench/dut/core/regs/status_cnt_drop
add wave -position insertpoint  \
sim:/testbench/dut/core/regs/irq_rx_fifo_empty \
sim:/testbench/dut/core/regs/irq_rx_fifo_full \
sim:/testbench/dut/core/regs/irq_tx_fifo_empty \
sim:/testbench/dut/core/regs/irq_tx_fifo_full \
sim:/testbench/dut/core/regs/irq_max_drop

add wave -position insertpoint sim:/testbench/apb_if/*
add wave -position insertpoint sim:/testbench/md_rx_if/*
add wave -position insertpoint sim:/testbench/md_tx_if/*
add wave -position insertpoint sim:/testbench/algn_if/*

# Add APB/MD interface assertions to waveform
# add wave -position insertpoint sim:/testbench/apb_if/KNOWN_PADDR
# add wave -position insertpoint sim:/testbench/apb_if/KNOWN_PWRITE
# add wave -position insertpoint sim:/testbench/apb_if/KNOWN_PWDATA
# add wave -position insertpoint sim:/testbench/apb_if/PENABLE_IS_LOW
# add wave -position insertpoint sim:/testbench/apb_if/ENTER_ACCESS_PHASE
# add wave -position insertpoint sim:/testbench/apb_if/STABLE_PWDATA
# add wave -position insertpoint sim:/testbench/apb_if/VALID_PSLVERR

# add wave -position insertpoint sim:/testbench/md_tx_if/VALID_MD_HIGH_A
# add wave -position insertpoint sim:/testbench/md_rx_if/VALID_MD_HIGH_A
# add wave -position insertpoint sim:/testbench/md_tx_if/VALID_MD_DATA_A
# add wave -position insertpoint sim:/testbench/md_rx_if/VALID_MD_DATA_A
# add wave -position insertpoint sim:/testbench/md_tx_if/STABLE_MD_DATA_A
# add wave -position insertpoint sim:/testbench/md_rx_if/STABLE_MD_DATA_A
# add wave -position insertpoint sim:/testbench/md_tx_if/VALID_MD_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_rx_if/VALID_MD_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_tx_if/STABLE_MD_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_rx_if/STABLE_MD_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_tx_if/VALID_MD_SIZE_A
# add wave -position insertpoint sim:/testbench/md_rx_if/VALID_MD_SIZE_A
# add wave -position insertpoint sim:/testbench/md_tx_if/STABLE_MD_SIZE_A
# add wave -position insertpoint sim:/testbench/md_rx_if/STABLE_MD_SIZE_A
# add wave -position insertpoint sim:/testbench/md_tx_if/NOT_ZERO_SIZE_A
# add wave -position insertpoint sim:/testbench/md_rx_if/NOT_ZERO_SIZE_A
# add wave -position insertpoint sim:/testbench/md_tx_if/LEGAL_SIZE_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_rx_if/LEGAL_SIZE_OFFSET_A
# add wave -position insertpoint sim:/testbench/md_tx_if/VALID_ERR_A
# add wave -position insertpoint sim:/testbench/md_rx_if/HIGH_ERR_A




# Open Assertions Debug View
view assertions
# Alternatively for recursive wave logging:
# log -r /*
# add wave -r /*

# 6. Run simulation
run -all

#==============================================================================
