local load
load = require("lyaml").load
local block
block = require("serpent").block
local exists, makeDir, glob, iglob
do
  local _obj_0 = require("filekit")
  exists, makeDir, glob, iglob = _obj_0.exists, _obj_0.makeDir, _obj_0.glob, _obj_0.iglob
end
local style
style = require("ansikit.style").style
local argparse = require("argparse")
local VERSION = "1.1"
local args = { }
do
  local _with_0 = argparse()
  _with_0:name("rockbuild")
  _with_0:description("Compile YAML rockframes into Lua rockspecs")
  _with_0:epilog("https://github.com/daelvn/rockbuild")
  _with_0:help_description_margin(28)
  _with_0:require_command(false)
  do
    local _with_1 = _with_0:argument("version", "version for your rockspec")
    _with_1:args(1)
  end
  do
    local _with_1 = _with_0:option("-p --prefix", "sets the prefix for the source tag")
    _with_1:default("v")
  end
  do
    local _with_1 = _with_0:option("-s --suffix", "sets the suffix for the source tag")
    _with_1:default("")
  end
  do
    local _with_1 = _with_0:option("-f --file", "rockframe location")
    _with_1:default("rock.yml")
  end
  do
    local _with_1 = _with_0:option("-d --dir", "rockspec output location")
    _with_1:default("rockspecs")
  end
  _with_0:flag("--dry", "prints the resulting rockspec and does nothing else")
  _with_0:flag("--delete", "deletes the rockspec after using it")
  _with_0:option("-r --revision", "custom revision for the rockspec")
  _with_0:flag("-m --make", "runs 'luarocks make' after compiling the rockspec")
  _with_0:flag("-t --tag", "Adds a git tag after compiling the rockspec")
  do
    local _with_1 = _with_0:flag("-v --version", "Shows the current version")
    _with_1:action(function()
      print(VERSION)
      return os.exit()
    end)
  end
  _with_0:command("upload u", "uploads the rockspec after compile")
  args = _with_0:parse()
end
local err
err = function(txt)
  print(style("%{red}!! " .. tostring(txt)))
  return os.exit(1)
end
local prefix
prefix = function(pref)
  return print(style("%{magenta}==>%{reset} " .. tostring(pref)))
end
local readfile
readfile = function(file)
  if not (exists(file)) then
    return nil
  end
  local contents
  do
    local _with_0 = io.open(tostring(file), "r")
    contents = _with_0:read("*a")
    _with_0:close()
  end
  return contents
end
local writefile
writefile = function(file, contents)
  do
    local _with_0 = io.open(tostring(file), "w")
    _with_0:write(contents)
    _with_0:close()
    return _with_0
  end
end
if not (exists(args.file)) then
  err(tostring(args.file) .. " not found.")
end
local torockspec
torockspec = function(txt)
  txt = txt:match("{\n(.+)\n}")
  local fin = ""
  for line in txt:gmatch("[^\n]+") do
    line = (line:gsub("^  ", ""))
    line = (line:gsub("^},", "}"))
    line = (line:gsub("^([%w_]+ = \".-\"),$", "%1"))
    fin = fin .. (line .. "\n")
  end
  return fin
end
local extractDeps
extractDeps = function(dept)
  local clone
  do
    local _tbl_0 = { }
    for k, v in pairs(dept) do
      _tbl_0[k] = v
    end
    clone = _tbl_0
  end
  clone.build = nil
  clone.external = nil
  return clone
end
local version = args.version
print(style("%{blue bold}rockbuild " .. tostring(VERSION)))
prefix("Using version %{green}'" .. tostring(version) .. "'")
prefix("Loading %{yellow}" .. tostring(args.file))
local frame = load(readfile(args.file))
args.revision = args.revision or (1 + #(glob(tostring(args.dir) .. "/" .. tostring(frame.package) .. "-" .. tostring(version) .. "-*.rockspec")))
local verrev = tostring(version) .. "-" .. tostring(args.revision)
prefix("Using revision %{green}'" .. tostring(args.revision) .. "'%{reset} (" .. tostring(verrev) .. ")")
prefix("Creating package...")
local package = {
  rockspec_format = frame.format or "3.0",
  package = frame.package or err("Expected package.name"),
  version = verrev,
  description = frame.description,
  supported_platforms = frame.platforms,
  dependencies = extractDeps(frame.dependencies),
  build_dependencies = frame.dependencies and frame.dependencies.build or nil,
  external_dependencies = frame.dependencies and frame.dependencies.external or nil,
  source = {
    url = frame.source and frame.source.url or err("Expected package.source"),
    md5 = frame.source and frame.source.md5 or nil,
    file = frame.source and frame.source.file or nil,
    dir = frame.source and frame.source.dir or nil,
    tag = tostring(args.prefix) .. tostring(version) .. tostring(args.suffix),
    branch = frame.source and frame.source.branch or nil,
    module = frame.source and frame.source.module or nil
  },
  build = frame.build
}
local result = block(package, {
  comment = false
})
if args.dry then
  print(torockspec(result))
  os.exit()
end
local path = tostring(args.dir) .. "/" .. tostring(frame.package) .. "-" .. tostring(verrev) .. ".rockspec"
prefix("Writing to %{yellow}" .. tostring(path))
if not (exists(tostring(args.dir) .. "/")) then
  makeDir(args.dir)
end
writefile(path, torockspec(result))
if args.tag then
  prefix("Making Git tag %{yellow}" .. tostring(args.prefix) .. tostring(version) .. tostring(args.suffix))
  os.execute("git add -A")
  os.execute("git commit -m 'Producing rockspec " .. tostring(verrev) .. "'")
  os.execute("git tag -a " .. tostring(args.prefix) .. tostring(version) .. tostring(args.suffix))
  os.execute("git push --tags")
end
if args.make then
  prefix("Running 'luarocks make'")
  os.execute("luarocks make")
end
if args.upload then
  prefix("Uploading rock %{yellow}" .. tostring(path))
  os.execute("luarocks upload " .. tostring(path))
  for file in iglob("*.src.rock") do
    os.remove(file)
  end
end
if args.delete then
  prefix("Deleting " .. tostring(path))
  return os.remove(path)
end
