#! /bin/bash

read_name() {
  local version_file="$1"
  local workspace="$2"

  case $version_file in
  # Deno
  deno.jsonc)
    grep -E '^\s*"name"\s*:\s*["'\'']([^"'\'']+)["'\'']' $version_file |
      sed -E 's/^.*"name"\s*:\s*["'\'']([^"'\'']+)["'\''].*/\1/'
    ;;
  mod.ts)
    name=$(grep -E '^export\s+const\s+NAME\s*=' $version_file |
      sed -E 's/^export\s+const\s+NAME\s*=\s*["'\'']([^"'\'']+)["'\''];?/\1/')
    ;;
  version.ts)
    name=$(grep -E '^export\s+const\s+NAME\s*=' $version_file |
      sed -E 's/^export\s+const\s+NAME\s*=\s*["'\'']([^"'\'']+)["'\''];?/\1/')
    ;;
  # Generic
  name | NAME | name.txt | NAME.txt)
    name=$(cat $version_file)
    ;;
  # Go
  go.mod)
    name=$(sed -n 's/^module\s\+\([^ ]\+\)$/\1/p' $version_file)
    ;;
  # Node
  package.json)
    name=$(jq -r '.name' $version_file)
    ;;
  # Python
  __init__.py)
    name=$(grep -E '^__version__\s*=' $version_file |
      sed -E 's/^__version__\s*=\s*["'\'']([^"'\'']+)["'\'']/\1/')
    ;;
  setup.py)
    name=$(grep -E '^\s*name\s*=' $version_file |
      sed -E 's/^.*name\s*=\s*["'\'']([^"'\'']+)["'\''].*$/\1/')
    ;;
  pyproject.toml)
    name=$(grep -E '^\s*name\s*=' $version_file |
      sed -E 's/^name\s*=\s*["'\'']([^"'\'']+)["'\'']/\1/')
    ;;
  *)
    echo "::error:: Unsupported name file: $version_file"
    exit 1
    ;;
  esac

  echo ${name:-$workspace}
}

read_version() {
  local version_file="$1"

  case $version_file in
  # Deno
  deno.jsonc)
    grep -E '^\s*version\s*=' $version_file |
      sed -E 's/^version\s*=\s*["'\'']([^"'\'']+)["'\'']/\1/'
    ;;
  mod.ts)
    version=$(grep -E '^export\s+const\s+VERSION\s*=' $version_file |
      sed -E 's/^export\s+const\s+VERSION\s*=\s*["'\'']([^"'\'']+)["'\''];?/\1/')
    ;;
  version.ts)
    version=$(grep -E '^export\s+const\s+VERSION\s*=' $version_file |
      sed -E 's/^export\s+const\s+VERSION\s*=\s*["'\'']([^"'\'']+)["'\''];?/\1/')
    ;;
  # Generic
  version | VERSION | version.txt | VERSION.txt)
    version=$(cat $version_file)
    ;;
  # Go
  go.mod)
    version=$(sed -n 's/^module.*v\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\1/p' $version_file)
    ;;
  # Node
  package.json)
    version=$(cat $version_file | jq -r '.version')
    ;;
  # Python
  __init__.py)
    version=$(grep -E '^__version__\s*=' $version_file |
      sed -E 's/^__version__\s*=\s*["'\'']([^"'\'']+)["'\'']/\1/')
    ;;
  # pyproject.toml)
  #   version=$(grep -E '^\s*version\s*=' $version_file | sed -E 's/^version\s*=\s*["'\'']([^"'\'']+)["'\'']/\1/')
  #   ;;
  setup.py)
    version=$(grep -E '^\s*version\s*=' $version_file |
      sed -E 's/^.*version\s*=\s*["'\'']([^"'\'']+)["'\''].*$/\1/')
    ;;
  *)
    echo "::error:: Unsupported version file: $version_file"
    exit 1
    ;;
  esac

  echo ${version:-0.0.0}
}

write_version() {
  local version_file="$1"
  local version="$2"

  case $version_file in
  # Deno
  deno.jsonc)
    sed -i.bak "s/^version\s*=\s*['\"][^'\"]*['\"]/version = \"$version\"/" $version_file
    ;;
  mod.ts)
    sed -i.bak "s/^export\s\+const\s\+VERSION\s*=\s*['\"][^'\"]*['\"]/export const VERSION = \"$version\";/" $version_file
    ;;
  version.ts)
    sed -i.bak "s/^export\s\+const\s\+VERSION\s*=\s*['\"][^'\"]*['\"]/export const VERSION = \"$version\";/" $version_file
    ;;
  # Generic
  version | VERSION | version.txt | VERSION.txt)
    echo $version >$version_file
    ;;
  # Go
  go.mod)
    current_version=$(sed -n 's/^module.*v\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\1/p' $version_file)
    if [[ -n "$current_version" ]]; then
      cat $version_file | sed "s/v$current_version/v$version/" >$version_file.tmp
    else
      cat $version_file | sed "/^module/s/$/ v$version/" >$version_file.tmp
    fi
    cat $version_file.tmp >$version_file
    rm $version_file.tmp
    ;;
  package.json)
    cat $version_file | jq --arg new_version "$version" '.version = $new_version' >$version_file.tmp
    cat $version_file.tmp | jq -r '.' >$version_file
    rm $version_file.tmp
    ;;
  # Python
  __init__.py)
    sed -i.bak "s/^__version__\s*=\s*['\"][^'\"]*['\"]/__version__ = \"$version\"/" $version_file
    ;;
  # pyproject.toml)
  #   sed -i.bak "s/^version\s*=\s*['\"][^'\"]*['\"]/version = \"$version\"/" $version_file
  #   ;;
  setup.py)
    sed -i.bak "s/^\s*version\s*=\s*['\"][^'\"]*['\"]/    version='$version',/" $version_file
    ;;
  *)
    echo "::error:: Unsupported version file: $version_file"
    exit 1
    ;;
  esac
}
