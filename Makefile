HS_FILES = $(shell git ls-files '*.hs' | grep -v 'vendored/')
CABAL_FILES = $(shell git ls-files '*.cabal' | grep -v 'vendored/')

.PHONY: update
update:
	cabal update

.PHONY: build
build:
	cabal build all -j4

.PHONY: test-llvm-calc
test-llvm-calc:
	cabal run llvm-calc:tests

.PHONY: test-llvm-calc2
test-llvm-calc2:
	cabal run llvm-calc2:tests

.PHONY: test-llvm-calc3
test-llvm-calc3:
	cabal run llvm-calc3:tests

.PHONY: test-llvm-calc4
test-llvm-calc4:
	cabal run llvm-calc4:tests

.PHONY: freeze
freeze:
	cabal freeze --enable-tests --enable-benchmarks

.PHONY: format
format:
	@ormolu --mode inplace $(HS_FILES) && echo "Ormolu success!"

.PHONY: hlint
hlint:
	@hlint $(HS_FILES)

.PHONY: format-cabal
format-cabal:
	@cabal-fmt -i $(CABAL_FILES)
