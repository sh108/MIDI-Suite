
CC            = g++

ifeq (\$(OS),Windows_NT)
# for Windows
CPPUTEST_LOC  = cpputest-3.8
CFLAGS        = -I$(CPPUTEST_LOC)/include
LDFLAGS       = -L$(CPPUTEST_LOC)/cpputest_build/src/CppUTest

else
UNAME = \${shell uname}

ifeq (\$(UNAME),Linux)
# for Linux

endif

ifeq (\$(UNAME),Darwin)
# for MacOSX
CPPUTEST_LOC  = /usr/local/Cellar/cpputest/3.8
CFLAGS        = -I$(CPPUTEST_LOC)/include/CppUTest/
LDFLAGS       = -L$(CPPUTEST_LOC)/Lib

endif

endif

LIBS          += -lCppUTest
PROGRAM       := unittest

SRC_DIR       := src
BUILD_DIR     := build

SRCS          := $(shell find src/ -name *.cpp)
OBJS          := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SRCS))

DEPS := $(patsubst %.o,%.d,$(OBJS))

all: $(DEPS)
	@$(MAKE) $(PROGRAM)

$(PROGRAM): $(OBJS)
	@$(CC) $^ $(CFLAGS) $(LDFLAGS) $(LIBS) -o $(PROGRAM)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CC) $(CFLAGS) -c $< -Wall -o $@

ifneq ($(filter clean,$(MAKECMDGOALS)),clean)
-include $(DEPS)
endif

$(BUILD_DIR)/%.d: $(SRC_DIR)/%.cpp
	@if [ ! -d $(dir $@) ]; then \
		mkdir -p $(dir $@); \
	fi
	@$(CC) -MM $(CFLAGS) $< | sed 's/$(basename $(notdir $<))\.o[ :]*/$(subst /,\/,$(subst .d,.o,$@)) $(subst /,\/,$@) : /g' > $@

#%: %.d

PHONY: all clean

clean:
	rm -rf *.o *.d build *~ $(PROGRAM).exe
