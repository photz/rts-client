SHELL=/bin/bash
pubflags=--mode debug
dartanalyzer=/usr/lib/dart/bin/dartanalyzer
dartanalyzerflags=--strong --lints --package-warnings
dirs=test web lib
pub=/usr/lib/dart/bin/pub
sass_root=web/sass
css_dest=styles.css

.PHONY: test start build analyze build-sass start-analyze

start:
	find $(dirs) -name '*.dart' | grep -v '#' | entr make build



start-analyze:
	find $(dirs) -name '*.dart' | grep -v '#' | entr make analyze

watch-sass:
	find $(sass_root) -name '*.scss' | grep -v '#' | entr make build-sass

build: web/*.dart analyze
	$(pub) build $(pubflags)
	notify-send "Compilation finished"


build-sass:
	find web/sass/ -name '*.scss' | awk '{print "@import \"" $$0 "\""}' | SASS_PATH='.' sass --scss --stdin > $(css_dest)

analyze: 
	reset
	$(dartanalyzer) $(dartanalyzerflags) web/main.dart

test:
	find $(dirs) -name '*.dart' | grep -v '#' | entr pub run test test/*.dart

