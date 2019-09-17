#include <iostream>
#include <cstdio>
#include <string>
#include <vector>
#include <thread>
#include <chrono>

// UART port configuration, adjust according to implementation
int baud_rate = 38400;
serial::bytesize_t byte_size = serial::eightbits;
serial::parity_t parity = serial::parity_odd;
serial::stopbits_t stopbits = serial::stopbits_one;
int inter_byte_timeout = 50;
int read_timeout_constant = 5000;
int read_timeout_multiplier = 10;
int write_timeout_constant = 50;
int write_timeout_multiplier = 10;

//methods
int on_init() {
    using namespace std::chrono_literals;
    std::this_thread::sleep_for(1s);
    byte init[10];
    byte recv[10]={0};
    init[0] = 0x00;
    int len = 4;
    *reinterpret_cast<word*>(init+1) = len;
    char test[10] = "UART";
    for (int i=0;i<len;++i) {
        init[3+i]=(byte)test[i];
        printf("%02x ",init[3+i]);
    }
    printf("\n");
    uart_send(init,3+len,recv,len);
    for (int i=0;i<len;++i) {
        printf("%02x ",recv[i]);
    }
    printf("\n");
    char *str = reinterpret_cast<char*>(recv);
    if (strcmp(str,test)) {
        printf("UART assertion failed\n");
        return 1;
    }
    return 0;
}
