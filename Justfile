#!/usr/bin/env just
# * Project scripts, using https://github.com/casey/just (last tested with 1.24.0)
# Usage: alias j=just, run j to list available scripts.
#
# After many years with make and plain shell and haskell for
# scripting, just is better enough, and the goal of clean consolidated
# efficient project automation is so valuable, that I am relying on it
# even though it's not installed by default.
#
# All of Makefile has been absorbed below; uncomment/update/drop
# remaining bits when needed. Makefile will be removed some time soon.
#
# just currently lacks make-style file dependency tracking.  When that
# is needed for efficiency, or when more powerful code is needed, use
# Shake.hs instead of just.
#
# Lines beginning with "# * ", "# ** ", etc are section headings,
# foldable in Emacs outshine-mode. Some extra Emacs highlighting:
# (add-hook 'just-mode-hook (lambda ()
#   (display-line-numbers-mode 1)
#   (highlight-lines-matching-regexp "^# \\*\\*? " 'hi-yellow)  ; level 1-2 outshine headings
#   (highlight-lines-matching-regexp "^@?\\w.*\\w:$" 'hi-pink) ; recipe headings (misses recipes with dependencies)
#   ))
#
# This file is formatted by `just format`, which currently eats blank lines a bit (and commits).
#
# 'set export' makes constants and arguments available as $VAR as well as {{ VAR }}.
# $ makes just code more like shell code.
# {{ }} handles multi-word values better and is fully evaluated in -n/--dry-run output.
#
# Reference:
# https://docs.rs/regex/1.5.4/regex/#syntax Regexps
# https://just.systems/man/en/chapter_31.html Functions
# https://cheatography.com/linux-china/cheat-sheets/justfile Cheatsheet
# https://github.com/casey/just/discussions

# ** Helpers ------------------------------------------------------------
HELPERS: help

set export := true

# and/or: -q --bell --stop-timeout=1

WATCHEXEC := 'watchexec --timings'

# grep-like rg
#RG_ := 'rg --sort=path --no-heading -i'
#TODAY := `date +%Y-%m-%d`
# just := "just -f " + justfile()
# Use this justfile from within its directory, otherwise we must write {{ just }} everywhere.

# list this justfile's recipes, optionally filtered by REGEX
@help *REGEX:
    if [[ '{{ REGEX }}' =~ '' ]]; then just -lu; else just -lu | rg -i '{{ REGEX }}'; true; fi

alias h := help

# check this justfile for errors and non-standard format
@check:
    just --fmt --unstable --check

# if this justfile is error free but in non-standard format, reformat it, and if it has changes, commit it
@format:
    just -q chk || just -q --fmt --unstable && git diff --quiet || git commit -m ';just: format' -- {{ justfile() }}

# rerun RECIPE when any watched-by-default file changes
watch RECIPE *JOPTS:
    #!/usr/bin/env bash
    $WATCHEXEC  -r --filter-file <(git ls-files) -- just $RECIPE {{ JOPTS }}

# rerun RECIPE when any git-committed file changes
watchgit RECIPE *JOPTS:
    #!/usr/bin/env bash
    $WATCHEXEC  -r --filter-file <(git ls-files) -- just $RECIPE {{ JOPTS }}

# show watchexec env vars when any file changes, printing events and ignoring nothing
_watchdbg *WOPTS:
    $WATCHEXEC  --ignore-nothing --print-events {{ WOPTS }} -- 'env | rg "WATCHEXEC\w*"; true'

# show watchexec env vars when any git-committed file changes
_watchgitdbg *WOPTS:
    #!/usr/bin/env bash
     $WATCHEXEC  -r --filter-file <(git ls-files) {{ WOPTS }} -- 'env | rg "WATCHEXEC\w*"; true'

# ** Constants ------------------------------------------------------------

BROWSE := 'open'

# XXX These often don't work well interpolated as $CMD or {{ CMD }}, not sure why
# find GNU tools, eg on mac

GDATE := `type -P gdate || echo date`
GTAR := `type -P gtar || echo tar`

#GNUTAR := `which gtar >/dev/null && echo gtar || echo tar`
# make ghc usable for scripting with -e

GHC := 'ghc -ignore-dot-ghci -package-env -'
GHCI := 'ghci'

# GHCPKG := 'ghc-pkg'
# HADDOCK := 'haddock'
# CABAL := 'cabal'
# CABALINSTALL := 'cabal install -w {{ GHC }}'
# GHC-compiled executables require a locale (and not just C) or they
# will die on encountering non-ascii data. Set LANG to something if not already set.
# export LANG? := 'en_US.UTF-8'
# command to run during profiling (time and heap)
# command to run when profiling

PROFCMD := 'stack exec --profile -- hledger balance -f examples/10000x1000x10.journal >/dev/null'
PROFRTSFLAGS := '-P'

# # command to run when checking test coverage
# COVCMD := 'test'
# COVCMD := '-f test-wf.csv print'
# Which stack command (and in particular, stack yaml/GHC version) to use for building etc. ?

STACK := 'stack'

#STACK := 'stack --stack-yaml=stack8.10.yaml'
# Or override temporarily with an env var:
# STACK := '"stack --stack-yaml=stack8.10.yaml" make functest'
# if using an unreleased stack with a newer hpack than the one mentioned in */*.cabal,
# it will give warnings. To silence these, put the old hpack-X.Y in $PATH and uncomment:
#STACK := 'stack --with-hpack=hpack-0.20'
# --threads := '16 sometimes gives "commitAndReleaseBuffer: resource vanished (Broken pipe)" but seems harmless'
# --timeout := 'N is not much use here - can be defeated by multiple threads, unoptimised builds, '
# slow hackage index or compiler setup on first build, etc.
# Which stack command (stack yaml, GHC version) to use for ghci[d] operations ?

STACKGHCI := STACK

#STACKGHCI := 'stack --stack-yaml=stack9.2.yaml'
# PACKAGES := '
#     hledger-lib
#     hledger
#     hledger-ui
#     hledger-web
#     '
# BINARIES := '
#     hledger
#     hledger-ui
#     hledger-web
#     '

INCLUDEPATHS := '
    -ihledger-lib
    -ihledger
    -ihledger-ui
    -ihledger-web
    -ihledger-web/app
    '
MAIN := 'hledger/app/hledger-cli.hs'

# All source files in the project (plus a few strays like Setup.hs & hlint.hs).
# Used eg for building tags. Doesn't reliably catch all source files.

SOURCEFILES := '
    dev.hs
    hledger/*hs
    hledger/app/*hs
    hledger/bench/*hs
    hledger/test/*hs
    hledger/Hledger/*hs
    hledger/Hledger/*/*hs
    hledger/Hledger/*/*/*hs
    hledger-*/*hs
    hledger-*/app/*hs
    hledger-*/test/*hs
    hledger-*/Hledger/*hs
    hledger-*/Hledger/*/*hs
    hledger-*/Hledger/*/*/*hs
    hledger-lib/Text/*/*hs
    '
HPACKFILES := '
    hledger/*package.yaml
    hledger-*/*package.yaml
    '
CABALFILES := '
    hledger/hledger.cabal
    hledger-*/*.cabal
    '
MANUALSOURCEFILES := '
    doc/common.m4
    */*.m4.md
    '

# MANUALGENFILES := '
#     hledger*/hledger*.{1,5,info,txt}
#     '

COMMANDHELPFILES := '
    hledger/Hledger/Cli/Commands/*.md
    '
WEBTEMPLATEFILES := '
    hledger-web/templates/*
    '
WEBCODEFILES := '
    hledger-web/static/*.js
    hledger-web/static/*.css
    '
DOCSOURCEFILES := '
    README.md
    CONTRIBUTING.md
    ' + MANUALSOURCEFILES + COMMANDHELPFILES
TESTFILES := `fd '\.test$' --exclude ledger-compat`

# XXX it's fd-find on gnu/linux ?
# # file(s) which require recompilation for a build to have an up-to-date version string
# VERSIONSOURCEFILE := 'hledger/Hledger/Cli/Version.hs'
# Two or three-part version string, set as program version in builds made by this makefile.
# We use hledger CLI's current version (XXX for all packages, which isn't quite right).

export VERSION := `cat hledger/.version`

# Flags for ghc builds.
# Warnings to see during dev tasks like make ghci*. See also the warnings in package.yamls.
# XXX redundant with package.yamls ?

WARNINGS := '
    -Wall
    -Wno-incomplete-uni-patterns
    -Wno-missing-signatures
    -Wno-orphans
    -Wno-type-defaults
    -Wno-unused-do-bind
    '

# if you have need to try building in less memory

GHCLOWMEMFLAGS := ''

# ghc-only builds need the macro definitions generated by cabal
# from cabal's dist or dist-sandbox dir, hopefully there's just one:
#CABALMACROSFLAGS := '-optP-include -optP hledger/dist*/build/autogen/cabal_macros.h'
# or from stack's dist dir:
#CABALMACROSFLAGS := '-optP-include -optP hledger/.stack-work/dist/*/*/build/autogen/cabal_macros.h'

