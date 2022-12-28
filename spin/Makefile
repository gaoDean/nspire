.SUFFIXES:
.SUFFIXES: .lua

ALL: spin.tns

FILE: spin

out.lua:
	nspire-merge --out $@ -- spin.lua

%.tns: out.lua
	luna $< $@

clean:
	rm out.lua
	rm spin.tns
