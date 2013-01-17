#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <unistd.h>
#include <netdb.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>

#define MAX_FILE_NAME 1024
#define SERVER_DIRECTORY "/home/raghu/public_html"

int serv_clients (int fd, char *filepath);
void get_filename (char *request, char **tmp);

int main (int argc, char *argv[])
{
        struct addrinfo hints = {0,};
        struct addrinfo *res = NULL;
        struct sockaddr_storage their_addr = {0,};
        socklen_t addr_size;
        int socketfd = 0;
        int newfd = 0;
        int ret = -1;
        int child = -1;
        char filepath[1024] = {0,};

        if (argv[1] == NULL) {
                strcpy (filepath, SERVER_DIRECTORY);
                printf ("filpath: %s\n", filepath);
        } else {
                strcpy (filepath, argv[1]);
                printf ("filepath: %s\n", filepath);
        }

        // first, load up address structs with getaddrinfo():
        memset (&hints, 0, sizeof (hints));
        hints.ai_family = AF_UNSPEC; //use IPv4 or IPv6, whichever
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_flags = AI_PASSIVE; //fill in my IP for me

        ret = getaddrinfo (NULL, "http", &hints, &res);
        if (ret) {
                fprintf (stderr, "Error while getting the address: %s\n",
                         gai_strerror(errno));
                goto out;
        }

        socketfd = socket (res->ai_family, res->ai_socktype, res->ai_protocol);
      //socketfd = socket (AF_INET, SOCK_STREAM, 0);
        if (socketfd == -1) {
                fprintf (stderr, "Error while creating the socket: %s\n",
                         strerror (errno));
                goto out;
        }

        ret = bind (socketfd, res->ai_addr, res->ai_addrlen);
        if (ret) {
                fprintf (stderr, "Error while binding to the socket: %s\n",
                         strerror (errno));
                goto out;
        }

        ret = listen (socketfd, 22);
        if (ret) {
                fprintf (stderr, "Error while listening on the socket %d:(%s)\n",
                         socketfd, strerror (errno));
                goto out;
        }

        newfd = accept (socketfd, (struct sockaddr *)&their_addr, &addr_size);
        if (newfd == -1) {
                fprintf (stderr, "Error while accepting the connection:(%s)\n"
                         , strerror (errno));
                goto out;
        }

        child = fork ();
        if (child == 0) {
                serv_clients (newfd, filepath);
                close (newfd);
                close (socketfd);
        }
out:
        if (res)
                freeaddrinfo (res);
        return ret;
}


int serv_clients (int fd, char *filepath)
{
        char req[MAX_FILE_NAME]; //The http request to be stored here.
        int  ret = -1;
        int  file_fd = -1;
        char buf[8192];
        int  bytes_read;
        char *file_requested = NULL;
        char file_path[MAX_FILE_NAME];
        struct stat stbuf;
        DIR *dir = NULL;
        struct dirent *entry = NULL;
        int length = 0;

        ret = read (fd, req, sizeof (req));
        if (-1 == ret) {
                fprintf (stderr, "Error while reading from the socket: %s\n",
                         strerror (errno));
                return ret;
        }

        if ((strstr (req, "GET")) == NULL) {
                fprintf (stderr, "404:page not found (%s)\n",
                         strerror (errno));
                return -1;
        }


        get_filename (req, &file_requested);
        strcpy (file_path, filepath); //it was commented before
        strcat (file_path,file_requested);   //it was strcpy instead of strcat

        ret = stat (file_path, &stbuf);
        if (ret) {
                fprintf (stderr, "Error in stat(): %s\n",
                         strerror (errno));
                goto out;
        }

        if (S_ISREG (stbuf.st_mode)) {
                file_fd = open (file_path, O_RDONLY);
                if (-1 == file_fd) {
                        fprintf (stderr, "Error while opening the file %s: %s\n",
                                 file_path, strerror (errno));
                        ret = -1;
                        goto out;
                }

                bytes_read = read (file_fd, buf, sizeof (buf));
                if (-1 == bytes_read) {
                        fprintf (stderr, "Error while reading the file: %s\n",
                                 strerror (errno));
                        close (file_fd);
                        ret = -1;
                        goto out;
                }
        } else if (S_ISDIR (stbuf.st_mode)) {
                dir = opendir (file_path);
                if (!dir) {
                        fprintf (stderr, "Error while opening the directory: %s\n",
                                 strerror (errno));
                        ret = -1;
                        goto out;
                }

                errno = 0;
                /* while (!errno) { */
                /*         entry = readdir (dir); */
                /*         if (errno == EBADF) { */
                /*                 fprintf (stderr, "Error while readdir (): %s\n", */
                /*                          strerror (errno)); */
                /*                 ret = -1; */
                /*                 goto out; */
                /*         } */

                /*         if ((!entry) && (errno == 0)) */
                /*                 goto write; */

                /*         entry->d_type = stbuf.st_mode; */
                /*         entry->d_off = telldir (dir); */
                /*         strncat (buf, entry->d_name, strlen (entry->d_name)); */
                /*         errno = 0; */
                /* } */
                do {
                        entry = readdir (dir);
                        if (entry) {
                                //entry->d_type = stbuf.st_mode;
                                entry->d_off = telldir (dir);
                                if (strcmp (entry->d_name, ".") && strcmp (entry->d_name, "..")) {
                                        strncat (buf, entry->d_name, strlen (entry->d_name));
                                        strcat (buf, "\n");
                                        length += strlen (entry->d_name);
                                        length++;
                                }
                        }
                } while (entry);
        } else {
                fprintf (stderr, "Neither a file nor a directory\n");
        }

write:
        if (S_ISREG (stbuf.st_mode)) {
                ret = write (fd, buf, bytes_read);
        } else if (S_ISDIR (stbuf.st_mode)) {
                ret = write (fd, buf, length);
        }

        if (-1 == ret) {
                fprintf (stderr, "Error while writing to the socket: %s\n",
                         strerror (errno));
                close (file_fd);
                ret = -1;
                goto out;
        }

out:
        if (file_fd != -1)
                close (file_fd);
        return ret;
}

void get_filename (char *request, char **tmp)
{
        char *filename = NULL;
        char *ptr = NULL;

        *tmp = strtok_r (request, " ", &ptr);
        *tmp = strtok_r (NULL, " ", &ptr);
}