CABALMACROSFLAGS := ''
BUILDFLAGS := '-rtsopts ' + WARNINGS + GHCLOWMEMFLAGS + CABALMACROSFLAGS + ' -DDEVELOPMENT' + ' -DVERSION="' + VERSION + '"' + INCLUDEPATHS

#    -fplugin Debug.Breakpoint \
#    -fhide-source-paths \
# PROFBUILDFLAGS := '-prof -fprof-auto -osuf hs_p'

TIME := "{{ shell date +'%Y%m%d%H%M' }}"
MONTHYEAR := "{{ shell date +'%B %Y' }}"

# ** Building ------------------------------------------------------------
BUILDING:

# build the hledger package showing ghc codegen times/allocations
@buildtimes:
    time ($STACK build hledger --force-dirty --ghc-options='-fforce-recomp -ddump-timings' 2>&1 | grep -E '\bCodeGen \[.*time=')

# # build an unoptimised hledger at bin/hledger.EXT.unopt (default: git describe)
# build-unopt *EXT:
#     #!/usr/bin/env bash
#     ext={{ if EXT == '' { `git describe --tags` } else { EXT } }}
#     exe="bin/hledger.$ext.unopt"
#     $STACK --verbosity=error install --ghc-options=-O0 hledger --local-bin-path=bin
#     mv bin/hledger "$exe"
#     echo "$exe"
# # build hledger with profiling enabled at bin/hledgerprof
# hledgerprof:
# # $STACK --verbosity=error install --local-bin-path=bin hledger
#     $STACK build --profile hledger
# # hledger-lib --ghc-options=-fprof-auto
# #    @echo "to profile, use $STACK exec --profile -- hledger ..."
# # build "bin/hledgercov" for coverage reports (with ghc)
# hledgercov:
#     $STACK ghc {{ MAIN }} -fhpc -o bin/hledgercov -outputdir .hledgercovobjs $BUILDFLAGS

# run ghcid on hledger-lib + hledger
@ghcid:
    ghcid -c 'just ghci'

# run ghcid autobuilder on hledger-lib + hledger + hledger-ui
@ghcid-ui:
    ghcid -c 'just ghci-ui'

# run ghcid autobuilder on hledger-lib + hledger + hledger-web
@ghcid-web:
    ghcid -c 'just ghci-web'

# run ghcid autobuilding and running hledger-web with sample journal on port 5001
@ghcid-web-run:
    ghcid -c 'just ghci-web' --test ':main -f examples/sample.journal --port 5001 --serve'

# # run ghcid autobuilding and running the test command
# ghcid-test:
#     ghcid -c 'just ghci' --test ':main test -- --color=always'
# # run ghcid autobuilding and running the test command with this TESTPATTERN
# ghcid-test-%:
#     ghcid -c 'just ghci' --test ':main test -- --color=always -p$*'

# run ghcid autobuilding and running hledger-lib doctests
@ghcid-doctest:
    ghcid -c 'cd hledger-lib; $STACK ghci hledger-lib:test:doctest' --test ':main' --reload hledger-lib

GHCIDRESTART := '--restart Makefile --restart Makefile.local'
GHCIDRELOAD := '--reload t.j --reload t.timedot'
GHCIDCMD := ':main -f t.j bal date:today -S'

# # run ghcid autobuilding and running a custom GHCI command with reload/restart on certain files - customise this
# ghcid-watch watch:
#     ghcid -c 'just ghci' --test '{{ GHCIDCMD }}' {{ GHCIDRELOAD }} {{ GHCIDRESTART }}
# keep synced with Shake.hs header

SHAKEDEPS := '\
    --package base-prelude \
    --package directory \
    --package extra \
    --package process \
    --package regex \
    --package safe \
    --package shake \
    --package time \
    '

#    --package hledger-lib \  # for Hledger.Utils.Debug

# run ghcid autobuilder on Shake.hs
ghcid-shake:
    stack exec {{ SHAKEDEPS }} -- ghcid Shake.hs

# ** Testing ------------------------------------------------------------
TESTING:

# run ghci on hledger-lib + hledger
@ghci:
    $STACKGHCI exec -- $GHCI $BUILDFLAGS -fobject-code hledger/Hledger/Cli.hs

# run ghci on hledger-lib + hledger with profiling/call stack information
@ghci-prof:
    stack build --profile hledger --only-dependencies
    $STACKGHCI exec -- $GHCI $BUILDFLAGS -fexternal-interpreter -prof -fprof-auto hledger/Hledger/Cli.hs

# # run ghci on hledger-lib + hledger + dev.hs script
# @ghci-dev:
#     $STACKGHCI exec -- $GHCI $BUILDFLAGS -fno-warn-unused-imports -fno-warn-unused-binds dev.hs

# run ghci on hledger-lib + hledger + hledger-ui
@ghci-ui:
    $STACKGHCI exec -- $GHCI $BUILDFLAGS hledger-ui/Hledger/UI/Main.hs

# run ghci on hledger-lib + hledger + hledger-web
@ghci-web:
    $STACKGHCI exec -- $GHCI $BUILDFLAGS hledger-web/app/main.hs

# run ghci on hledger-lib + hledger + hledger-web + hledger-web test suite
@ghci-web-test:
    $STACKGHCI exec -- $GHCI $BUILDFLAGS hledger-web/test/test.hs

# # better than stack exec ?
# # XXX does not see changes to files
# # run ghci on hledger-lib + test runner
# ghci-lib-test:
#     $STACKGHCI ghci --ghc-options="\'-rtsopts {{ WARNINGS }} -ihledger-lib  -DDEVELOPMENT -DVERSION=\"1.26.99\"\'" hledger-lib/test/unittest.hs
# run ghci on all the hledger
# ghci-all:
#     $STACK exec -- $GHCI $BUILDFLAGS \
#         hledger-ui/Hledger/UI/Main.hs \
#         hledger-web/app/main.hs \

# run ghci on hledger-lib doctests
@ghci-doctest:
    cd hledger-lib; $STACKGHCI ghci hledger-lib:test:doctest

# run ghci on Shake.hs
@ghci-shake:
    $STACK exec {{ SHAKEDEPS }} -- ghci Shake.hs

# #    hledger-lib/Hledger/Read/TimeclockReaderPP.hs
# # build the dev.hs script for quick experiments (with ghc)
# dev:
#     $STACK ghc -- {{ CABALMACROSFLAGS }} -ihledger-lib dev.hs \
# # to get profiling deps installed, first do something like:
# # stack build --library-profiling hledger-lib timeit criterion
# # build the dev.hs script with profiling support
# devprof:
#     $STACK ghc -- {{ CABALMACROSFLAGS }} -ihledger-lib dev.hs -rtsopts -prof -fprof-auto -osuf p_o -o devprof
# # get a time & space profile of the dev.hs script
# dev-profile:
#     time ./devprof +RTS -P \
#     && cp devprof.prof devprof.prof.{{ TIME }} \
#     && profiterole devprof.prof
# # get heap profiles of the dev.hs script
# dev-heap:
#     time ./devprof +RTS -hc -L1000 && cp devprof.hp devprof-hc.hp && hp2ps devprof-hc.hp
#     time ./devprof +RTS -hr -L1000 && cp devprof.hp devprof-hr.hp && hp2ps devprof-hr.hp
# dev-heap-upload:
#     curl -F "file=@devprof-hc.hp" -F "title='hledger parser'" http://heap.ezyang.com/upload
#     curl -F "file=@devprof-hr.hp" -F "title='hledger parser'" http://heap.ezyang.com/upload

# run tests that are reasonably quick (files, unit, functional) and benchmarks
test: filestest functest

# For quieter tests add --silent. It may hide troubleshooting info.
# For very verbose tests add --verbosity=debug. It seems hard to get something in between.

