# === Compiler & Flags ===
CXX := g++
CXXFLAGS := -std=c++17 -O2 -Wall

# === 檔案設定 ===
TARGET := tb_pe_array
SRC :=  tb_pe_array.cpp
# 若還有其他 .cpp (例如在 tb_OS/ 或 analyzer/ 下)，可加進來：
# SRC += tb_OS/OS_Based_with_mem_Simulator.cpp analyzer/Mapper_base.cpp

# === 偵測 g++ 版本是否小於 9，自動加上 -lstdc++fs ===
GXX_VER := $(shell $(CXX) -dumpfullversion -dumpversion | cut -d. -f1)
ifeq ($(shell [ $(GXX_VER) -lt 9 ] && echo yes),yes)
    LDFLAGS += -lstdc++fs
endif
#1323
# === Build Rules ===
$(TARGET): $(SRC)
	@echo "Using g++ version $(GXX_VER)"
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

# === Clean ===
clean:
	rm -f $(TARGET) *.o