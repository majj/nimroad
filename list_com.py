
import serial
import serial.tools.list_ports


def test():
    
    plist = list(serial.tools.list_ports.comports())
    print("RS232 Ports: ", end="")
    for p in plist:
        print(p[0], end=",")
    print()
    
if __name__ == "__main__":
    test()