STACKTEST := STACK + ' test --fast'

# # When doing build testing, save a little time and output noise by not
# # running tests & benchmarks. Comment this out if you want to run them.
# SKIPTESTSBENCHS := '--no-run-tests --no-run-benchmarks'

# check all files embedded with file-embed are declared in extra-source-files
@filestest:
    tools/checkembeddedfiles

# # stack build --dry-run all hledger packages ensuring an install plan with default snapshot)
# buildplantest:
#     buildplantest-stack.yaml
# # stack build --dry-run all hledger packages ensuring an install plan with each ghc version/stackage snapshot
# buildplantest-all:
#     for F in stack*.yaml; do make --no-print-directory buildplantest-$F; done
# # stack build --dry-run all hledger packages ensuring an install plan with the given stack yaml file; eg make buildplantest-stack8.2.yaml
# buildplantest-%:
#     $STACK build --dry-run --test --bench --stack-yaml=$*
# # force-rebuild all hledger packages/modules quickly ensuring no warnings with default snapshot)
# buildtest:
#     buildtest-stack.yaml
# # force-rebuild all hledger packages/modules quickly ensuring no warnings with each ghc version/stackage snapshot
# buildtest-all:
#     for F in stack*.yaml; do make --no-print-directory buildtest-$F; done
# # force-rebuild all hledger packages/modules quickly ensuring no warnings with the given stack yaml file; eg make buildtest-stack8.2.yaml
# buildtest-%:
#     $STACK build --test --bench {{ SKIPTESTSBENCHS }} --fast --force-dirty --ghc-options=-fforce-recomp --ghc-options=-Werror --stack-yaml=$*
# # build any outdated hledger packages/modules quickly ensuring no warnings with default snapshot. Wont detect warnings in up-to-date modules.)
# incr-buildtest:
#     incr-buildtest-stack.yaml
# # build any outdated hledger packages/modules quickly ensuring no warnings with each ghc version/stackage snapshot. Wont detect warnings in up-to-date modules.
# incr-buildtest-all:
#     for F in stack*.yaml; do make --no-print-directory incr-buildtest-$F; done
# # build any outdated hledger packages/modules quickly ensuring no warnings with the stack yaml file; eg make buildtest-stack8.2.yaml. Wont detect warnings in up-to-date modules.
# incr-buildtest-%:
#     $STACK build --test --bench {{ SKIPTESTSBENCHS }} --fast --ghc-options=-Werror --stack-yaml=$*
# # do a stack clean --full with all ghc versions for paranoia/troubleshooting
# stack-clean-all:
#     for F in stack*.yaml; do $STACK clean --full --stack-yaml=$F; done

# run all test suites in the hledger packages
@pkgtest:
    ($STACKTEST && echo $@ PASSED) || (echo $@ FAILED; false)

# doctest with ghc 8.4 on mac requires a workaround, see hledger-lib/package.yaml.
# Or, could run it with ghc 8.2:
#    @($STACKTEST --stack-yaml stack8.2.yaml hledger-lib:test:doctest && echo $@ PASSED) || (echo $@ FAILED; false)

# run the doctests in hledger-lib module/function docs
@doctest:
    ($STACKTEST --ghc-options=-f-object-code hledger-lib:test:doctest && echo $@ PASSED) || (echo $@ FAILED; false)

# # run the unit tests in hledger-lib
# unittest:
#     @($STACKTEST hledger-lib:test:unittest && echo $@ PASSED) || (echo $@ FAILED; false)

# run hledger & hledger-lib unit tests (do a stack build hledger first).
@unittest:
    ($STACK exec hledger test && echo $@ PASSED) || (echo $@ FAILED; false)

SHELLTEST := 'COLUMNS=80 ' + STACK + ' exec -- shelltest --execdir --threads=64 --exclude=/_'

#  --hide-successes

# build hledger quickly and run functional tests, with any shelltest OPTS (requires mktestaddons)
@functest *OPTS:
    $STACK build --fast hledger
    ({{ SHELLTEST }} {{ if OPTS == '' { '' } else { OPTS } }} \
        hledger/test/ bin/ \
        -x ledger-compat/ledger-baseline -x ledger-compat/ledger-regress -x ledger-compat/ledger-extra \
        && echo $@ PASSED) || (echo $@ FAILED; false)

ADDONEXTS := 'pl py rb sh hs lhs rkt exe com bat'

# generate dummy add-ons for testing the CLI
@mktestaddons:
    rm -rf hledger/test/addons/hledger-*
    printf '#!/bin/sh\necho add-on: $0\necho args: $*\n' >hledger/test/addons/hledger-addon
    for E in '' {{ ADDONEXTS }}; do \
        cp hledger/test/addons/hledger-addon hledger/test/addons/hledger-addon.$E; done
    for F in addon. addon2 addon2.hs addon3.exe addon3.lhs addon4.exe add reg; do \
        cp hledger/test/addons/hledger-addon hledger/test/addons/hledger-$F; done
    mkdir hledger/test/addons/hledger-addondir
    chmod +x hledger/test/addons/hledger-*

# compare hledger's and ledger's balance report
compare-balance:
    #!/usr/bin/env bash
    for f in examples/1txns-1accts.journal \
            examples/10txns-10accts.journal \
            ; do \
        (export f=$f; \
        printf "\n-------------------------------------------------------------------------------\n"; \
        echo "comparing hledger -f $f balance and ledger -f $f balance --flat"; \
        difft --color=always --display side-by-side-show-both <(hledger -f $f balance) <(ledger -f $f balance --flat) ) | tail +2; \
        done

# generate a hlint report
# hlinttest hlint:
#     hlint --hint=hlint --report=hlint.html {{ SOURCEFILES }}
# # run haddock to make sure it can generate docs without dying
# @haddocktest:
#     (make --quiet haddock && echo $@ PASSED) || (echo $@ FAILED; false)
# # run cabal check to test cabal file syntax
# cabalfiletest:
#     @(make --no-print-directory cabalcheck && echo $@ PASSED) || (echo $@ FAILED; false)
# test-stack%yaml:
#     $STACK --stack-yaml stack$*yaml clean
#     $STACK --stack-yaml stack$*yaml build --ghc-options="{{ WARNINGS }} -Werror" --test --bench --haddock --no-haddock-deps
# committest: hlinttest unittest doctest functest haddocktest buildtest quickcabaltest \
#
# releasetest: Clean unittest functest fullcabaltest haddocktest #buildtest doctest \
#     {{ call def-help,releasetest,pre-release tests }}

# run hledger-install.sh not from inside a haskell project
installtest:
    cd; {{ justfile_directory() }}/hledger-install/hledger-install.sh

# ** Installing ------------------------------------------------------------
INSTALLING:

# # copy the current ~/.local/bin/hledger to bin/old/hledger-VER
# @copy-as VER:
#     cp ~/.local/bin/hledger bin/old/hledger-{{ VER }}; echo "bin/hledger-{{ VER }}"

# stack install, then copy the hledger executables to bin/old/hledger*-VER
@installas VER:
    $STACK install --local-bin-path bin/old
    for e in hledger hledger-ui hledger-web ; do cp bin/old/$e bin/old/$e-{{ VER }}; echo "bin/$e-{{ VER }}"; done

# # make must be GNU Make 4.3+
# .PHONY: shellcompletions
# # update shell completions in hledger package
# shellcompletions:
#     make -C hledger/shell-completion/ clean-all all

# download a recent set of hledger versions from github releases to bin/hledger-VER
get-binaries:
    for V in 1.32.2 1.31 1.30 1.29.2 1.28 1.27.1; do just get-binary $OS x64 $V; done
    just symlink-binaries

# download hledger version VER for OS (linux, mac windows) and ARCH (x64) from github releases to bin/hledger-VER

# On gnu/linux: can't interpolate GTAR here for some reason, and need the shebang line.
get-binary OS ARCH VER:
    #!/usr/bin/env bash
    cd bin && curl -Ls https://github.com/simonmichael/hledger/releases/download/{{ VER }}/hledger-{{ OS }}-{{ ARCH }}.zip | funzip | `type -P gtar || echo tar` xf - hledger --transform 's/$/-{{ VER }}/'

# add easier symlinks for all the minor hledger releases downloaded by get-binaries.
symlink-binaries:
    just symlink-binary 1.32.2
    just symlink-binary 1.29.2
    just symlink-binary 1.27.1

