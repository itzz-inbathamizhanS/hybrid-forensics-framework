/* Normal compute and data writes; never executes memory it wrote. Must give no FSU alert.
 * Build: gcc -O0 -static benign.c -o benign */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    enum { N = 1 << 14 };
    unsigned *a = malloc(N * sizeof *a);
    char *s = malloc(8192);
    if (!a || !s) return 1;
    for (unsigned i = 0; i < N; i++) a[i] = i * 2654435761u;
    unsigned long sum = 0;
    for (int r = 0; r < 20; r++)
        for (unsigned i = 0; i < N; i++) sum += a[i] ^ (sum >> 3);
    memset(s, 'x', 8192);
    snprintf(s, 64, "sum=%lu", sum);
    printf("[Benign] %s\n", s);
    free(a); free(s);
    return 0;
}
