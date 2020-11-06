-include Makefile.config

DEFAULT_FLAGS?=-default-type int64 -default-type word64

.PHONY: all clean realclean phony

default:
	@echo "usage: make <bench>.<impl>.<config>.bin"

clean:
	rm -f bin/*.bin* bin/*.log bin/*.c bin/*.s

phony:

%.bin: phony
	@mkdir -p bin
	@./scripts/compile.py \
		--benchmark $(shell echo $* | cut -d. -f1) \
		--impl $(shell echo $* | cut -d. -f2) \
		--config $(shell echo $* | cut -d. -f3) \
		--output "bin/$@" \
		--verbose \
		-- $(DEFAULT_FLAGS) $(EXTRA_FLAGS)
