#!/usr/bin/env nu

use common.nu [get-env]

# Environment variable name for module directories, multiple directories should be separated by `;`
const LIB_ENV = 'NU_MODULE_DIRS'

def setup-nu-config [
  version: string,  # The tag name or version of the release to use.
] {
  let config_path = ($nu.env-path | path dirname)
  let config_prefix = $'https://github.com/nushell/nushell/blob/($version)/crates/nu-utils/src'
  aria2c $'($config_prefix)/sample_config/default_env.nu' -o env.nu -d $config_path
  aria2c $'($config_prefix)/sample_config/default_config.nu' -o config.nu -d $config_path
  config reset --without-backup
}

def-env setup-lib-dirs [] {
  print 'Current working dir: '
  print ($env.PWD)
  let module_dirs = ($env | get -i $LIB_ENV | default '' | str trim)
  'module_dirs: ' | print
  $module_dirs | print
  if ($module_dirs | is-empty) { return }
  let dirs = (
    $module_dirs
      | split row ';'
      | each {|p| ($p | str trim | path expand) }
      | filter {|p| ($p | path exists) }
  )
  let libs = ($env.NU_LIB_DIRS | append $dirs | str join ';')
  print 'Current NU_LIB_DIRS: '
  print $libs
  bash -c $'echo "NU_LIB_DIRS=($libs)" >> $GITHUB_ENV'

  open $nu.env-path | nu-highlight

  # open $nu.env-path
  #   | str replace -s 'let-env NU_LIB_DIRS = [' $'let-env NU_LIB_DIRS = [(char nl)($env.NU_LIB_DIRS | str join (char nl))'
  #   | save -f $nu.env-path
}

def main [
  version: string,  # The tag name or version of the release to use.
] {
  setup-nu-config $version
  setup-lib-dirs
}
