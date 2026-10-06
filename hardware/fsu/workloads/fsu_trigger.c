/* Reflective-injection pattern: write code into an RWX page, then execute it.
 * Build: gcc -O0 -static fsu_trigger.c -o fsu_trigger
 * With -DUSE_CLFLUSH the written line is flushed to DRAM before execution. */
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

int main(void) {
    printf("[System] Normal userspace execution running.\n");
    void *buffer = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC,
                        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (buffer == MAP_FAILED) { perror("mmap failed"); return 1; }

    printf("[Payload] Injecting payload into allocated memory...\n");
    unsigned char shellcode[] = { 0x90, 0x90, 0xC3 }; /* NOP, NOP, RET */
    memcpy(buffer, shellcode, sizeof(shellcode));
#ifdef USE_CLFLUSH
    __asm__ volatile("clflush (%0)" :: "r"(buffer) : "memory");
    __asm__ volatile("mfence" ::: "memory");
#endif

    printf("[Malware] Executing payload from dynamically written page...\n");
    void (*exec_payload)(void) = (void (*)(void))buffer;
    exec_payload();

    /* Must NOT print if the FSU stalls the CPU */
    printf("[FAILURE] Malware finished execution without intervention.\n");
    return 0;
}
