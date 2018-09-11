#!/bin/bash

# To use this, first build the docker image and run this script in the container:
# docker build -t achilles .
# docker run -it -v `pwd`:/app -v /root/.elm achilles /app/dist.sh
#
# 

# make sure we are in a clean state 
mkdir -p /app/dist 
rm -rf /app/elm-stuff/*
rm -rf /app/dist/*

# compile and minify the Elm application bundle
cd /app && elm make src/Main.elm --output=/app/optimized.js --optimize
uglifyjs optimized.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=/app/dist/elm.js

# copy over other static assets
cp -r assets dist/assets
cp -r js dist/js

# finally drop in the index.html, but strip out the elm-live reload script line
sed '/livereload/d' index.html > dist/index.html