# add an easier symlink for this minor hledger release (hledger-1.29 -> hledger-1.29.2, etc.)
@symlink-binary MINORVER:
    cd bin && ln -sf hledger-$MINORVER hledger-`echo $MINORVER | sed -E 's/\.[0-9]+$//'`

# sym-link some directories required by hledger-web dev builds
symlink-web-dirs:
    echo "#ln -sf hledger-web/config  # disabled, causes makeinfo warnings"
    ln -sf hledger-web/messages
    ln -sf hledger-web/static
    ln -sf hledger-web/templates

# ** Benchmarking ------------------------------------------------------------
BENCHMARKING:

# generate standard sample journals in examples/
samplejournals:
    # small journals
    tools/generatejournal 3 5 5            > examples/ascii.journal
    tools/generatejournal 3 5 5 --mixed    > examples/mixed.journal
    tools/generatejournal 1 1 10           > examples/1txns-1accts.journal
    tools/generatejournal 10 10 10         > examples/10txns-10accts.journal
    tools/generatejournal 100 100 10       > examples/100txns-100accts.journal
    # many transactions
    tools/generatejournal 1000    1000 10  > examples/1ktxns-1kaccts.journal
    tools/generatejournal 2000    1000 10  > examples/2ktxns-1kaccts.journal
    tools/generatejournal 3000    1000 10  > examples/3ktxns-1kaccts.journal
    tools/generatejournal 4000    1000 10  > examples/4ktxns-1kaccts.journal
    tools/generatejournal 5000    1000 10  > examples/5ktxns-1kaccts.journal
    tools/generatejournal 6000    1000 10  > examples/6ktxns-1kaccts.journal
    tools/generatejournal 7000    1000 10  > examples/7ktxns-1kaccts.journal
    tools/generatejournal 8000    1000 10  > examples/8ktxns-1kaccts.journal
    tools/generatejournal 9000    1000 10  > examples/9ktxns-1kaccts.journal
    tools/generatejournal 10000   1000 10  > examples/10ktxns-1kaccts.journal
    tools/generatejournal 20000   1000 10  > examples/20ktxns-1kaccts.journal
    tools/generatejournal 30000   1000 10  > examples/30ktxns-1kaccts.journal
    tools/generatejournal 40000   1000 10  > examples/40ktxns-1kaccts.journal
    tools/generatejournal 50000   1000 10  > examples/50ktxns-1kaccts.journal
    tools/generatejournal 60000   1000 10  > examples/60ktxns-1kaccts.journal
    tools/generatejournal 70000   1000 10  > examples/70ktxns-1kaccts.journal
    tools/generatejournal 80000   1000 10  > examples/80ktxns-1kaccts.journal
    tools/generatejournal 90000   1000 10  > examples/90ktxns-1kaccts.journal
    tools/generatejournal 100000  1000 10  > examples/100ktxns-1kaccts.journal
    tools/generatejournal 1000000 1000 10  > examples/1Mtxns-1kaccts.journal
    # many accounts
    tools/generatejournal 1000 1 10        > examples/1ktxns-1accts.journal
    tools/generatejournal 1000 10 10       > examples/1ktxns-10accts.journal
    tools/generatejournal 1000 100 10      > examples/1ktxns-100accts.journal
    #tools/generatejournal 1000 1000 10    > examples/1ktxns-1kaccts.journal
    tools/generatejournal 1000 10000 10    > examples/1ktxns-10kaccts.journal
    tools/generatejournal 1000 100000 10   > examples/1ktxns-100kaccts.journal
    tools/generatejournal 1000 1000000 10  > examples/1ktxns-1maccts.journal
    tools/generatejournal 10000 1 10       > examples/10ktxns-1accts.journal
    tools/generatejournal 10000 10 10      > examples/10ktxns-10accts.journal
    tools/generatejournal 10000 100 10     > examples/10ktxns-100accts.journal
    #tools/generatejournal 10000 1000 10   > examples/10ktxns-1kaccts.journal
    tools/generatejournal 10000 10000 10   > examples/10ktxns-10kaccts.journal
    tools/generatejournal 10000 20000 10   > examples/10ktxns-20kaccts.journal
    tools/generatejournal 10000 30000 10   > examples/10ktxns-30kaccts.journal
    tools/generatejournal 10000 40000 10   > examples/10ktxns-40kaccts.journal
    tools/generatejournal 10000 50000 10   > examples/10ktxns-50kaccts.journal
    tools/generatejournal 10000 60000 10   > examples/10ktxns-60kaccts.journal
    tools/generatejournal 10000 70000 10   > examples/10ktxns-70kaccts.journal
    tools/generatejournal 10000 80000 10   > examples/10ktxns-80kaccts.journal
    tools/generatejournal 10000 90000 10   > examples/10ktxns-90kaccts.journal
    tools/generatejournal 10000 100000 10  > examples/10ktxns-100kaccts.journal
    tools/generatejournal 10000 1000000 10 > examples/10ktxns-1maccts.journal

# The current OS name, in the form used for hledger release binaries: linux, mac, windows or other.
# can't use $GHC or {{GHC}} here for some reason

OS := `ghc -ignore-dot-ghci -package-env - -e 'import System.Info' -e 'putStrLn $ case os of "darwin"->"mac"; "mingw32"->"windows"; "linux"->"linux"; _->"other"'`

#    tools/generatejournal.hs 3 5 5 --chinese > examples/chinese.journal  # don't regenerate, keep the simple version
# $ just --set BENCHEXES ledger,hledger  bench

# run the benchmark commands in bench.sh with quickbench. Eg: just bench -h; just bench -f bench10k.sh -w hledger-1.30,hledger-1.31,hledger-1.32 -n2 -N2
@bench *ARGS:
    printf "Running quick benchmarks (times are approximate, can be skewed):\n"
    which quickbench >/dev/null && quickbench {{ ARGS }} || echo "quickbench not installed (see bench.sh), skipping"

# @bench-gtime:
#     for args in '-f examples/10ktxns-1kaccts.journal print' '-f examples/100ktxns-1kaccts.journal register' '-f examples/100ktxns-1kaccts.journal balance'; do \
#     echo; \
#     for app in hledger-1.26 hledger-21ad ledger; do \
#     echo; echo $app $args:; \
#     gtime $app $args >/dev/null; \
#     done; \
#     done

# show throughput at various data sizes with the given hledger executable (requires samplejournals)
@bench-throughput EXE:
    echo date:       `date`
    echo system:     `uname -a`
    echo executable: {{ EXE }}
    echo version:    `{{ EXE }} --version`
    for n in 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 100000 ; do \
        printf "%6d txns: " $n; {{ EXE }} stats -f examples/${n}x1000x10.journal | tail -1; \
    done
    date

# show throughput at various data sizes with the latest hledger dev build, optimised or not (requires samplejournals)
@bench-throughput-dev:
    stack build hledger
    stack exec -- just throughput hledger

# show throughput of recent hledger versions (requires samplejournals)
@bench-throughput-recent:
    for v in 1.25 1.28 1.29 1.32 1.32.3; do printf "\nhledger-$v:\n"; for i in `seq 1 3`; do hledger-$v -f examples/10ktxns-10kaccts.journal stats | grep throughput; done; done

