#include <time.h>
#include "stb_image/stb_image.h"
#include "stb_image/stb_image_write.h"
#include "image.h"

ICBError icbust_file(const char* input_filename, const char* output_filename, bool debug) {
    int width = 0;
    int height = 0;
    int channels = 0;

    unsigned char* img = stbi_load(input_filename, &width, &height, &channels, 0);

    if (img == 0) {
        return IOReadError;
    }

    size_t img_size = width * height * channels;

    srand(time(NULL));
    int rand_selected_img_pixel = rand() % img_size;
    unsigned char rand_b = rand() % 255;

    // Modify a randomly selected byte
    img[rand_selected_img_pixel] = rand_b;

    if (debug) {
        printf("input filename=%s;", input_filename);
        printf("output filename=%s;\n", output_filename);
        printf("width=%d;height=%d;channels=%d;\n", width, height, channels);
        printf("image size=%zu;\n", img_size);
        printf("randomly selected pixel=%d;to byte=%d\n", rand_selected_img_pixel, rand_b);
    }

    int write_result = stbi_write_jpg(output_filename, width, height, channels, img, 100);
    if (write_result == 0) {
        return IOWriteError;
    }

    stbi_image_free(img);
    return IsOk;
}