const std = @import("std");
const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cInclude("stb_image/stb_image.h");
    @cInclude("stb_image/stb_image_write.h");
});

const DEBUG = (std.debug.runtime_safety);
pub const StbImageError = error{ IOError, IOReadError, IOWriteError };

// icbust_file_w_copy: leaving this here as an example of allocating a copy of
// the original image and modifying the bytes of that buffer. It took a few
// attempts to figure out the right incantation for handling the void*.
pub fn icbust_file_w_copy(allocator: *const std.mem.Allocator, input_filename: []const u8, output_filename: []const u8, debug: bool) !i32 {
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const ptr_in_filen = @ptrCast([*c]const u8, input_filename);
    const orig_img_buff = c.stbi_load(ptr_in_filen, &width, &height, &channels, 0);
    if (orig_img_buff == 0) {
        return StbImageError.IOReadError;
    }

    const img_size: usize = @intCast(usize, width * height * channels);

    const new_img_buff = try allocator.alloc(u8, img_size);
    defer allocator.free(new_img_buff);

    if (debug) {
        std.debug.print("width={d};height={d};channels={d};\n", .{ width, height, channels });
        std.debug.print("Image size: {d}\n", .{img_size});
    }

    // const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
    // const prng = std.rand.DefaultPrng.init(seed);
    // const rand_f = prng.random().float(f32);
    // const rand_selected_img_pixel = std.math.floor(rand_f * @intToFloat(f64, img_size));
    // const rand_b = prng.random().int(u8);

    var i: usize = 0;
    while (i < img_size) : (i += 1) {
        new_img_buff[i] = orig_img_buff[i]; // do something to manipulate the images
    }

    // Writes the modified image out to disk
    const ptr_out_filen = @ptrCast([*c]const u8, output_filename);
    const write_result = c.stbi_write_jpg(ptr_out_filen, width, height, channels, @ptrCast(?*const anyopaque, new_img_buff), 100);
    std.debug.print("Write resuit: {d}\n", .{write_result});
    c.stbi_image_free(orig_img_buff);
    return 0;
}

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
pub fn icbust_file(input_filename: []const u8, output_filename: []const u8, debug: bool) !void {
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const img = c.stbi_load(@ptrCast([*c]const u8, input_filename), &width, &height, &channels, 0);
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

    const write_result = c.stbi_write_jpg(@ptrCast([*c]const u8, output_filename), width, height, channels, img, 100);
    if (write_result == 0) {
        return StbImageError.IOWriteError;
    }
}
