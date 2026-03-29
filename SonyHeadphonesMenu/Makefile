ROOT_DIR := $(shell cd .. && pwd)
BUILD_DIR := $(ROOT_DIR)/build
NPROC := $(shell sysctl -n hw.ncpu)

.PHONY: all libmdr app clean run

all: libmdr app

libmdr:
	@echo "=== Building libmdr ==="
	cmake -B $(BUILD_DIR) -S $(ROOT_DIR) \
		-DCMAKE_BUILD_TYPE=Release \
		-DMDR_ENABLE_CODEGEN=OFF
	cmake --build $(BUILD_DIR) --target mdr -j$(NPROC)

app: libmdr
	@echo "=== Building SonyHeadphonesMenu ==="
	swift build

run: app
	.build/debug/SonyHeadphonesMenu

clean:
	rm -rf .build
	rm -rf $(BUILD_DIR)
