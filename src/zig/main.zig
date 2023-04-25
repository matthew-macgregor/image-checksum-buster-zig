const std = @import("std");
const clap = @import("clap");
const img = @import("image.zig");
const ansi = @import("ansi.zig");
const DEBUG = (std.debug.runtime_safety);

const c = @cImport({
    @cInclude("version.h");
});

const StatusCode = enum(u8) {
    Ok = 0,
    UnknownError = 1,
    OutputFilenameIsRequired = 2,
    IOError = 7,
    InputFilenameIsRequired = 13,
    InputAndOutputEquality = 21,
};

fn usage(helpText: []const u8) void {
    std.debug.print("\n{s}izbuster (Image Checksum Buster){s}\n", .{ ansi.green, ansi.reset });
    std.debug.print("{s}----------------------------------------------------\n", .{ansi.gray});
    std.debug.print("Outputs a JPEG with randomly modified pixel to bust its checksum.\n", .{});
    std.debug.print("Version {s}+zig\n", .{c.VERSION});
    std.debug.print("{s}{s}\n", .{ helpText, ansi.reset });
}

pub fn main() u8 {
    const helpTxt =
        \\
        \\<FILE>
        \\-h, --help               Display this help and exit.
        \\-o, --output <FILE>      Output filename.
        \\-d, --debug              Enable debug output.
        \\-v, --version            Output version string.
        \\
    ;
    const params = comptime clap.parseParamsComptime(helpTxt);

    const parsers = comptime .{
        .FILE = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return 1;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        usage(helpTxt);
        return 0;
    }

    if (res.args.version != 0) {
        std.debug.print("{s}\n", .{c.VERSION});
        return 0;
    }

    const debug = (res.args.debug != 0);

    if (debug) {
        std.debug.print("Debug mode.\n", .{});
    }

    const filen_in = if (res.positionals.len > 0)
        res.positionals[0]
    else {
        std.debug.print("{s}Input file is required.{s}\n", .{ ansi.red, ansi.reset });
        return @enumToInt(StatusCode.InputFilenameIsRequired);
    };

    const filen_out = if (res.args.output) |fout|
        fout
    else {
        std.debug.print("{s}Output file is required.{s}\n", .{ ansi.red, ansi.reset });
        return @enumToInt(StatusCode.OutputFilenameIsRequired);
    };

    if (std.mem.eql(u8, filen_in, filen_out)) {
        std.debug.print("Input and output files cannot be the same.\n", .{});
        return @enumToInt(StatusCode.InputAndOutputEquality);
    }

    img.icbustFile(filen_in, filen_out, debug) catch |err| {
        switch (err) {
            img.StbImageError.IOReadError => {
                std.debug.print("{s}There was an error reading from the file {s}: {any}.{s}\n", .{ ansi.red, filen_in, err, ansi.reset });
                return @enumToInt(StatusCode.IOError);
            },
            img.StbImageError.IOWriteError => {
                std.debug.print("{s}There was an error writing to the file {s}: {any}.{s}\n", .{ ansi.red, filen_out, err, ansi.reset });
                return @enumToInt(StatusCode.IOError);
            },
            else => {
                std.debug.print("{s}There was an error: {any}.{s}\n", .{ ansi.red, err, ansi.reset });
                return @enumToInt(StatusCode.UnknownError);
            },
        }
    };

    return @enumToInt(StatusCode.Ok);
}
