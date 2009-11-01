#! ./pts-tcc -run
int printf(char const*fmt, ...);
double sqrt(double x);
int main() {
  printf("Hello, World!\n");
  return sqrt(36) * 7;
}