# @bench-balance-many-accts:
#     quickbench -w hledger-1.26,hledger-21ad,ledger -f bench-many-accts.sh -N2
#     #quickbench -w hledger-1.25,hledger-1.28,hledger-1.29,hledger-1.30,hledger-1.31,hledger-1.32,hledger-21ad,ledger -f bench-many-accts.sh -N2
# @bench-balance-many-txns:
#     quickbench -w hledger-21ad,ledger -f bench-many-txns.sh -N2
# samplejournals bench.sh
# bench: samplejournals tests/bench.tests tools/simplebench \
# 	$(call def-help,bench,\
# 	run simple performance benchmarks and archive results\
# 	Requires some commands defined in tests/bench.tests and some BENCHEXES defined above.\
# 	)
# 	tools/simplebench -v -ftests/bench.tests $(BENCHEXES) | tee doc/profs/$(TIME).bench
# 	@rm -f benchresults.*
# 	@(cd doc/profs; rm -f latest.bench; ln -s $(TIME).bench latest.bench)
# criterionbench: samplejournals tools/criterionbench \
# 	$(call def-help,criterionbench,\
# 	run criterion benchmark tests and save graphical results\
# 	)
# 	tools/criterionbench -t png -k png
# progressionbench: samplejournals tools/progressionbench \
# 	$(call def-help,progressionbench,\
# 	run progression benchmark tests and save graphical results\
# 	)
# 	tools/progressionbench -- -t png -k png
# # prof: samplejournals \
# # 	$(call def-help,prof,\
# # 	generate and archive an execution profile\
# # 	) #bin/hledgerprof
# # 	@echo "Profiling: $(PROFCMD)"
# # 	-$(PROFCMD) +RTS $(PROFRTSFLAGS) -RTS
# # 	mv hledgerprof.prof doc/profs/$(TIME).prof
# # 	(cd doc/profs; rm -f latest*.prof; ln -s $(TIME).prof latest.prof)
# # viewprof: prof \
# # 	$(call def-help,viewprof,\
# # 	generate, archive, simplify and display an execution profile\
# # 	)
# # 	tools/simplifyprof.hs doc/profs/latest.prof
# quickprof-%: hledgerprof samplejournals \
# 		$(call def-help,quickprof-"CMD", run some command against a standard sample journal and display the execution profile )
# 	$(STACK) exec --profile -- hledger +RTS $(PROFRTSFLAGS) -RTS $* -f examples/1000x1000x10.journal >/dev/null
# 	profiterole hledger.prof
# 	@echo
# 	@head -20 hledger.prof
# 	@echo ...
# 	@echo
# 	@head -20 hledger.profiterole.txt
# 	@echo ...
# 	@echo
# 	@echo "See hledger.prof, hledger.profiterole.txt, hledger.profiterole.html for more."
# # heap: samplejournals \
# # 	$(call def-help,heap,\
# # 	generate and archive a graphical heap profile\
# # 	) #bin/hledgerprof
# # 	@echo "Profiling heap with: $(PROFCMD)"
# # 	$(PROFCMD) +RTS -hc -RTS
# # 	mv hledgerprof.hp doc/profs/$(TIME).hp
# # 	(cd doc/profs; rm -f latest.hp; ln -s $(TIME).hp latest.hp; \
# # 		hp2ps $(TIME).hp; rm -f latest.ps; ln -s $(TIME).ps latest.ps; rm -f *.aux)
# # viewheap: heap \
# # 	$(call def-help,viewheap,\
# # 	\
# # 	)
# # 	$(VIEWPS) doc/profs/latest.ps
# quickheap-%: hledgerprof samplejournals \
# 		$(call def-help,quickheap-"CMD", run some command against a sample journal and display the heap profile )
# 	$(STACK) exec -- hledgerprof +RTS -hc -RTS $* -f examples/10000x1000x10.journal >/dev/null
# 	hp2ps hledgerprof.hp
# 	@echo generated hledgerprof.ps
# 	$(VIEWPS) hledgerprof.ps
# # quickcoverage: hledgercov \
# # 	$(call def-help,quickcoverage,\
# # 	display a code coverage text report from running hledger COVCMD\
# # 	)
# # 	@echo "Generating code coverage text report for hledger command: $(COVCMD)"
# # 	tools/runhledgercov "report" $(COVCMD)
# # coverage: samplejournals hledgercov \
# # 	$(call def-help,coverage,\
# # 	generate a code coverage html report from running hledger COVCMD\
# # 	)
# # 	@echo "Generating code coverage html report for hledger command: $(COVCMD)"
# # 	tools/runhledgercov "markup --destdir=doc/profs/coverage" $(COVCMD)
# # 	cd doc/profs/coverage; rm -f index.html; ln -s hpc_index.html index.html
# # viewcoverage: \
# # 	$(call def-help,viewcoverage,\
# # 	view the last html code coverage report\
# # 	)
# # 	$(VIEWHTML) doc/profs/coverage/index.html

# ** Documenting ------------------------------------------------------------
DOCUMENTING:

# see also Shake.hs
# http://www.haskell.org/haddock/doc/html/invoking.html

STACKHADDOCK := 'time ' + STACK + ' --verbosity=error haddock --fast --no-keep-going \
    --only-locals --no-haddock-deps --no-haddock-hyperlink-source \
    --haddock-arguments="--no-warnings" \
    '

# -ghc-options='-optP-P'  # workaround for http://trac.haskell.org/haddock/ticket/284

HADDOCKPKGS := 'hledger-lib'

# regenerate haddock docs for the hledger packages and open them
haddock:
    {{ STACKHADDOCK }} {{ HADDOCKPKGS }}
    just haddock-open   # --open shows all deps and packages

# # Rerenders all hledger packages. Run make haddock-open to open contents page.
# haddock-watch1: \
#     $(call def-help,haddock-watch, regenerate haddock docs when files change )
#     $(STACKHADDOCK) $(HADDOCK_PKGS) --file-watch --exec='echo done'
# # Rerenders hledger-lib modules, opens hledger-lib contents page.
# haddock-watch2: \
#     $(call def-help,haddock-watch2, regenerate hledger-lib haddock docs when files change )
#     watchexec -r -e yaml,cabal,hs --print-events -- \
#     $(STACKHADDOCK) --verbosity=info $(HADDOCK_PKGS) --exec="'echo done'" hledger-lib --open
# # Rerenders/reopens the Hledger module, without submodules. (Fastest)
# haddock-watch: \
#     $(call def-help,haddock-watch3, quickly regenerate & reload Hledger.hs haddock when files change )
#     watchexec -r -e yaml,cabal,hs --print-events --shell=none -- bash -c 'mkdir -p tmp && rm -f tmp/Hledger.html && haddock -h -o tmp hledger-lib/Hledger.hs --no-warnings --no-print-missing-docs 2>&1 | grep -v "Could not find documentation" && open tmp/Hledger.html'

# open the haddock packages contents page in a browser
haddock-open:
    {{ BROWSE }} `$STACK path --local-install-root`/doc/index.html

# hoogle-setup: $(call def-help,hoogle-setup, install hoogle then build haddocks and a hoogle db for the project and all deps )
#     stack hoogle --rebuild
# HOOGLEBROWSER="/Applications/Firefox Dev.app/Contents/MacOS/firefox"   # safari not supported
# hoogle-serve: $(call def-help,hoogle-serve, run hoogle web app and open in browser after doing setup if needed )
#     $(HOOGLEBROWSER) http://localhost:8080 &
#     stack --verbosity=warn hoogle --server
# # sourcegraph: \
# #     $(call def-help,sourcegraph,\
# #     \
# #     )
# #     for p in $(PACKAGES); do (cd $$p; SourceGraph $$p.cabal); done
# manuals-watch: Shake \
#         $(call def-help,manuals-watch, rerender manuals when their source files change  )
#     ls $(DOCSOURCEFILES) | entr ./Shake -VV manuals
# man-watch: man-watch-hledger \
#         $(call def-help,man-watch, run man on the hledger man page when its source file changes )
# man-watch-%: Shake \
#         $(call def-help,man-watch-PROG, run man on the given man page when its source file changes. Eg make man-watch-hledger-web )
#     $(WATCHEXEC) -r -w $*/$*.m4.md './Shake $*/$*.1 && man $*/$*.1'
# shakehelp-watch: \
#         $(call def-help,shakehelp-watch, rerender Shake.hs's help when it changes)
#     ls Shake.hs | entr -c ./Shake.hs
# # The following rule, for updating the website, gets called on hledger.org by:
# # 1. github-post-receive (github webhook handler), when something is pushed
# #    to the main or wiki repos on Github. Config:
# #     /etc/supervisord.conf -> [program:github-post-receive]
# #     /etc/github-post-receive.conf
# # 2. cron, nightly. Config: /etc/crontab
# # 3. manually: "make site" on hledger.org, or "make hledgerorg" elsewhere (cf Makefile.local).
# .PHONY: site
# # Use the existing Shake executable without recompiling it, so as not to automatially run unreviewed code by hook ? I think this no longer applies.
# # site: $(call def-help,site-build, update the hledger.org website (run this on hledger.org, or run "make hledgerorg" elsewhere) )
# #     @[ ! -x Shake ] \
# #         && echo 'Please run "make Shake" first (manual compilation required for safety)' \
# #         || ( \
# #             echo; \
# #             ./Shake -V site; \
# #         ) 2>&1 | tee -a site.log
# site: Shake \
#     $(call def-help,site, update the hledger.org website (run on hledger.org, or run "make hledgerorg" elsewhere) )
#     ./Shake -V site 2>&1 | tee -a site.log
# BROWSE=open
# BROWSEDELAY=5
# LOCALSITEURL=http://localhost:3000/dev/hledger.html
# site-watch: $(call def-help,site-watch, open a browser on the website (in ./site) and rerender when docs or web pages change )
#     @make -s Shake
#     @(printf "\nbrowser will open in $(BROWSEDELAY)s (adjust BROWSE in Makefile if needed)...\n\n"; sleep $(BROWSEDELAY); $(BROWSE) $(LOCALSITEURL)) &
#     @$(WATCHEXEC) --print-events -e md,m4 -i hledger.md -i hledger-ui.md -i hledger-web.md -r './Shake webmanuals && ./Shake orgfiles && make -sC site serve'

