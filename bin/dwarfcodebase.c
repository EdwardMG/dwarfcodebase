#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define BL 255

// - [x] 3d array
// - [x] set value in 3d array
// - [x] respond to command line arguments
// - [x] read from file
// - [x] write to file
// - [x] read/write 3d array of structs (obviously a shorthand, maybe semicolon delimited? you need coordinate, label, action, type
//       actually, probably more like label:type:action, and just let the linenumber be the index of the array, especially since it's
//       defined as a flat array in reality, you just loop over every line
// - [x] respond to command line write and label
// - [x] tie into a vim mode
// - [x] descend and ascend depth
// - [x] don't allow moving location offmap (either beyond max or below min...)
// - [x] vim mode to open files as it goes over labeled entries
// - [x] erase label
// - [-] if labels appear next to each other, it might be nice to draw a `-` or `|` to make visual connections easy to see
//       did this for between cols and it looks nice, but there is no spacing between rows to put it without making it ugly
// - [x] redraw popup on change buffer
// - [x] remainder of alphabete for setting labels (after this it's pretty much usable!)

// stretch
// - [ ] it could be nice to have line number and column as well?

int maxd = 10; // depth
int maxr = 10; // row
int maxc = 10; // col

struct cell {
        char label;
        char path[BL];
};

void populate(struct cell* p, int l) {
        for (int i = 0; i < l; i++) {
                p[i].label = 'X';
                p[i].path[0] = '\0';
        }
}

void printFloor(int d, struct cell* p, int* l) {
        for (int r=0; r < maxr; r++) {
                printf("\n");
                // if we want up and down pipes, we have to do more than just print a new line
                // actually, we don't print a new line at all, it's single spaced. hmmm. I like how they're spaced
                // already so I don't want to add lines inbetween
                printf("  "); // leading space for border
                for (int c=0; c < maxc; c++) {
                        char label = p[d * maxd * maxr + r * maxr + c].label;
                        if (l[0] == d && l[1] == r && l[2] == c) {
                                printf( "%c", tolower(label));
                        } else {
                                printf( "%c", label);
                        }
                        /* printf(" "); */
                        char next_label = p[d * maxd * maxr + r * maxr + c + 1].label;
                        if (label != 'X' && next_label != 'X' && c < maxc - 1) {
                                printf("-");
                        } else {
                                printf(" ");
                        }
                }
                printf(" "); // trailing space for border
        }
        printf("\n           %i", d);
}

void set(int d, int r, int c, char l, char* action, struct cell* p) {
        p[d * maxd * maxr + r * maxr + c].label = l;

        if (action[0] == '/') {
                strlcpy(p[d * maxd * maxr + r * maxr + c].path, action, BL);
        }
}

void read(struct cell* p, int* l) {
        FILE* f = fopen("/Users/edwardgallant/dftest", "r"); if (!f) return;
        char line[BL];
        fgets(line, BL, f);

        // C bullshit where we subtract '0' to get an int from a char
        // atoi expects a string so it's not convenient for us
        l[0] = line[0] - '0';
        l[1] = line[1] - '0';
        l[2] = line[2] - '0';

        // 1000 is the max, but for messing around I hard coded it
        // BL is the buflength to read in; could result in bugs where things
        // are mislabeled if it ever went over, which it well could given our long paths
        for (int i = 0; i < 1000 && fgets(line, BL, f); i++) {
                p[i].label = line[0];
                if ( line[1] == '/' ) {
                        int j = 1;
                        while (line[j] != '\n') { // we DO NOT want to copy the newline into the path, or it makes everything confusing
                                p[i].path[j-1] = line[j];
                                j++;
                        }
                        p[i].path[j-1] = '\0';
                } else {
                        p[i].path[0] = '\0';
                }
        }

        fclose(f);
}

void write(struct cell* p, int* l) {
        // const char* s = getenv("HOME");
        // have to do this and manually concat the strings
        // to make this generic
        // it's only for me so... who cares
        FILE* f = fopen("/Users/edwardgallant/dftest", "w+"); if (!f) return;
        char line[BL];

        // print location... not fprintf, formatted print to file
        fprintf(f, "%d", l[0]);
        fprintf(f, "%d", l[1]);
        fprintf(f, "%d", l[2]);
        fputs("\n\0", f);

        // put each label and path
        for (int i = 0; i < 1000; i++) {
                line[0] = p[i].label;
                line[1] = '\0';
                fputs(line, f);
                fputs(p[i].path, f);
                fputs("\n\0", f);
        }

        fputs("\0", f);
        fclose(f);
}

int main(int argc, char **argv) {
        char cmd = argc > 1 ? argv[1][0] : '\0';

        int max = maxd * maxr * maxc;
        struct cell a[max];
        int l[3] = {0, 0, 0};
        populate(a, max);

        read(a, l);

        if (cmd == 'p') { // "print" location
                if ( argc == 2) return 0; // did not recieve a path (it was blank or something)
                for (int i=0; i < max; i++) {
                        if (strcmp(a[i].path, argv[2]) == 0) {
                                l[0] = i / 100;
                                l[1] = (i - (l[0] * 100)) / 10;
                                l[2] = i - (l[0] * 100) - (l[1] * 10);
                                write(a, l);
                                printf("1");
                                return 0;
                        }
                }
                printf("0");
                return 0;
        }

        if (cmd == 'h' && l[2] > 0)      l[2] = l[2] - 1;
        if (cmd == 'j' && l[1] < maxr-1) l[1] = l[1] + 1;
        if (cmd == 'k' && l[1] > 0)      l[1] = l[1] - 1;
        if (cmd == 'l' && l[2] < maxc-1) l[2] = l[2] + 1;
        if (cmd == 'f' && l[0] > 0)      l[0] = l[0] - 1;
        if (cmd == 'd' && l[0] < maxd-1) l[0] = l[0] + 1;

        if (cmd == 'x') { // label (x marks the spot)
                set(l[0], l[1], l[2], argv[1][1], argv[2], a);
        }

        if (cmd == 'e') { // erase
                set(l[0], l[1], l[2], 'X', "", a);
        }

        /* for (int i=0; i < 10; i++) printFloor(i, a); */

        write(a, l);
        printFloor(l[0], a, l);

        if (a[l[0] * maxd * maxr + l[1] * maxr + l[2]].path[0]) {
                printf("\n%s", a[l[0] * maxd * maxr + l[1] * maxr + l[2]].path);
        } else {
                printf("\n\n");
        }
}
