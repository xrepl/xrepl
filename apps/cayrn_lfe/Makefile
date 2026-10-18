REBAR ?= rebar3
.PHONY: help build check clean
help:
	@printf 'cayrn-lfe: make build | make check | make clean\n'
build:
	$(REBAR) compile
check: build
	$(REBAR) eunit
clean:
	$(REBAR) clean
