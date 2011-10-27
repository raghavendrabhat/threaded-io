/* This program will calculate the average time consumed by the */
/* gettimeofday () function call by making 100,000 gettimeofday */
/* calls and then calculating the duration. */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/time.h>

double
timeval_elapsed(struct timeval *tv1, struct timeval *tv2)
{
        return (tv2->tv_sec - tv1->tv_sec)+
                (tv2->tv_usec - tv1->tv_usec) * 1.0e-6;
}

int
main ()
{
        int i = -1;
        int ret = -1;
        struct timeval tmp, before, after;
        double duration;
        double full;

        gettimeofday (&before, NULL);

        for (i = 0; i < 100000; i++) {
                gettimeofday (&tmp,  NULL);
        }

        gettimeofday (&after, NULL);

        full = timeval_elapsed (&before, &after);
        duration = full * 1e6/100000;
        printf ("full: %.01f\n avg: %.01f us\n", full, duration);
}