# optimise and commit RELEASING value map diagram
@releasediag:
    pngquant doc/HledgerReleaseValueMap.png -f -o doc/HledgerReleaseValueMap.png
    git add doc/HledgerReleaseValueMap.png
    git commit -m ';doc: RELEASING: update value map' -- doc/HledgerReleaseValueMap.png

# Convert DATEARG to an ISO date. It can be an ISO date, number of recent days, or nothing (meaning last release date).
@_datearg *DATEARG:
    echo {{ if DATEARG == '' { `just reldate` } else { if DATEARG =~ '^\d+$' { `dateadd $(date +%Y-%m-%d) -$DATEARG` } else { DATEARG } } }}

# Show activity since (mostly) this date or days ago or last release. Eg: just log > log.org
log *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    printf "* Activity since $DATE:\n\n"
    printf "Last release: `just rel`\n\n"
    just chlog
    just commitlog $DATEARG
    just timelog   $DATEARG
    just worklog   $DATEARG
    just chatlog   $DATEARG
    just maillog   $DATEARG
    just redditlog $DATEARG
    just tootlog   $DATEARG
    just bloglog
    echo "News url will be (if this is friday): https://hledger.org/news.html#this-week-in-hledger-"`date -I`

CHANGELOGS := 'CHANGES.md hledger/CHANGES.md hledger-ui/CHANGES.md hledger-web/CHANGES.md hledger-lib/CHANGES.md'

# Show changes since last release in the given CHANGES.md file or all of them. (Run after ./Shake changelogs.)
chlog *CHANGELOG:
    #!/usr/bin/env osh
    if [[ -z $CHANGELOG ]]; then
        for CHANGELOG in $CHANGELOGS; do
            printf "** $CHANGELOG\n\n"
            just chlog $CHANGELOG
            echo
        done
    else
        awk '/^#+ /{p=1};/^#+ +[0-9]+\.[0-9].*([0-9]{4}-[0-9]{2}-[0-9]{2})/{exit};p' $CHANGELOG
    fi

GITSHORTFMT := "--format='%ad %h %s' --date=short"

# Show commits in the three repos since this date or days ago or last release, briefly.
commitlog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    printf "** hledger commits\n\n"
    git log {{ GITSHORTFMT }} --since $DATE
    echo
    printf "** hledger_site commits\n\n"
    git -C site log {{ GITSHORTFMT }} --since $DATE
    echo
    printf "** hledger_finance commits\n\n"
    git -C finance log {{ GITSHORTFMT }} --since $DATE
    echo
    printf "** plaintextaccounting.org commits\n\n"
    git -C ../plaintextaccounting.org log {{ GITSHORTFMT }} --since $DATE
    echo

# Show hledger-related time logged since this date or days ago or last release
timelog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    printf "** Time log\n\n"
    hledger -f $TIMELOG print hledger -b $DATE | rg '^2|hledger'
    echo
    hledger -f $TIMELOG bal -S hledger -b $DATE -e tomorrow
    echo

WORKLOG := "../../notes/CLOUD/hledger.md"

# Show dates logged in hledger work log.
@worklogdates:
    awk "/^## Log/{p=1;next};/^## /{p=0};p" $WORKLOG | rg '^#### (\d{4}-\d{2}-\d{2})' -or '$1'

# Show hledger work logged since this date or days ago or last release
worklog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    WORKDATE=`just worklogdates | $GHC -e "getContents >>= putStrLn . head . dropWhile (< \"$DATE\") . (++[\"9999-99-99\"]) . lines"`
    printf "** Work log\n"
    awk "/^#### $WORKDATE/{p=1;print;next};/^## /{p=0};p" $WORKLOG
    echo

# Copy some text to the system clipboard if possible
@clip TEXT:
    type -P pbcopy >/dev/null && (printf "$TEXT" | pbcopy)

# Show matrix chat since this date or days ago or last release
chatlog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    JUMP="/jumptodate $DATE"
    just clip "$JUMP"
    echo "** matrix:    https://matrix.hledger.org, $JUMP"
    echo

# Show mail list discussion since this date or days ago or last release
maillog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    DATE2=`$GDATE -d $DATE +"%b %-d"`
    echo "** mail list: https://list.hledger.org, since $DATE2 ($DATE)"
    echo

# Show /r/plaintextaccounting posts since this date or days ago or last release
redditlog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    DAYS=`datediff $DATE now`
    echo "** reddit:    https://www.reddit.com/r/plaintextaccounting/new, since $DAYS days ago ($DATE)"
    echo

# Show #hledger-tagged mastodon toots since this date or days ago or last release
tootlog *DATEARG:
    #!/usr/bin/env osh
    DATE=`just _datearg $DATEARG`
    just clip "#hledger after:$DATE"
    echo "** mastodon:  https://fosstodon.org/search, #hledger after:$DATE , #plaintextaccounting after:$DATE"
    echo

# Show recent PTA blog posts added on plaintextaccounting.org
bloglog:
    #!/usr/bin/env osh
    # DATE=`just _datearg $DATEARG`
    echo "** pta.o:  https://plaintextaccounting.org/#`date +%Y`"
    echo

# # Some evil works against this..
# #     echo "open https://www.reddit.com/r/plaintextaccounting/new, copy links since $DAYS days ago ($DATE), paste into obsidian, select, cut, and paste here for cleaning (in emacs shell use C-c C-d, C-c C-r)"
# #     just redditclean > $$.tmp
# #     printf "\n\n\n\n\n"
# #     cat $$.tmp
# #     rm -f $$.tmp
# #
# # Clean links copied from old.reddit.com.
# @redditclean:
#     rg '^(\[.*?]\([^\)]+\)).*self.plaintextaccounting' -or '- $1\n' -

# ** Releasing ------------------------------------------------------------
RELEASING:

# Symlink/copy important files temporarily in .relfiles/.
relfiles:
    #!/usr/bin/env bash
    echo "linking/copying important release files in .relfiles/ for convenient access..."
    mkdir -p .relfiles
    cd .relfiles
    for f in \
        ../stack.yaml \
        ../Shake.hs \
        ../hledger-install/hledger-install.sh \
        ../CHANGES.md \
        ../hledger/CHANGES.md \
        ../hledger-ui/CHANGES.md \
        ../hledger-web/CHANGES.md \
        ../hledger-lib/CHANGES.md \
        ../doc/github-release.md \
        ../doc/ANNOUNCE \
        ../doc/ANNOUNCE.masto \
        ../site/src/release-notes.md \
        ../site/src/install.md \
    ; do ln -sf $f .; done
    cp ../doc/RELEASING.md ./RELEASING2.md   # temp copy which can be edited without disruption

# Prepare to release today, creating/switching to release branch and doing routine updates - versions, dates, manuals, command helps
relprep VER:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -z {{ VER }} ]] && usage
    BRANCH=$(just _versionReleaseBranch {{ VER }})
    COMMIT="-c"
    echo "Switching to $BRANCH, auto-creating it if needed..."
    just _gitSwitchAutoCreate "$BRANCH"
    echo "Bumping all version strings to {{ VER }} ..."
    ./Shake setversion {{ VER }} $COMMIT
    echo "Updating all command help texts for embedding..."
    ./Shake cmdhelp $COMMIT
    echo "Updating all dates in man pages..."
    ./Shake mandates
    echo "Generating all the manuals in all formats...."
    ./Shake manuals $COMMIT
    # echo "Updating CHANGES.md files with latest commits..."
    # ./Shake changelogs $COMMIT

# Push the current branch to github to generate release binaries.
@relbin:
    # assumes the github remote is named "github"
    git push -f github HEAD:binaries

# Show last release date (of hledger package).
@reldate:
    awk '/^#+ +[0-9]+\.[0-9].*([0-9]{4}-[0-9]{2}-[0-9]{2})/{print $3;exit}' hledger/CHANGES.md

