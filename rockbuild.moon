-- rockbuild
-- Build rockspecs from YAML
-- By daelvn
import load                         from require "lyaml"
import block                        from require "serpent"
import exists, makeDir, glob, iglob from require "filekit"
import style                        from require "ansikit.style"
argparse                               = require "argparse"

args = {}
with argparse!
  \name        "rockbuild"
  \description "Compile YAML rockframes into Lua rockspecs"
  \epilog      "https://github.com/daelvn/rockbuild"

  \help_description_margin 28
  \require_command         false

  with \argument "version", "version for your rockspec"
    \args 1

  with \option "-p --prefix", "sets the prefix for the source tag"
    \default "v"
  with \option "-s --suffix", "sets the suffix for the source tag"
    \default ""
  with \option "-f --file", "rockframe location"
    \default "rock.yml"
  with \option "-d --dir", "rockspec output location"
    \default "rockspecs"
  \flag   "--dry",         "prints the resulting rockspec and does nothing else"
  \flag   "--delete",      "deletes the rockspec after using it"
  \option "-r --revision", "custom revision for the rockspec"
  \flag   "-m --make",     "runs 'luarocks make' after compiling the rockspec"
  \flag   "-t --tag",      "Adds a git tag after compiling the rockspec"

  \command "upload u", "uploads the rockspec after compile"

  args = \parse!

-- err & prefix
err = (txt) ->
  print style "%{red}!! #{txt}"
  os.exit 1
prefix = (pref) ->
  print style "%{magenta}==>%{reset} #{pref}"

-- reads the contents of a file
readfile = (file) ->
  return nil unless exists file
  local contents
  with io.open "#{file}", "r"
    contents = \read "*a"
    \close!
  return contents

-- writes the contents of a file
writefile = (file, contents) ->
  with io.open "#{file}", "w"
    \write contents
    \close!

-- check that rock.yml exists
err "#{args.file} not found." unless exists args.file

-- turns dumped table into a rockspec
torockspec = (txt) ->
  txt = txt\match "{\n(.+)\n}"
  fin = ""
  for line in txt\gmatch "[^\n]+"
    line  = (line\gsub "^  ", "")
    line  = (line\gsub "^},", "}")
    line  = (line\gsub "^([%w_]+ = \".-\"),$", "%1")
    fin ..= line .. "\n"
  return fin

-- start
version = args.version
print style "%{blue bold}rockbuild 1.0"
prefix "Using version %{green}'#{version}'"

-- load rockframe
prefix "Loading %{yellow}#{args.file}"
frame = load readfile args.file

-- get a revision number
args.revision or= 1 + #(glob "#{args.dir}/#{frame.package}-#{version}-*.rockspec")
verrev   = "#{version}-#{args.revision}"
prefix "Using revision %{green}'#{args.revision}'%{reset} (#{verrev})"

-- create package
prefix "Creating package..."
package = {
  rockspec_format: frame.format or "3.0"
  package:         frame.package or err "Expected package.name"
  version:         verrev
  
  description: frame.description
  
  supported_platforms:   frame.platforms
  dependencies:          frame.dependencies
  build_dependencies:    frame.dependencies and frame.dependencies.build    or nil 
  external_dependencies: frame.dependencies and frame.dependencies.external or nil

  source:
    url:    frame.source and frame.source.url  or err "Expected package.source"
    md5:    frame.source and frame.source.md5  or nil
    file:   frame.source and frame.source.file or nil
    dir:    frame.source and frame.source.dir  or nil
    tag:    "#{args.prefix}#{version}#{args.suffix}"
    branch: frame.source and frame.source.branch or nil
    module: frame.source and frame.source.module or nil

  build: frame.build
}

-- dump package
result = block package, comment: false
if args.dry
  print torockspec result
  os.exit!

-- write to file
path = "#{args.dir}/#{frame.package}-#{verrev}.rockspec"
prefix "Writing to %{yellow}#{path}"
makeDir args.dir unless exists "#{args.dir}/"
writefile path, torockspec result

-- run post-compile things
if args.tag
  prefix "Making Git tag %{yellow}#{args.prefix}#{version}#{args.suffix}"
  os.execute "git add -A"
  os.execute "git commit -m 'Producing rockspec #{verrev}'"
  os.execute "git tag -a #{args.prefix}#{version}#{args.suffix}"
if args.make
  prefix "Running 'luarocks make'"
  os.execute "luarocks make"
if args.upload
  prefix "Uploading rock %{yellow}#{path}"
  os.execute "luarocks upload #{path}"
  os.remove file for file in iglob "*.src.rock"
if args.delete
  prefix "Deleting #{path}"
  os.remove path