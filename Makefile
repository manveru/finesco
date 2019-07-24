#!/usr/bin/env bash

( echo site.hs | entr -n ghc --make site.hs & )
( echo site | entr -n -c -r './site clean && ./site watch' & )
( sass --scss --style compressed --load-path scss --watch scss:css )