# Show last release date and version (of hledger package).
@rel:
    just rels | head -1

# Show all release dates and versions (of hledger package).
@rels:
    awk '/^#+ +[0-9]+\.[0-9].*([0-9]{4}-[0-9]{2}-[0-9]{2})/{printf "%s %s\n",$3,$2}' hledger/CHANGES.md

# *** hledger version number helpers
# (as hidden recipes, since just doesn't support global custom functions)
# See doc/RELEASING.md > Glossary.

# First 0-2 parts of a dotted version number.
@_versionMajorPart VER:
    echo {{ replace_regex(VER, '(\d+(\.\d+)?).*', '$1') }}

# Third part of a dotted version number, if any.
@_versionMinorPart VER:
    echo {{ if VER =~ '\d+(\.\d+){2,}' { replace_regex(VER, '\d+\.\d+\.(\d+).*', '$1') } else { '' } }}

# Fourth part of a dotted version number, if any.
@_versionFourthPart VER:
    echo {{ if VER =~ '\d+(\.\d+){3,}' { replace_regex(VER, '\d+(\.\d+){2}\.(\d+).*', '$2') } else { '' } }}

# Does this dotted version number have a .99 third part and no fourth part ?
@_versionIsDev VER:
    echo {{ if VER =~ '(\d+\.){2}99$' { 'y' } else { '' } }}

# Does this dotted version number have a .99 third part and a fourth part ?
@_versionIsPreview VER:
    echo {{ if VER =~ '(\d+\.){2}99\.\d+' { 'y' } else { '' } }}

# Increment a major version number to the next.
# @majorVersionIncrement MAJORVER:
#     python3 -c "print({{MAJORVER}} + 0.01)"

# Appropriate release branch name for the given version number.
_versionReleaseBranch VER:
    #!/usr/bin/env bash
    MAJOR=$(just _versionMajorPart {{ VER }})
    if [[ $(just _versionIsDev {{ VER }}) == y ]] then
      echo "{{ VER }} is not a releasable version" >&2
      exit 1
    elif [[ $(just _versionIsPreview {{ VER }}) == y ]] then
      # echo "$(just majorVersionIncrement "$MAJOR")-branch"
      echo "{{ VER }} is not a releasable version" >&2
      exit 1
    else
      echo "$MAJOR-branch"
    fi

# *** git helpers

# Does the named branch exist in this git repo ?
@_gitBranchExists BRANCH:
    git branch -l {{ BRANCH }} | grep -q {{ BRANCH }}

# Switch to the named git branch, creating it if it doesn't exist.
_gitSwitchAutoCreate BRANCH:
    #!/usr/bin/env bash
    if just _gitBranchExists {{ BRANCH }}; then
      git switch {{ BRANCH }}
    else
      git switch -c {{ BRANCH }}
    fi

# # old/desired release process:
# #  a normal release: echo 0.7   >.version; make release
# #  a bugfix release: echo 0.7.1 >.version; make release
# #release: releasetest bumpversion tagrelease $(call def-help,release, prepare and test a release and tag the repo )
# #publish: hackageupload pushtags $(call def-help,upload, publish latest hackage packages and push tags to github )
# #releaseandpublish: release upload $(call def-help,releaseandpublish, release and upload and publish updated docs )
# ISCLEAN=git diff-index --quiet HEAD --
# # stop if the working directory has uncommitted changes
# iscleanwd:
#     @$(ISCLEAN) || (echo "please clean the working directory first"; false)
# # stop if the given file(s) have uncommitted changes
# isclean-%:
#     @$(ISCLEAN) $* || (echo "please clean these files first: $*"; false)
# # update all cabal files based on latest package.yaml files using stack's built-in hpack
# cabal: $(call def-help,cabal, regenerate cabal files from package.yaml files with stack )
#     $(STACK) build --dry-run --silent
# # Update all cabal files based on latest package.yaml files using a specific hpack version.
# # To avoid warnings, this should be the same version as stack's built-in hpack.
# cabal-with-hpack-%:
#     $(STACK) build --with-hpack hpack-$* --dry-run --silent
# # updatecabal: gencabal $(call def-help,updatecabal, regenerate cabal files and commit )
# #     @read -p "please review changes then press enter to commit $(shell ls */*.cabal)"
# #     git commit -m "update cabal files" $(shell ls */*.cabal)
# # we use shake for this job; so dependencies aren't checked here
# manuals: Shake $(call def-help,manuals, regenerate and commit CLI help and manuals (might need -B) )
#     ./Shake manuals
#     git commit -m ";doc: regen manuals" -m "[ci skip]" hledger*/hledger*.{1,5,info,txt} hledger/Hledger/Cli/Commands/*.txt
# tag: $(call def-help,tag, make git release tags for the project and all packages )
#     @for p in $(PACKAGES); do make tag-$$p; done
#     @make tag-project
# tag-%: $(call def-help,tag-PKG, make a git release tag for PKG )
#     git tag -fs $*-`cat $*/.version` -m "Release $*-`cat $*/.version`"
# tag-project: $(call def-help,tag-project, make a git release tag for the project as a whole )
#     git tag -fs `cat .version` -m "Release `cat .version`, https://hledger.org/release-notes.html#hledger-`cat .version | sed -e 's/\./-/g'`"
#     @printf "if tagging a major release, please also review and run this command:\n"
#     @printf " git tag -fs `cat .version`.99 master -m \"Start of next release cycle. This tag influences git describe and dev builds' version strings.\"\n"
# # hackageupload-dry: \
# #     $(call def-help,hackageupload-dry,\
# #     upload all packages to hackage; dry run\
# #     )
# #     for p in $(PACKAGES); do cabal upload $$p/dist/$$p-$(VERSION).tar.gz -v2 --check; done
# hackageupload: \
#     $(call def-help,hackageupload, upload all packages to hackage    from a release branch)
#     tools/hackageupload $(PACKAGES)
# # showreleasestats stats: \
# #     showreleasedays \
# #     showunreleasedchangecount \
# #     showloc \
# #     showtestcount \
# #     showunittestcoverage \
# #     showreleaseauthors \
# #     showunreleasedcodechanges \
# #     showunpushedchanges \
# #     $(call def-help,showreleasestats stats,\
# #     show project stats useful for release notes\
# #     )
# # #    showerrors
# # FROMTAG=.
# # showreleasedays: \
# #     $(call def-help,showreleasedays,\
# #     \
# #     )
# #     @echo Days since last release:
# #     @tools/dayssincetag.hs $(FROMTAG) | head -1 | cut -d' ' -f-1
# #     @echo
# # # XXX
# # showunreleasedchangecount: \
# #     $(call def-help,showunreleasedchangecount,\
# #     \
# #     )
# #     @echo Commits since last release:
# #     @darcs changes --from-tag $(FROMTAG) --count
# #     @echo

# show a precise git-describe version string
@describe:
    git describe --tags --match 'hledger-[0-9]*' --dirty

# show commit author names since last release
@authors-release:
    echo "Commit authors since last release:"
    git shortlog -sn `git tag --sort=-creatordate -l '[0-9]*' | head -1`..

# show all commit author names
@authors:
    echo "Commit authors ($(git shortlog -sn | wc -l | awk '{print $1}'))":
    git shortlog -sn

# show all commit author names and emails
@authorsv:
    echo "Commit authors ($(git shortlog -sn | wc -l | awk '{print $1}'))":
    git shortlog -sne

SCC := 'scc -z --cocomo-project-type semi-detached -f wide -s code'

# count lines of code with scc
scc:
    echo "Lines of code including tests:"
    {{ SCC }} -i hs,sh,m4,hamlet

# count lines of code with scc, showing all files
sccv:
    echo "Lines of code including tests:"
    {{ SCC }} -i hs,sh,m4,hamlet --by-file

