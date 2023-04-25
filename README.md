# Image Checksum Buster

Project goals:

- Learn something about the Zig programming language in a trivial project.
- Leverage the `stb_image` single header libraries.
- Mix C and Zig in a single project.
- Use a simple C library in a Zig project.
- Evaluate Zig's build tools, potentially as a standalone alternative to CMake etc.
- Solve a niche problem that crops up day-to-day for me.

# Implementations

The repo contains two side-by-side implementations that (currently) support
parallel features: a C implementation and a Zig implementation. `zig build`
builds both implementations: `icbuster` is the C version, and `izbuster` is the
Zig implementation. The C implementation is mostly there for comparison.

- Note: There are only tests written for the Zig version of the program.

# License

[MIT License](./LICENSE).

# Libraries

All library dependencies are vendored into the `libs` folder, so you only need
this repo in order to build the tool.

- [stb_image](https://github.com/nothings/stb/): Simple image library. Public Domain.
- [zig-clap](https://github.com/Hejsil/zig-clap): Command-line argument parser. MIT License.

# Introduction

This project takes an image file in one of several popular formats (JPEG, PNG,
GIF, BMP, etc.) and randomly changes a byte in one of the channels. The resulting
file (naturally) has a new checksum, which busts the cache for systems that rely
on a checksum for deduplication.

Naturally, there are simpler ways to do this, such as using imagemagick to add
a watermark or just poke a byte at random somewhere past the JPEG header. But
since this is a freetime project, it struck me as a great chance to try out the
Zig programming language.

# Usage

Given an image file `foo.jpg`:

```sh
./izbuster foo.jpg -o out.jpg
md5 img/*.jpg
```

Output:

```sh
MD5 (img/out.jpg) = 5dd5d15b1468bee9d498aaec58fcf342
MD5 (img/foo.jpg) = 7ab77224654503a92a1c45db8a3e0d79
```

# Dependencies

- Zig 0.10.1: the current stable version at the moment.
- All other dependencies are vendored into the libs folder.

# Build

```sh
zig build -Drelease-safe
```

# Develop

```sh
zig build run/zig -- --help # build/run the C impl
zig build run/c -- --help   # build/run the Zig impl
```

# Test

```sh
zig build test
```

# Stability & Security

This project makes no claims about its fitness for any purpose.

The `stb_image` library has the following note:

>   Primarily of interest to game developers and other people who can
>   avoid problematic images and only need the trivial interface

This tool should probably not be used with images of unknown provenance unless
they have already been sanitized.