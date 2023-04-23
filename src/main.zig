const std = @import("std");
const img = @import("image");
const clap = @import("clap");
const cfg = @import("config");
const ansi = @import("ansi");
const DEBUG = (std.debug.runtime_safety);

const StatusCode = enum(u8) {
    Ok = 0,
    OutputFilenameIsRequired = 1,
    InputFilenameIsRequired = 13,
    InputAndOutputEquality = 21,
    ICBustError = 42,
};

fn usage(helpText: []const u8) void {
    std.debug.print("\n{s}izbuster (Image Checksum Buster via Zig){s}\n", .{ ansi.green, ansi.reset });
    std.debug.print("{s}----------------------------------------------------\n", .{ansi.gray});
    std.debug.print("Outputs a JPEG with randomly modified pixel to bust its checksum.\n", .{});
    std.debug.print("Version {s}\n", .{cfg.version});
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
        std.debug.print("{s}\n", .{cfg.version});
        return 0;
    }

    const debug = (res.args.debug != 0);

    if (res.positionals.len > 0) {
        const filen_in = res.positionals[0];
        if (res.args.output) |filen_out| {
            if (std.mem.eql(u8, filen_in, filen_out)) {
                std.debug.print("Input and output files cannot be the same.\n", .{});
                return @enumToInt(StatusCode.InputAndOutputEquality);
            }

            img.icbust_file(filen_in, filen_out, debug) catch |err| {
                switch (err) {
                    img.StbImageError.IOInputError => {
                        std.debug.print("{s}There was an error reading from the file {s}: {any}.{s}\n", .{ ansi.red, filen_in, err, ansi.reset });
                    },
                    else => {
                        std.debug.print("{s}There was an error: {any}.{s}\n", .{ ansi.red, err, ansi.reset });
                    },
                }
                return @enumToInt(StatusCode.ICBustError);
            };
        } else {
            std.debug.print("{s}Output filename is required.{s}\n", .{ ansi.red, ansi.reset });
            return @enumToInt(StatusCode.OutputFilenameIsRequired);
        }
    } else {
        std.debug.print("{s}Input filename is required.{s}\n", .{ ansi.red, ansi.reset });
        return @enumToInt(StatusCode.InputFilenameIsRequired);
    }

    // Leaving this here for reference, although it is currently not implemented.
    // This version allocates an in memory copy and passes the copy to be written.
    // const allocator = std.heap.page_allocator;
    // const result = icbust_file_w_copy(&allocator, filen, filen_out) catch |err| {
    //     std.debug.print("Oops: {any}\n", .{err});
    //     return;
    // };

    return @enumToInt(StatusCode.Ok);
}
