#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

#define BLOCK_SIZE 4096

void *buf;

int main(int argc, char **argv)
{
        buf = malloc (512);
        memset (buf,"a",512);
        int fd = 0;
        int i;
        int sector_per_block = BLOCK_SIZE/512;
        int block_count = 4;

        if(argc != 2) {
                printf ("Wrong usage\n USAGE: program absolute_path_to_write\n");
                _exit (-1);
        }

        fd = open (argv[1],O_RDWR | O_CREAT,0666);
        if (fd <= 0) {
                printf ("file open failed\n");
                _exit (0);
        }

        while (block_count > 0) {
                lseek (fd, BLOCK_SIZE, SEEK_CUR);
                block_count--;

                for(i = 0; i < sector_per_block; i++)
                        write (fd, buf, 512);

                block_count--;
        }

        close(fd);

        return 0;
}
