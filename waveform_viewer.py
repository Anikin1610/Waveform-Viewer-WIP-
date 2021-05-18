import matplotlib.pyplot as plt
import serial
import numpy as np

def update_plot(time_vec, sr_data, line):
    if (line == []):
        plt.ion()
        fig = plt.figure()
        ax = fig.add_subplot(1, 1, 1)
        line_fn,  = ax.plot(sr_data)
        plt.ylim(0, 255)
        plt.ylabel('Amplitude')
        plt.xlabel('Time')
        plt.title('Waveform Viewer')
        plt.show()
        return line_fn
    else:
        line.set_ydata(sr_data)
        plt.pause(0.1)
        return line

if __name__ == '__main__':
    time_vec = np.linspace(0, 19)
    line = []
    plot_data = np.zeros(1000)
    try:
        while True:
            fpga_link = serial.Serial('/dev/ttyUSB1', 19200, serial.EIGHTBITS, serial.PARITY_NONE, serial.STOPBITS_ONE, 1.0)
            bytesToRead = fpga_link.inWaiting()
            data = fpga_link.read(bytesToRead)
            if data != b'':
                print(data)
                plot_data = np.roll(plot_data, -(bytesToRead))
                for i in range(bytesToRead):
                    plot_data[999 - i] = int(data[i])
                line = update_plot(time_vec, plot_data, line)
    except KeyboardInterrupt:
        print('Program Terminated!')
