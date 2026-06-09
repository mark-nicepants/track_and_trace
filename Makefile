# Convenience wrappers. All commands go through `fvm` so the pinned Flutter
# version (see .fvmrc) is used, and pass `--enable-experiment=primary-constructors`
# where required.
#
# `fvm dart analyze` reads the experiment flag from analysis_options.yaml.
# All other dart/flutter invocations need the flag.

EXP    = --enable-experiment=primary-constructors
FVM    = fvm
FLUTTER = $(FVM) flutter
DART    = $(FVM) dart

.PHONY: setup get analyze format layers test run build-ios build-android clean check

setup:
	$(FVM) install
	$(FLUTTER) pub get
	lefthook install

get:
	$(FLUTTER) pub get

analyze:
	$(DART) analyze --fatal-infos

format:
	$(DART) format $(EXP) --set-exit-if-changed --output=none .

layers:
	$(DART) run $(EXP) tool/check_architecture_violations.dart

test:
	$(FLUTTER) test $(EXP)

run:
	$(FLUTTER) run $(EXP)

build-ios:
	$(FLUTTER) build ios $(EXP)

build-android:
	$(FLUTTER) build appbundle $(EXP)

clean:
	$(FLUTTER) clean

check: analyze format layers test
