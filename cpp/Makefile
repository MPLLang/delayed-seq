CPP=g++
INSTALL_FOLDER=bin

ifeq (, $(shell which jemalloc-config))
JEMALLOC =
else
JEMALLOCLD = $(shell jemalloc-config --libdir)
JEMALLOC = -L$(JEMALLOCLD) -ljemalloc
endif

CILK_COMMON_PREFIX=-fcilkplus -lcilkrts -DCILK -ldl -DPARLAY_CILK

ifdef USE_HWLOC
	HWLOC_PREFIX+=-DUSE_HWLOC
endif

INCLUDE_FILES=\
	$(wildcard *.hpp *.h)
INCLUDE_DIRECTIVES=

WARNINGS_PREFIX=-Wno-subobject-linkage -Wno-overflow
COMMON_PREFIX=-std=c++17 -mcx16 $(WARNINGS_PREFIX) $(HWLOC_PREFIX)

OPT_PREFIX=-O3 -march=native -DNDEBUG $(COMMON_PREFIX)
DBG_PREFIX=-O0 -g3 $(COMMON_PREFIX)

PARDBG_PREFIX=$(DBG_PREFIX) $(CILK_COMMON_PREFIX)
SEQDBG_PREFIX=$(DBG_PREFIX)

PBBSLIBCPP_PREFIX=$(OPT_PREFIX) $(CILK_COMMON_PREFIX)
PBBSLIBCPPHG_PREFIX=$(OPT_PREFIX) $(HOMEGROWN_COMMON_PREFIX)

# Debugging binaries
# ------------------

%.pardbg.bin: %.cpp $(INCLUDE_FILES)
	$(CPP) $(PARDBG_PREFIX) $(INCLUDE_DIRECTIVES) -o $@ $<

%.seqdbg.bin: %.cpp $(INCLUDE_FILES)
	$(CPP) $(SEQDBG_PREFIX) $(INCLUDE_DIRECTIVES) -o $@ $<

# Optimized binaries
# ------------------

%.cpp.bin: %.cpp $(INCLUDE_FILES)
	$(CPP) $(PBBSLIBCPP_PREFIX) $(INCLUDE_DIRECTIVES) -o $@ $< $(JEMALLOC)

%.cppstats.bin: %.cpp $(INCLUDE_FILES)
	$(CPP) $(PBBSLIBCPP_PREFIX) $(INCLUDE_DIRECTIVES) $(CILK_EXTRAS_PREFIX) -o $@ $< $(JEMALLOC)

%.cpphg.bin: %.cpp $(INCLUDE_FILES)
	$(CPP) $(PBBSLIBCPPHG_PREFIX) $(INCLUDE_DIRECTIVES) -o $@ $< $(JEMALLOC)


PROGRAMS=\
	mcss.array.cpp.bin

all_cpp: $(PROGRAMS:%=%.cpp.bin)

install:
	cp run $(INSTALL_FOLDER)
	cp *.bin $(INSTALL_FOLDER)/

clean:
	rm -f *.bin
