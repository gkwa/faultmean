clean:
	shfmt -w -s -i 4 *.sh
	shellcheck --external-sources *.sh
