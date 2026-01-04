root_dir := $(PWD)
src_dir := ./src
syn_dir := ./syn
inc_dir := ./include
sim_dir := ./sim
vip_dir := $(PWD)/vip
bld_dir := ./build

FSDB_DEF :=
ifeq ($(FSDB),1)
	FSDB_DEF := +FSDB
else ifeq ($(FSDB),2)
	FSDB_DEF := +FSDB_ALL
endif

prog ?= 0

$(bld_dir):
	mkdir -p $(bld_dir)

$(syn_dir):
	mkdir -p $(syn_dir)


INCDIRS := \
  $(root_dir)/$(inc_dir) \
\

# RTL sources (expand wildcards at make-time)
RTL_SRCS := \
  $(root_dir)/$(src_dir)/ASIC.sv \
  $(root_dir)/$(src_dir)/top.sv \
  $(root_dir)/$(sim_dir)/DRAM.sv \
  $(wildcard $(root_dir)/$(src_dir)/controller/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/DMA/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PPU/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/GLB/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/GIN/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/GON/*.sv)

TB_SRCS := $(root_dir)/$(sim_dir)/Testbench.sv

vcs: | $(bld_dir)
	@if [ ! -d "$(sim_dir)/prog$(prog)" ]; then \
			echo "ERROR:Can't find the path $(sim_dir)/prog$(prog)"; \
			exit 1; \
	fi
	g++ -std=c++17 ../testbench/tb_pe_array.cpp -o ./../testbench/tb_pe_array.exe
	LD_LIBRARY_PATH=/usr/lib64 ./../testbench/tb_pe_array.exe
	python3 $(sim_dir)/assembler.py $(sim_dir)/prog$(prog)/GEMM_assembly.txt
	cd $(bld_dir); \
	vcs -full64 -R -sverilog \
		$(foreach d,$(INCDIRS),+incdir+$(d)) \
		$(TB_SRCS) $(RTL_SRCS) \
		-debug_access+all -debug_region+cell +memcbk \
		+define+prog$(prog)$(FSDB_DEF) \
		+prog_path=$(root_dir)/$(sim_dir)/prog$(prog) \
		+notimingcheck

# Utilities
nWave: | $(bld_dir)
	cd $(bld_dir); \
	nWave top.fsdb &

superlint: | $(bld_dir)
	cd $(bld_dir); \
	jg -superlint ../script/superlint.tcl &

dv: | $(bld_dir) $(syn_dir)
	cp script/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	dc_shell -gui -no_home_init

synthesize: | $(bld_dir) $(syn_dir)
	cp script/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	dc_shell -no_home_init -f ../script/synthesis.tcl

tar:
	cd ..; \
	tar cvf Project.tar Project
	
.PHONY: clean

clean:
	rm -rf $(bld_dir); \