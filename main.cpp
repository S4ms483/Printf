extern "C" {
    void my_printf(const char* str, ...);
}

int main() {
    my_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127, -1, "love", 3802, 100, 33, 127);
}