const std = @import("std");
const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cInclude("stb_image/stb_image.h");
    @cInclude("stb_image/stb_image_write.h");
});

const DEBUG = (std.debug.runtime_safety);
pub const StbImageError = error{ IOError, IOReadError, IOWriteError };

/// Loads the image file at {input_filename}, modifies a byte, and writes it to
/// a JPEG {output_filename}. This function is intended to act as a cachebuster.
///
/// Supports any of the formats provided by stb_image, which should include:
/// - jpeg, gif, png, bmp, psd (and a few others)
///
/// The stb_image library makes no guarantees about the security of reading
/// image files, and so it is best to only use this function with images which
/// are known-good or have been sanitized.
///
///
pub fn icbustFile(input_filename: []const u8, output_filename: []const u8, debug: bool) !void {
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const img = c.stbi_load(input_filename.ptr, &width, &height, &channels, 0);
    defer c.stbi_image_free(img);

    if (img == 0) {
        return StbImageError.IOReadError;
    }

    const img_size: usize = @intCast(usize, width * height * channels);

    const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
    var prng = std.rand.DefaultPrng.init(seed);
    const rand_f = prng.random().float(f32);
    const rand_selected_img_pixel = std.math.floor(rand_f * @intToFloat(f64, img_size));
    const rand_b = prng.random().int(u8);

    // Modify a randomly selected byte
    img[@floatToInt(usize, rand_selected_img_pixel)] = rand_b;

    if (debug) {
        std.debug.print("input filename={s};", .{input_filename});
        std.debug.print("output filename={s};\n", .{output_filename});
        std.debug.print("width={d};height={d};channels={d};\n", .{ width, height, channels });
        std.debug.print("image size={d};\n", .{img_size});
        std.debug.print("randomly selected pixel={d};to byte={d}\n", .{ rand_selected_img_pixel, rand_b });
    }

    const write_result = c.stbi_write_jpg(output_filename.ptr, width, height, channels, img, 100);
    if (write_result == 0) {
        return StbImageError.IOWriteError;
    }
}
