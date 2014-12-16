#!/bin/sh -e

. package/info

echo '#'
echo '# This file has been generated by tools/gen-deps.sh'
echo '#'
echo

for dir in src/include/${package} src/* ; do
  for file in $(ls -1 $dir | grep -- \\.h$) ; do
    {
      grep -F -- "#include <${package}/" < ${dir}/$file | cut -d'<' -f2 | cut -d'>' -f1 ;
      grep -- '#include ".*\.h"' < ${dir}/$file | cut -d'"' -f2
    } | sort -u | {
      deps=
      while read dep ; do
        if echo $dep | grep -q "^${package}/" ; then
          deps="$deps src/include/$dep"
        elif test -f "${dir}/$dep" ; then
          deps="$deps ${dir}/$dep"
        else
          deps="$deps src/include-local/$dep"
        fi
      done
      if test -n "$deps" ; then
        echo "${dir}/${file}:${deps}"
      fi
    }
  done
done

for dir in src/* ; do
  for file in $(ls -1 $dir | grep -- \\.c$) ; do
    {
      grep -F -- "#include <${package}/" < ${dir}/$file | cut -d'<' -f2 | cut -d'>' -f1 ;
      grep -- '#include ".*\.h"' < ${dir}/$file | cut -d'"' -f2
    } | sort -u | {
      deps=" ${dir}/$file"
      while read dep ; do
        if echo $dep | grep -q "^${package}/" ; then
          deps="$deps src/include/$dep"
        elif test -f "${dir}/$dep" ; then
          deps="$deps ${dir}/$dep"
        else
          deps="$deps src/include-local/$dep"
        fi
      done
      o=$(echo $file | sed s/\\.c$/.o/)
      lo=$(echo $file | sed s/\\.c$/.lo/)
      echo "${dir}/${o} ${dir}/${lo}:${deps}"
    }
  done
done
echo

for dir in $(ls -1 src | grep -v ^include) ; do
  for file in $(ls -1 src/$dir/deps-lib) ; do
    deps=
    while read dep ; do
      deps="$deps src/$dir/$dep"
    done < src/$dir/deps-lib/$file
    echo "lib$file.a: $deps"
    if test -x "src/$dir/deps-lib/$file" ; then
      echo "lib${file}.so: $(echo "$deps" | sed 's/\.o/.lo/g')"
    fi
  done

  for file in $(ls -1 src/$dir/deps-exe) ; do
    deps=
    libs=
    while read dep ; do
      if echo $dep | grep -q -- \\.o$ ; then
        dep="src/$dir/$dep"
      fi
      if echo $dep | grep -q ^\\\$ ; then
        libs="$libs $dep"
      else
        deps="$deps $dep"
      fi
    done < src/$dir/deps-exe/$file
    echo "$file: private EXTRA_LIBS :=$libs"
    echo "$file: src/$dir/$file.o$deps"
  done
done
