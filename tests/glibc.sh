#!/usr/bin/env bash

# fix for github.com/NixOS/patchelf/issues/44
# test files from cprogramming.com/tutorial/shared-libraries-linux-gcc.html

cat >foo.h <<EOF
#ifndef foo_h__
#define foo_h__
extern void foo(void);
#endif  // foo_h__
EOF

cat >foo.c <<EOF
#include <stdio.h>
void foo(void)
{ puts("Hello, I'm a shared library"); }
EOF

cat >main.c <<EOF
#include <stdio.h>
#include "foo.h"
int main(void)
{
  puts("This is a shared library test...");
  foo(); return 0;
}
EOF
  
gcc -c -Wall -Werror -fpic foo.c
gcc -shared -o libfoo.so foo.o
gcc -L. -Wall -o test main.c -lfoo

readelf -l -S libfoo.so >raw_so
patchelf --debug --set-rpath "$(pwd):$(printf 'very_long_rpath%.0s' {1..50})" libfoo.so
readelf -l -S libfoo.so >mod_so

readelf -S libfoo.so | awk '$2 == ".dynstr" { print $1 }' >dyn_str
readelf -S libfoo.so | awk '$3 == "STRTAB" { print $1 }' >str_tab

sed -i 's,[][],,g' dyn_str
sed -i 's,[][],,g' str_tab
dyn=$(head -1 dyn_str)

while read n; do 
  if [ $n -lt $dyn ]; then
    echo 'ERROR: this test has failed !
1 (or more) STRTAB entry remains before .dynstr in the section headers'
    exit 1
  fi
done <str_tab

LD_LIBRARY_PATH=$(pwd) ./test