# # `ls $(SOURCEFILES)`
# # sloc: \
# #     $(call def-help,sloc,\
# #     \
# #     )
# #     @sloccount hledger-lib hledger hledger-web
# # cloc: \
# #     $(call def-help,cloc,\
# #     \
# #     )
# #     @echo
# #     @echo "Lines of code as of `date`:"
# #     @echo
# #     @echo "hledger-lib, hledger"
# #     @cloc -q hledger-lib hledger             2>&1 | grep -v 'defined('
# #     @echo
# #     @echo "hledger-web"
# #     @cloc -q hledger-web                     2>&1 | grep -v 'defined('
# #     @echo
# #     @echo "hledger-lib, hledger, hledger-web"
# #     @cloc -q hledger-lib hledger hledger-web 2>&1 | grep -v 'defined('
# # showtestcount: \
# #     $(call def-help,showtestcount,\
# #     \
# #     )
# #     @echo "Unit tests:"
# #     @hledger test 2>&1 | cut -d' ' -f2
# #     @echo "Functional tests:"
# #     @make --no-print functest | egrep '^ Total' | awk '{print $$2}'
# #     @echo
# # showunittestcoverage: \
# #     $(call def-help,showunittestcoverage,\
# #     \
# #     )
# #     @echo Unit test coverage:
# #     @make --no-print quickcoverage | grep 'expressions'
# #     @echo
# # # showerrors:
# # #     @echo Known errors:
# # #     @awk '/^** errors/, /^** / && !/^** errors/' NOTES.org | grep '^\*\*\* ' | tail +1
# # #     @echo
# # # XXX
# # showunpushedchanges showunpushed: \
# #     $(call def-help,showunpushedchanges showunpushed,\
# #     \
# #     )
# #     @echo "Changes not yet pushed upstream (to `darcs show repo | grep 'Default Remote' | cut -c 17-`):"
# #     @-darcs push simon@joyful.com:/repos/hledger --dry-run | grep '*' | tac
# #     @echo
# # # XXX
# # showunreleasedcodechanges showunreleased showchanges: \
# #     $(call def-help,showunreleasedcodechanges showunreleased showchanges,\
# #     \
# #     )
# #     @echo "hledger code changes since last release:"
# #     @darcs changes --from-tag $(FROMTAG) --matches "not (name docs: or name doc: or name site: or name tools:)" | grep '*'
# #     @echo
# # # XXX
# # showcodechanges: \
# #     $(call def-help,showcodechanges,\
# #     \
# #     )
# #     @echo "hledger code changes:"
# #     @darcs changes --matches "not (name docs: or name site: or name tools:)" | egrep '^ +(\*|tagged)'
# #     @echo
# nix-hledger-version: $(call def-help,nix-hledger-version, show which version of hledger has reached nixpkgs)
#     @curl -s https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/haskell-modules/hackage-packages.nix | grep -A1 'pname = "hledger"'
# nix-hledger-versions: $(call def-help,nix-hledger-versions, show versions of all hledger packages in nixpkgs)
#     @curl -s https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/haskell-modules/hackage-packages.nix | grep -A1 'pname = "hledger'
# nix-view-commits: $(call def-help,nix-view-commits, show recent haskell commits in nixpkgs)
#     @open 'https://github.com/NixOS/nixpkgs/commits/master/pkgs/development/haskell-modules/hackage-packages.nix'
# list-commits: $(call def-help,list-commits, list all commits chronologically and numbered)
#     @git log --format='%ad %h %s (%an)' --date=short --reverse | cat -n

# ** Misc ------------------------------------------------------------
MISC:

# push to github CI, wait for tests to pass, refreshing every INTERVAL (default:10s), then push to master.
@push *INTERVAL:
    tools/push {{ INTERVAL }}

# run some tests to validate the development environment
# check-setup:
#     run some tests to validate the development environment\
#     )
#     @echo sanity-checking developer environment:
#     @({{ SHELLTEST }} checks \
#         && echo $@ PASSED) || echo $@ FAILED

# Show activity over the last N days (eg 7), for This Week In Hledger.
@_lastweek DAYS:
    echo "hledger time last $DAYS days including today (this should be run on a Friday):"
    tt bal hledger -DTS -b "$DAYS days ago" --drop 2
    echo
    echo "By activity type, percentage:"
    tt bal hledger -DTS -b "$DAYS days ago" --pivot t -% -c 1% | tail +1
    echo
    echo "Time log details:"
    tt print hledger -b "$DAYS days ago" | grep -E '^[^ ]|hledger'
    echo
    echo "main repo:"
    git log --format='%C(yellow)%cd %ad %Cred%h%Creset %s %Cgreen(%an)%Creset%C(bold blue)%d%Creset' --date=short --since="$DAYS days ago" --reverse
    echo
    echo "site repo:"
    git -C site log --format='%C(yellow)%cd %ad %Cred%h%Creset %s %Cgreen(%an)%Creset%C(bold blue)%d%Creset' --date=short --since="$DAYS days ago" --reverse
    echo
    echo "finance repo:"
    git -C finance log --format='%C(yellow)%cd %ad %Cred%h%Creset %s %Cgreen(%an)%Creset%C(bold blue)%d%Creset' --date=short --since="$DAYS days ago" --reverse
    echo

# show the sorted, unique files matched by SOURCEFILES
@_listsourcefiles:
    for f in $SOURCEFILES; do echo $f; done | sort | uniq

# show the sorted, unique subdirectories containing hs files
@_listsourcedirs:
    find . -name '*hs' | sed -e 's%[^/]*hs$%%' | sort | uniq

# show the ghc versions used by all stack files
@_listghcversions:
    for F in stack*.yaml; do $STACK --stack-yaml=$F --no-install-ghc exec -- ghc --version; done 2>&1 | grep -v 'To install the correct GHC'

# Show a bunch of debug messages.
@_dbgmsgs:
    rg --sort path -t hs 'dbg.*?(".*")' -r '$1' -o

# # Extract Hledger.hs examples to jargon.j.
# @_jargon:
#   rg '^ *> (.*)' -or '$1' hledger-lib/Hledger.hs > jargon.j
#   echo "wrote jargon.j"

# Extract ledger/hledger/beancount commit stats to project-commits.j.
@_projectcommits:
    # https://hledger.org/reporting-version-control-stats.html
    printf "account ledger\naccount hledger\naccount beancount\n\n" >project-commits.j
    for p in ledger hledger beancount; do git -C ../$p log --format="%cd (%h) %s%n  ($p)  1%n" --date=short --reverse >> project-commits.j; done
    echo "wrote project-commits.j"

# symlink tools/commitlint as .git/hooks/commit-msg
installcommithook:
    ln -s ../../tools/commitlint .git/hooks/commit-msg

# Shake: Shake.hs $(call def-help,Shake, ensure the Shake script is compiled )
#     ./Shake.hs

# show some big directory sizes
@usage:
    -du -sh .git bin data doc extra `find . -name '.stack*' -prune -o -name 'dist' -prune -o -name 'dist-newstyle' -prune` 2>/dev/null | sort -hr

# Files to include in emacs TAGS file:
# 1. haskell source files with hasktags -e (or ctags -aeR)
# 2. other source files recognised by (exuberant) ctags and not excluded by .ctags. Keep .ctags up to date.
# 3. some extra files missed by the above, as just their file names (for tags-search, tags-query-replace etc.)

TAGFILES := WEBTEMPLATEFILES + DOCSOURCEFILES + TESTFILES + HPACKFILES + CABALFILES + 'Shake.hs'

# generate emacs TAGS file for haskell source and other project files, and list the tagged files in TAGS.files
@etags:
    hasktags -e $SOURCEFILES
    for f in $TAGFILES; do printf "\n$f,1\n" >>TAGS; done

# list the files tagged in TAGS
@etags-ls:
    rg -v '[ ]' TAGS | rg -r '$1' '^(.*?([0-9]+)?),[0-9,]+*'

# remove TAGS files
@etags-clean:
    rm -f TAGS

# stackclean: \
#     $(call def-help-hide,stackclean, remove .stack-work/ dirs )
#     $(STACK) purge
# cleanghco: \
#     $(call def-help-hide,cleanghc, remove ghc build leftovers )
#     rm -rf `find . -name "*.o" -o -name "*.hi" -o -name "*.dyn_o" -o -name "*.dyn_hi" -o -name "*~" | grep -vE '\.(stack-work|cabal-sandbox|virthualenv)'`
# #rm -f `fd -I '\.(hi|o|dyn_hi|dyn_o)$'`
# clean: cleanghco \
#     $(call def-help,clean, default cleanup (ghc build leftovers) )
# Clean: stackclean cleanghco cleantags \
#     $(call def-help,Clean, thorough cleanup (stack/ghc leftovers/tags) )
# # reverse = $(if $(wordlist 2,2,$(1)),$(call reverse,$(wordlist 2,$(words $(1)),$(1))) $(firstword $(1)),$(1))
