# =========================
# VCS Makefile
# =========================

# ---- Tools ----
VCS      ?= vcs
SIMV     ?= simv
DVE      ?= dve

# ---- Project settings ----
# -top 需要的是「testbench module 名稱」，不是檔名
TOP_TB   ?= controller_tb
HEX      ?= tb1.hex

# include paths (for .svh)
INCDIRS  ?= ../include

# RTL list
RTL_SRCS = \
  controller_top.sv \
  ALU.sv \
  decoder.sv \
  regfile.sv \
  SRAM.sv \
  pc_counter.sv \
  pc_adder.sv \
  mux.sv \
  signal_controller.sv \
  ID_SENDER.sv \
  glb_addr_generator.sv

# Testbench file
TB_SRCS  = controller_tb.sv

# ---- VCS flags ----
VCS_FLAGS = -full64 -sverilog \
  $(foreach d,$(INCDIRS),+incdir+$(d)) \
  -debug_access+all \
  -timescale=1ns/1ps \
  -l compile.log

# Run flags
RUN_FLAGS = +HEX=$(HEX) -l run.log

# =========================
# Targets
# =========================
.PHONY: all build run sim wave clean help

all: sim

build: $(SIMV)

$(SIMV): $(TB_SRCS) $(RTL_SRCS)
	$(VCS) $(VCS_FLAGS) -top $(TOP_TB) $(TB_SRCS) $(RTL_SRCS) -o $(SIMV)

run: $(SIMV)
	./$(SIMV) $(RUN_FLAGS)

sim: build run

wave:
	$(DVE) -vpd vcdplus.vpd &

clean:
	rm -rf csrc $(SIMV) $(SIMV).daidir ucli.key \
	       *.vpd *.vcd *.log DVEfiles \
	       verdiLog novas* *.fsdb

help:
	@echo "make / make sim             : build + run"
	@echo "make build                  : compile only"
	@echo "make run HEX=xxx.hex        : run only (default HEX=tb1.hex)"
	@echo "make wave                   : open DVE (vpd)"
	@echo "make clean                  : remove generated files"
