# Rockbuild

[rockwriter](https://github.com/daelvn/rockwriter) stopped working for me after its prompt library, [Croissant](https://github.com/giann/croissant), broke for me on Alpine. This library takes a different approach, writing the rockspec in YAML, and taking care of the steps like compiling it, versioning, uploading and such.

In here, you don't have to include the `version` and `source.tag` fields: Rockbuild will fill them for you.

## Usage

Create a `rock.yml` (or any other YAML file, as long as you pass the filename with `-f`) that has the structure of a normal rockspec. You can look at the `rock.yml` for this repo for an example. There are a couple changes:

- `build_dependencies` is `dependencies.build` in YAML
- `external_dependencies` is `dependencies.external` in YAML
- `supported_platforms` is `platforms` in YAML

Then, the basics are:

```sh
# Just prints the resulting rockspec
$ rockbuild --dry 1.0
# Generate a new rockspec, then make it
$ rockbuild -m 1.0
# Delete the rockspec after creating and making it
$ rockbuild -m --delete 1.0
# Store rockspecs in a different location
$ rockbuild -d rocks 1.0
# This one is equivalent to:
#   git add -A
#   git commit -m "Producing rockspec 1.0-1"
#   git tag -a v1.0
#   git push --tags
#   luarocks upload rockspecs/package-1.0-1.rockspec
$ rockbuild -t 1.0 upload
```

### Full usage

```
Usage: rockbuild [-h] [-p <prefix>] [-s <suffix>] [-f <file>]
       [-d <dir>] [--dry] [--delete] [-r <revision>] [-m] [-t] [-v]
       <version> [<command>] ...

Compile YAML rockframes into Lua rockspecs

Arguments:
   version                  version for your rockspec

Options:
   -h, --help               Show this help message and exit.
         -p <prefix>,       sets the prefix for the source tag (default: v)
   --prefix <prefix>
         -s <suffix>,       sets the suffix for the source tag (default: )
   --suffix <suffix>
       -f <file>,           rockframe location (default: rock.yml)
   --file <file>
      -d <dir>,             rockspec output location (default: rockspecs)
   --dir <dir>
   --dry                    prints the resulting rockspec and does nothing else
   --delete                 deletes the rockspec after using it
           -r <revision>,   custom revision for the rockspec
   --revision <revision>
   -m, --make               runs 'luarocks make' after compiling the rockspec
   -t, --tag                Adds a git tag after compiling the rockspec
   -v, --version            Shows the current version

Commands:
   upload, u                uploads the rockspec after compile

https://github.com/daelvn/rockbuild
```

## Install

You can install this project through LuaRocks

```sh
$ luarocks install rockbuild
```