# Name of the binary to create
PROJECT_NAME  := libtbrx
IS_STATIC_LIB := true     # Only used if project is a library (false: dynamic library)

# Compiling options and settings
CEXT     := cpp
CXX      := gcc
CXXSTD   := c++20
CXXFLAGS := -W -Wall -Wextra -pedantic -std=$(CXXSTD)
LDFLAGS  := -L@/usr/lib -lstdc++ -lfmt


# Utility
has_dir = $(shell if [[ -d "$(1)" ]]; then echo "$(1)"; fi)

# Variables
ROOTDIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
ifeq ($(OS),Windows_NT) 
    USER_OS := windows
else
    USER_OS := $(shell echo $(shell uname 2>/dev/null || echo unknown) | tr A-Z a-z)
endif

# Directories
ifneq (, $(findstring lib,$(PROJECT_NAME))) # Project IS library
	TARGETDIR := $(ROOTDIR)/lib

	ifeq ($(USER_OS),darwin)
	TARGETEXT := .dylib
	endif

	ifeq ($(USER_OS),linux)
	TARGETEXT := $(if ifeq ($(IS_STATIC_LIB),true),.a,.so)
	endif

	ifeq ($(USER_OS),windows)
	TARGETEXT := .dll
	endif
else
	TARGETDIR := $(ROOTDIR)/bin
	TARGETEXT :=
endif
BUILDDIR     := $(ROOTDIR)/build
SRCDIR       := $(ROOTDIR)/$(PROJECT_NAME)
DEPDIR       := $(ROOTDIR)/deps
TESTDIR      := $(ROOTDIR)/test
ALLDIRS      := $(patsubst $(ROOTDIR)/%,%,$(call has_dir,$(TARGETDIR)) $(call has_dir,$(SRCDIR)) $(call has_dir,$(BUILDDIR)) $(call has_dir,$(DEPDIR)) $(call has_dir,$(TESTDIR)))

# Target source files
INCLUDES     := -I$(PROJECT_NAME) -Ideps
SRCFILES     := $(shell cd $(SRCDIR) && find $(SRCDIR) -name "*.c*" | sed -E 's:^$(SRCDIR)/::g')
HEADERFILES  := $(shell cd $(SRCDIR) && find $(SRCDIR) -name "*.h*" | sed -E 's:^$(SRCDIR)/::g')
EXTDEPFILES  := $(shell if [[ -d "$(DEPDIR)" ]]; then cd $(DEPDIR) && find $(DEPDIR) -name '*.?pp*' | sed -E 's:^$(ROOTDIR)/::g'; fi)
TESTFILES    := $(shell if [[ -d "$(TESTDIR)" ]]; then cd $(TESTDIR) && find $(TESTDIR) -name '*.?pp*' | sed -E 's:^$(ROOTDIR)/::g'; fi)
OBJECTS      := $(SRCFILES:%.$(CEXT)=$(BUILDDIR)/%.o)
DEPENDENCIES := $(OBJECTS:.o=.d)

# First rule will get called if only "make" is used
default: debug

all: clean build $(BINDIR)/$(TARGET)

$(BUILDDIR)/%.o: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -MMD -o $@

$(BINDIR)/$(TARGET): $(OBJECTS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $(BINDIR)/$(TARGET) $^ $(LDFLAGS)

-include $(DEPENDENCIES)

build:
	@mkdir -p $(BINDIR)
	@mkdir -p $(BUILDDIR)

debug: CXXFLAGS += -DDEBUG -g
debug: all

release: CXXFLAGS += -O3
release: all

clear: clean
clean:
	@echo "Cleaning built files"
	-@rm -vrf $(BUILDDIR)/*
	-@rm -vrf $(BINDIR)/*

info:
ifeq ($(USER_OS),linux) 
	@echo -e "\x1b[1m - Detected OS\x1b[0m:    $(USER_OS)                                                           "
	@echo -e "\x1b[1m - Output\x1b[0m:         $(patsubst $(ROOTDIR)/%,%,$(TARGETDIR))/$(PROJECT_NAME)$(TARGETEXT)  "
	@echo -e "\x1b[1m - Directories\x1b[0m:    $(patsubst %,%/,$(ALLDIRS))                                          "
	@echo -e "\x1b[1m - Sources\x1b[0m:\n $(patsubst %,    $(PROJECT_NAME)/%\n,$(SRCFILES))                         "
ifneq (,$(HEADERFILES))
	@echo -e "\x1b[1m - Headers\x1b[0m:\n$(patsubst %,    $(PROJECT_NAME)/%\n,$(HEADERFILES))                       "
endif
ifneq (,$(EXTDEPFILES))
	@echo -e "\x1b[1m - External\x1b[0m:\n$(patsubst %,    %\n,$(EXTDEPFILES))                                      "
endif
ifneq (,$(TESTFILES))
	@echo -e "\x1b[1m - Test\x1b[0m:\n$(patsubst %,    %\n,$(TESTFILES))                                            "
endif
endif
ifeq ($(USER_OS),darwin) 
	@gecho -e "\x1b[1m - Detected OS\x1b[0m:    $(USER_OS)                                                          "
	@gecho -e "\x1b[1m - Output\x1b[0m:         $(patsubst $(ROOTDIR)/%,%,$(TARGETDIR))/$(PROJECT_NAME)$(TARGETEXT) "
	@gecho -e "\x1b[1m - Directories\x1b[0m:    $(patsubst %,%/,$(ALLDIRS))                                         "
	@gecho -e "\x1b[1m - Sources\x1b[0m:\n $(patsubst %,    $(PROJECT_NAME)/%\n,$(SRCFILES))                        "
ifneq (,$(HEADERFILES))
	@gecho -e "\x1b[1m - Headers\x1b[0m:\n$(patsubst %,    $(PROJECT_NAME)/%\n,$(HEADERFILES))                      "
endif
ifneq (,$(EXTDEPFILES))
	@gecho -e "\x1b[1m - External\x1b[0m:\n$(patsubst %,    %\n,$(EXTDEPFILES))                                     "
endif
ifneq (,$(TESTFILES))
	@gecho -e "\x1b[1m - Test\x1b[0m:\n$(patsubst %,    %\n,$(TESTFILES))                                           "
endif
endif
	

.PHONY: all build clean clear debug release info
