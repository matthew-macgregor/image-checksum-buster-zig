#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "image.h"

#include <stdbool.h>
#include <stdlib.h>
#include "cargs/cargs.h"
#include "colors.h"
#include "version.h"

typedef enum {
    StatusOk = EXIT_SUCCESS,
    UnknownError = EXIT_FAILURE,
    OutputFilenameIsRequired = 2,
    IOError = 7,
    InputFilenameIsRequired = 13,
    InputAndOutputEquality = 21,
    BadArgument = 22
} StatusCode;

/**
 * This is the main configuration of all options available.
 */
static struct cag_option options[] = {{
        .identifier = 'h',
        .access_letters = "h",
        .access_name = "help",
        .description = "Displays this help and exit."
    },{
        .identifier = 'o',
        .access_letters = "o",
        .access_name = "output",
        .value_name = "VALUE",
        .description = "Output filename."
    },{
        .identifier = 'd',
        .access_letters = "d",
        .access_name = "debug",
        .value_name = NULL,
        .description = "Enable debug output."
    },{
        .identifier = 'v',
        .access_letters = "v",
        .access_name = "version",
        .description = "Output version string."
    }
};

struct args_cfg {
    bool debug;
    bool version;
    const char *input_file;
    const char *output_file;
};

int main(int argc, char **argv)
{
    char identifier;
    const char *value;
    cag_option_context context;
    struct args_cfg config = {false, NULL, NULL};
    int param_index;

    cag_option_prepare(&context, options, CAG_ARRAY_SIZE(options), argc, argv);
    while (cag_option_fetch(&context))
    {
        identifier = cag_option_get(&context);
        switch (identifier)
        {
        case 'd':
            config.debug = true;
            break;
        case 'o':
            value = cag_option_get_value(&context);
            config.output_file = value;
            break;
        case 'v':
            printf("Version %s\n", VERSION);
            return 0;
        case 'h':
            printf("\n%sicbuster (Image Checksum Buster)%s\n"
            "%s----------------------------------------------------\n"
            "Outputs a JPEG with randomly modified pixel to bust its checksum.\n"
            "Version %s+clang\n\n  <FILE>\n", CON_GREEN, CON_RESET, CON_GRAY, VERSION);
            cag_option_print(options, CAG_ARRAY_SIZE(options), stdout);
            printf("%s\n", CON_RESET);
            return EXIT_SUCCESS;
        default:
            printf("Unknown identifier: %s\n", identifier);
            return BadArgument;
        }
    }

    if (config.debug) {
        printf("Debug mode.\n");
    }

    if (context.index < argc) {
        // TODO: lifespan of argv should allow me to just take a pointer.
        config.input_file = argv[context.index];
    }

    if (!config.input_file) {
        printf("%sInput file is required.%s\n", CON_RED, CON_RESET);
        return EXIT_FAILURE;
    }

    if (!config.output_file) {
        printf("%sOutput file is required.%s\n", CON_RED, CON_RESET);
        return EXIT_FAILURE;
    }

    ICBError result = icbust_file(config.input_file, config.output_file, config.debug);
    return result != IsOk ? result : 0;
}