SRC1 = $(wildcard ./src/PE_array/PE.sv)
SRC2 = $(wildcard ./src/PE_array/PE_array.sv)
SRC3 = $(wildcard ./src/PPU/PPU.sv)

ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS += --cc --exe
VERILATOR_FLAGS += -I./include
CXXFLAGS += -g

# Optimize
# VERILATOR_FLAGS += -x-assign fast

# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
# VERILATOR_FLAGS += -Wall -Wno-lint

# Automatically build the Verilated model
VERILATOR_FLAGS += --build

# Make waveforms
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --trace-max-array 1024

# Run Verilator in debug mode
VERILATOR_FLAGS += --debug

LOG_FILE ?= logs/terminal_text.log
POST_PROCESS :=

ifneq ($(PE),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PE=$(PE)"
    LOG_FILE = logs/terminal_text_pe$(PE).log
    VERILATOR_INPUT = $(SRC1) ./testbench/tb_PE.cpp
    TARGET=VPE
    POST_PROCESS = @chmod 666 ./testbench/tb_PE.cpp
else
ifneq ($(ARRAY),)
    VERILATOR_FLAGS += -CFLAGS "-DTBA=$(ARRAY)"
    LOG_FILE = logs/terminal_text_array$(ARRAY).log
    VERILATOR_INPUT = $(SRC2) ./testbench/tb_array.cpp
    TARGET=VPE_array
    POST_PROCESS = @chmod 666 ./testbench/tb_array.cpp
else
ifneq ($(PPU),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PPU=$(PPU)"
    VERILATOR_INPUT = $(SRC3) ./testbench/tb_PPU.cpp
    TARGET=VPPU
    LOG_FILE = logs/terminal_text_ppu$(PPU).log
    POST_PROCESS = @chmod 666 ./testbench/tb_PPU.cpp
endif
endif
endif

######################################################################
default: all

.PHONY: all pe_all array_all ppu_all

pe_all: pe0 pe1 pe2 pe3
array_all: array0 array1 array2 array3 array4 array5
ppu_all: ppu0 ppu1 ppu2

all: pe_all array_all ppu_all

run:
	@echo
	@echo "-- Verilator Start"

	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	obj_dir/$(TARGET) +trace > $(LOG_FILE)

	@echo
	@echo "-- DONE --------------------"
	@echo "To see waveforms, open PE_wave.vcd in a waveform viewer"
	@echo

	$(POST_PROCESS)

######################################################################
# Specific Testbench Targets
# Pass TB_select as a parameter to the simulation executable
.PHONY: array% pe%

pe%:
	make run PE=$*

array%:
	make run ARRAY=$*

ppu%:
	make run PPU=$*



######################################################################
# Other targets

format:
	clang-format -i testbench/*.cpp testbench/*.h
	@chmod 666 ./testbench/*.cpp
	@chmod 666 ./testbench/*.h
show-config:
	$(VERILATOR) -V

dist:
	make clean
	python release.py
	cd release && zip -r ../aoc2025-lab3.zip .

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.log *.dmp *.vpd wave/*.vcd wave/*.fsdb coverage.dat core *.zip release
