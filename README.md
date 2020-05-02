# Rockbuild

[rockwriter](https://github.com/daelvn/rockwriter) stopped working for me after its prompt library, [Croissant](https://github.com/giann/croissant), broke for me on Alpine. This library takes a different approach, writing the rockspec in YAML, and taking care of the steps like compiling it, versioning, uploading and such.

## Install

You can install this project through LuaRocks

```sh
$ luarocks install rockbuild
```