
BIN_NAME := bakugen.exe

SOURCE_PATH = src

CXX = g++
COMPILE_FLAGS = -std=c++14 -Wall -Wextra -DDX_GCC_COMPILE -DBOOST_USE_WINDOWS_H
DCOMPILE_FLAGS = -O0 -g -D DEBUG
RCOMPILE_FLAGS = -O3 -D NDEBUG
INCLUDES = -I $(SOURCE_PATH)/ -ID:/lib/boost_1_57_0 -ID:/lib/DxLib_GCC/MinGW/4_9_2_x86_64_w64
LIBS = -LD:/lib/boost_1_57_0/stage/x64/lib -LD:/lib/DxLib_GCC/MinGW/4_9_2_x86_64_w64
LINK_FLAGS = -static-libgcc -static-libstdc++ -lm -lDxLib -lDxUseCLib -ljpeg -lpng -lzlib -ltheora_static -lvorbis_static \
			 -lvorbisfile_static -lDxDrawFunc -logg_static -lbulletdynamics -lbulletcollision -lbulletmath -ltiff \
			 -mwindows
DLINK_FLAGS = -lboost_system-mgw49-mt-d-1_57 -lboost_filesystem-mgw49-mt-d-1_57 -lboost_serialization-mgw49-mt-d-1_57
RLINK_FLAGS = -lboost_system-mgw49-mt-1_57 -lboost_filesystem-mgw49-mt-1_57 -lboost_serialization-mgw49-mt-1_57

PRECOMPILE_HEADER = $(SOURCE_PATH)/stdafx.hpp

SHELL = /bin/bash

SOURCES = $(shell find $(SOURCE_PATH)/ -name '*.cpp' -printf '%T@\t%p\n' \
		  			| sort -k 1nr | cut -f2-)
rwildcard = $(foreach d, $(wildcard $1*), $(call rwildcard,$d/,$2) \
						$(filter $(subst *,$2), $d))
#ifeq ($(SOURCES),)
#	SOURCES := $(call rwildcard, $(SOURCE_PATH)/, *.cpp)
#endif

release: export CXXFLAGS := $(CXXFLAGS) $(COMPILE_FLAGS) $(RCOMPILE_FLAGS)
release: export LDFLAGS := $(LDFLAGS) $(LIBS) $(LINK_FLAGS) $(RLINK_FLAGS)
debug: export CXXFLAGS := $(CXXFLAGS) $(COMPILE_FLAGS) $(DCOMPILE_FLAGS)
debug: export LDFLAGS := $(LDFLAGS) $(LIBS) $(LINK_FLAGS) $(DLINK_FLAGS)

# build.sh で無理やり変数作った. 大体dependsのせい
#release: export BUILD_PATH := build/release
#release: export BIN_PATH := bin/release
#debug: export BUILD_PATH := build/debug
#debug: export BIN_PATH := bin/debug

OBJECTS = $(SOURCES:$(SOURCE_PATH)/%.cpp=$(BUILD_PATH)/%.o)
OBJECTS += $(BUILD_PATH)/resource.o
DEPENDS = $(OBJECTS:.o=.d)

# $$で$を表す
TIME_FILE = $(dir $@).$(notdir $@)_time
START_TIME = date '+%s' > $(TIME_FILE)
END_TIME = read st < $(TIME_FILE) ; \
		   rm $(TIME_FILE) ; \
		   st=$$((`date '+%s'` - $$st - 86400)) ; \
		   echo `date -u -d @$$st '+%H:%M:%S'`

.PHONY: precompile
precompile: $(PRECOMPILE_HEADER)
	@echo "Precompiling..."
	@$(START_TIME)
	@$(CXX) $(CXXFLAGS) $(INCLUDES) $(PRECOMPILE_HEADER)
	@echo -en "\t Precompile time: "
	@$(END_TIME)
	@echo ""

#echo -n は改行を出力しない -e はエスケープ文字を有効にして表示
.PHONY: release
release: dirs precompile
	@echo "Beginning release build"
	@$(START_TIME)
	@make all --no-print-directory
	@echo -n "Total build time: "
	@$(END_TIME)

.PHONY: debug
debug: dirs precompile
	@echo "Beginning debug build"
	@$(START_TIME)
	@make all --no-print-directory
	@echo -n "Total build time: "
	@$(END_TIME)

.PHONY: dirs
dirs:
	@echo "Creating directories"
	@mkdir -p $(dir $(OBJECTS))
	@mkdir -p $(BIN_PATH)
	@mkdir -p $(dir $(DEPENDS))

.PHONY:	clean
clean:
	@echo "Deleting derectories"
	@rm -rf build
	@rm -rf bin

all: $(BIN_PATH)/$(BIN_NAME)
	@echo "Making symlink: $(BIN_NAME) -> $<"
	@rm -f $(BIN_NAME)
	@ln -s $(BIN_PATH)/$(BIN_NAME) $(BIN_NAME)

$(BIN_PATH)/$(BIN_NAME): $(OBJECTS)
	@echo "Linking: $@"
	@$(START_TIME)
	@$(CXX) $(OBJECTS) $(LDFLAGS) -o $@
	@echo -en "\t Link time: "
	@$(END_TIME)
	@echo ""

-include $(DEPENDS)

$(BUILD_PATH)/%.o: $(SOURCE_PATH)/%.cpp
	@echo "Compiling: $< -> $@"
	@$(START_TIME)
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -MP -MMD -c $< -o $@
	@echo -en "\t Compile time: "
	@$(END_TIME)
	@echo ""

# For resource file
$(BUILD_PATH)/resource.o: src/resource.rc
	cd src; \
	sed 's/\\/\\\\/' resource.rc | windres -o ../$(BUILD_PATH)/resource.o

