#!/bin/sh
unset CFLAGS CXXFLAGS

# Only add -- to stop option parsing when the input file is an absolute path.
# CMake may pass /fo <outfile> <abs-input-path> and without -- Zig will treat
# the absolute source path as an option.
last_arg=""
for arg in "$@"; do
  last_arg="$arg"
done

if [ "${last_arg#/}" != "$last_arg" ] && [ -f "$last_arg" ]; then
  args=""
  for arg in "$@"; do
    if [ "$arg" = "$last_arg" ]; then
      break
    fi
    args="$args \"$arg\""
done
  eval "set -- $args -- \"$last_arg\""
fi

exec zig rc "$@"
