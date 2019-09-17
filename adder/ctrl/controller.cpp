#include <iostream>
#include <cstdio>
#include <fstream>
#include <serial/serial.h>
#include <vector>
#include <ctime>
typedef std::uint8_t byte;
typedef std::uint16_t word;
using namespace std;

serial::Serial serPort;

void uart_send(const byte *data, int send_count, byte* recv, int return_count) {
    serPort.write(data,send_count);
    if (!return_count) return;
    try {
        serPort.read(recv,return_count);
    } catch (std::exception &e) {
        cout<<"recv error:"<<e.what()<<endl;
    }
}
void uart_send(const std::vector<byte> data, byte* recv, int return_count) {
    uart_send(data.data(),data.size(),recv,return_count);
}
void uart_send(const std::string &data) { serPort.write(data); }
void uart_send(const byte *data, int size) { serPort.write(data,size); }
void uart_send(const std::vector<byte> &data) { serPort.write(data); }

#include "listener.h"

int init_port(char* port) {
    serPort.setPort(port);
    serPort.setBaudrate(baud_rate);
    serPort.setBytesize(byte_size);
    serPort.setParity(parity);
    serPort.setStopbits(stopbits);
    serPort.setTimeout(
        inter_byte_timeout,
        read_timeout_constant,
        read_timeout_multiplier,
        write_timeout_constant,
        write_timeout_multiplier
        );
    try {
        serPort.open();
    } catch (std::exception &e) {
        cout<<"failed to open port: "<<e.what()<<endl;
        return 1;
    }
    cout<<"initialized UART port on: "<<port<<endl;
    return 0;
}

int test_adder(int a, int b) {
    byte payload[6] = {0};
    byte recv[4] = {0};

    payload[0] = 0x01;
    *reinterpret_cast<word*>(payload+1) = a;
    *reinterpret_cast<word*>(payload+3) = b;
    uart_send(payload,5,recv,3);
    int r = *reinterpret_cast<word*>(recv);
    int c = recv[2];
    printf("a:%d\tb:%d\tans:%d\tcarry:%d\n",a,b,r,c);
    if (r==(word)(a+b) && c==(a+b)>>16) return 1;
    return 0;
}

void run() {
    int succ=1;
    srand(time(0));
    for (int i=0;i<10000;++i) {
        int a, b;
        a = rand()%0xffff;
        b = rand()%0xffff;
        if (!test_adder(a,b)) {
            cout<<"oops, test failed"<<endl;
            succ=0;
        }
    }
    if (succ) cout<<"test passed, congrats!"<<endl;
}

int main(int argc, char** argv) {
    if (argc<2) {
        cout << "usage: com-port" << endl;
        return 1;
    }
    char* comport = argv[1];
    if (init_port(comport)) return 1;
    if (on_init()) return 1;
    run();
    serPort.close();
}
