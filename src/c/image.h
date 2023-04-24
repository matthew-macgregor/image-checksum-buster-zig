#include <stdbool.h>
#include <stdlib.h>

#ifndef IMAGE_H
#define IMAGE_H

typedef enum {
    IsOk = EXIT_SUCCESS,
    IOReadError,
    IOWriteError
} ICBError;

ICBError
icbust_file(const char* input_filename, const char* output_filename, bool debug);

#endif