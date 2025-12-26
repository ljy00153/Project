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
  $(root_dir)/$(src_dir)/DRAM.sv \
  $(wildcard $(root_dir)/$(src_dir)/controller/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/DMA/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PPU/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/GLB/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/GIN/*.sv) \
  $(wildcard $(root_dir)/$(src_dir)/PE_array/GON/*.sv)

TB_SRCS := $(root_dir)/$(sim_dir)/Testbench.sv

vcs: | $(bld_dir)
	python3 $(sim_dir)/prog0/assembler.py $(sim_dir)/prog0/GEMM_assembly.txt
	cd $(bld_dir); \
	vcs -full64 -R -sverilog \
		$(foreach d,$(INCDIRS),+incdir+$(d)) \
		$(TB_SRCS) $(RTL_SRCS) \
		-debug_access+all -debug_region+cell +memcbk \
		+define+prog0$(FSDB_DEF) \
		+prog_path=$(root_dir)/$(sim_dir)/prog0 \
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

# Check file structure
BLUE=\033[1;34m
RED=\033[1;31m
NORMAL=\033[0m

check: clean
	@if [ -f StudentID ]; then \
		STUDENTID=$$(grep -v '^$$' StudentID); \
		if [ -z "$$STUDENTID" ]; then \
			echo -e "$(RED)Student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID_LEN=$$(expr length $$STUDENTID); \
			if [ $$ID_LEN -eq 9 ]; then \
				if [[ $$STUDENTID =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	else \
		echo -e "$(RED)StudentID file is not found$(NORMAL)"; \
		exit 1; \
	fi; \
	if [ -f StudentID2 ]; then \
		STUDENTID2=$$(grep -v '^$$' StudentID2); \
		if [ -z "$$STUDENTID2" ]; then \
			echo -e "$(RED)Second student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID2_LEN=$$(expr length $$STUDENTID2); \
			if [ $$ID2_LEN -eq 9 ]; then \
				if [[ $$STUDENTID2 =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Second student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Second student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Second student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	fi; \
	if [ $$(ls -1 *.docx 2>/dev/null | wc -l) -eq 0 ]; then \
		echo -e "$(RED)Report file is not found$(NORMAL)"; \
		exit 1; \
	elif [ $$(ls -1 *.docx 2>/dev/null | wc -l) -gt 1 ]; then \
		echo -e "$(RED)More than one docx file is found, please delete redundant file(s)$(NORMAL)"; \
		exit 1; \
	elif [ ! -f $${STUDENTID}.docx ]; then \
		echo -e "$(RED)Report file name should be $$STUDENTID.docx$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Report file name pass$(NORMAL)"; \
	fi; \
	if [ $$(basename $(PWD)) != $$STUDENTID ]; then \
		echo -e "$(RED)Main folder name should be \"$$STUDENTID\"$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Main folder name pass$(NORMAL)"; \
	fi

tar:
	cd ..; \
	tar cvf Project.tar Project

.PHONY: clean

clean:
	rm -rf $(bld_dir); \