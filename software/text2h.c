/*
 * text2h.c - A small tool to generate a header file from a text file.
 * (c) 2004 Alexandre Erwin Ittner <aittner@netuno.com.br>
 *
 * This program is distributed under the terms of GNU GPL, version 2, and
 * comes WITHOUT ANY WARRANTY.
 *
 * Compile with:   gcc -o text2h text2h.c
 *
 */


#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>

void defstream(FILE *ifp, FILE *ofp, char *name)
{
    char c;
    int cnt = 0;

    fprintf(ofp, "/* This is a generated file -- Do not edit */\n\n");
    fprintf(ofp, "#define %s \\\n    \"", name);
    
    while(1)
    {
        c = getc(ifp);
        if(feof(ifp))
            break;
        switch(c)
        {
            default:
                fprintf(ofp, "%c", c);
                cnt++;
                break;
            case '\0':
                continue;
            case '\n':
                fprintf(ofp, "\\n\" \\\n    \"");
                cnt = 0;
                break;
            case '\r':
                fprintf(ofp, "\\r");
                cnt += 2;
                break;
            case '"':
                fprintf(ofp, "\\\"");
                cnt += 2;
                break;
            case '\t':
                fprintf(ofp, "\\t");
                cnt += 2;
                break;
            case '\f':
                fprintf(ofp, "\\f");
                cnt += 2;
                break;
            case '\v':
                fprintf(ofp, "\\v");
                cnt += 2;
                break;
            case '\\':
                fprintf(ofp, "\\\\");
                cnt += 2;
                break;
        }
        if(cnt >= 70)
        {
            fprintf(ofp, "\" \\\n    \"");
            cnt = 0;
        }
    }
    fprintf(ofp, "\"\n");
    fflush(ofp);
}
       

void usage(FILE *fp)
{
    fprintf(fp, "text2h (c) 2004 Alexandre Erwin Ittner\n");
    fprintf(fp, "This program is distributed under the GNU GPL, version 2, "
                "and comes WITHOUT ANY WARRANTY.\n\n");
    fprintf(fp, "Usage: text2h <infile> <defname> [outfile]\n");
}


int main(int argc, char *argv[])
{
    char *ifname = NULL;
    char *ofname = NULL;
    char *defname = NULL;
    FILE *ifp;
    FILE *ofp;

    if(argc < 3 || argc > 4)
    {
        usage(stderr);
        return 1;
    }

    ifname = argv[1];
    defname = argv[2];

    if((ifp = fopen(ifname, "rt")) == NULL)
    {
        fprintf(stderr, "Error: Failed to open '%s' for reading.\n", ifname);
        return 1;
    }

    if(argc == 4)
    {
        ofname = argv[3];
        if((ofp = fopen(ofname, "wt")) == NULL)
        {
            fprintf(stderr, "Error: Failed to open '%s' for writing.\n",
                ofname);
            return 1;
        }
    }
    else
        ofp = stdout;

    defstream(ifp, ofp, defname);
    if(ofname)
        fclose(ofp);
    fclose(ifp);
    return 0;
}


