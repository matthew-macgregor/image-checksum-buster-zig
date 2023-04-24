#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "image.h"

#include <stdbool.h>
#include <stdlib.h>
#include "cargs/cargs.h"
#include "colors.h"

/**
 * This is the main configuration of all options available.
 */
static struct cag_option options[] = {
    {.identifier = 'd',
     .access_letters = "d",
     .access_name = "debug",
     .value_name = NULL,
     .description = "Enable debug output."},

    {.identifier = 'o',
     .access_letters = "o",
     .access_name = "output",
     .value_name = "VALUE",
     .description = "Output file name."},

    {.identifier = 'h',
     .access_letters = "h",
     .access_name = "help",
     .description = "Shows the command help"}
};

struct args_cfg
{
    bool debug;
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
        case 'h':
            printf("Usage: cargsdemo [OPTION]...\n");
            printf("Demonstrates the cargs library.\n\n");
            cag_option_print(options, CAG_ARRAY_SIZE(options), stdout);
            printf("\nNote that all formatting is done by cargs.\n");
            return EXIT_SUCCESS;
        default:
            printf("Unknown identifier: %s\n", identifier);
        }
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

    if (config.debug) {
        printf("Debug mode.\n");
    }

    ICBError result = icbust_file(config.input_file, config.output_file, config.debug);
    return result != IsOk ? result : 0;
}