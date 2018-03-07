#include <unistd.h>

int main(int argc, char ** argv) {
    uid_t olduid = getuid();
    gid_t oldgid = getgid();

    setuid(0);
    setgid(0);

    int result = execvp(argv[1], &argv[1]);

    setuid(olduid);
    setgid(oldgid);

    return result;
}
