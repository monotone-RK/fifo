SRCS = fifo.v

TARGET = a.out
VCD = uut.vcd

IV = iverilog
GTK = gtkwave

all:
	$(IV) -o $(TARGET) $(SRCS)

run:
	vvp $(TARGET)

view:
	$(GTK) $(VCD) &

clean:
	rm -f $(TARGET) $(VCD)
