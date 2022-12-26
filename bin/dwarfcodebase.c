#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define BL 255

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

int findIndex(int d, int r, int c) {
        return d * maxd * maxr + r * maxr + c;
}

void printFloor(int d, struct cell* p, int* l) {
        for (int r=0; r < maxr; r++) {
                printf("\n");
                // if we want up and down pipes, we have to do more than just print a new line
                // actually, we don't print a new line at all, it's single spaced. hmmm. I like how they're spaced
                // already so I don't want to add lines inbetween
                printf("  "); // leading space for border
                for (int c=0; c < maxc; c++) {
                        char label = p[ findIndex(d, r, c) ].label;
                        if (l[0] == d && l[1] == r && l[2] == c) {
                                printf( "%c", tolower(label));
                        } else {
                                printf( "%c", label);
                        }
                        /* printf(" "); */
                        char next_label = p[ findIndex(d, r, c + 1) ].label;
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

        // this will break if we ever go about 10 (index 9)
        // in that case, we would have to create a separator and
        // probably atoi and some temp string management
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

struct In {
        int argc;
        int clear;
        int print_location;
        int label;
        char move;
        char label_value;
        char path[BL];
};

struct In in;

void setIn(int argc, char **argv) {
        in.argc           = argc;
        in.move           = '\0';
        in.clear          = 0;
        in.print_location = 0;
        in.label          = 0;
        in.label_value    = 'X'; // our default empty space
        in.path[0]        = '\0';


        if (argc > 1) {
                char cmd  = argv[1][0];
                char cmd2 = argv[1][1];

                if (cmd == 'j' || // up
                    cmd == 'k' || // down
                    cmd == 'h' || // left
                    cmd == 'l' || // right
                    cmd == 'd' || // descend
                    cmd == 'f')   // float
                        in.move = cmd;
                else if (cmd == 'e') in.clear = 1; // erase
                else if (cmd == 'p') { // print location
                        in.print_location = 1;
                        if (argc > 2) {
                                if (argv[2][0] == '/') {
                                        strlcpy(in.path, argv[2], BL);
                                } else {
                                        printf("Recieved '%s', but expected a path starting with /.", argv[2]);
                                        exit(1);
                                }
                        } else {
                                printf("Recieved '%s' (print location), but no path followed.", argv[1]);
                                exit(1);
                        }
                } else if (cmd == 'm') { // mark
                        in.label = 1;
                        in.label_value = cmd2;
                        if (argc > 2) {
                                if (argv[2][0] == '/') {
                                        strlcpy(in.path, argv[2], BL);
                                } else {
                                        printf("Recieved '%s', but expected a path starting with /.", argv[2]);
                                        exit(1);
                                }
                        } else {
                                printf("Recieved '%s' (set label), but no path followed.", argv[1]);
                                exit(1);
                        }
                } else {
                        printf("Recieved '%c' as argument, but no such action exists.", argv[1][0]);
                        exit(1);
                }
        }
}

int main(int argc, char **argv) {
        setIn(argc, argv);

        char cmd = argc > 1 ? argv[1][0] : '\0';

        int max = maxd * maxr * maxc;
        struct cell a[max];
        int l[3] = {0, 0, 0};
        populate(a, max);

        read(a, l);

        if (in.print_location) {
                for (int i=0; i < max; i++) {
                        if ( strcmp(a[i].path, in.path) == 0 ) {
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

        if (in.move == 'h' && l[2] > 0)      l[2] = l[2] - 1;
        if (in.move == 'j' && l[1] < maxr-1) l[1] = l[1] + 1;
        if (in.move == 'k' && l[1] > 0)      l[1] = l[1] - 1;
        if (in.move == 'l' && l[2] < maxc-1) l[2] = l[2] + 1;
        if (in.move == 'f' && l[0] > 0)      l[0] = l[0] - 1;
        if (in.move == 'd' && l[0] < maxd-1) l[0] = l[0] + 1;

        if (in.label) set(l[0], l[1], l[2], in.label_value, in.path, a);
        if (in.clear) set(l[0], l[1], l[2], 'X', "", a);

        write(a, l);
        printFloor(l[0], a, l);

        int index = findIndex( l[0], l[1], l[2] );
        if (a[ index ].path[0])
                printf("\n%s", a[ index ].path);
        else
                printf("\n\n");

        return 0;
}

/* for (int i=0; i < 10; i++) printFloor(i, a); */
