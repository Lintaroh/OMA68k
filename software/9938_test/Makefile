.SUFFIXES: .asm .p .lst

ASL   := ../psg_test/tools/asl.exe
P2BIN := ../psg_test/tools/p2bin.exe
P2HEX := ../psg_test/tools/p2hex.exe

TARGET := 9938_test

SRCS := $(TARGET).asm

all: $(TARGET).bin $(TARGET).hex $(TARGET).lst

$(TARGET).p $(TARGET).lst: $(SRCS)
	$(ASL) -L $(TARGET).asm

$(TARGET).bin: $(TARGET).p
	$(P2BIN) -r 0x00400-0x7CFFF -l 0xff $(TARGET).p $@

$(TARGET).hex: $(TARGET).p
	$(P2HEX) -F Intel -r 0x00400-0x7CFFF $(TARGET).p $@

check: all
	@echo "generated files:"
	@ls -l $(TARGET).bin $(TARGET).hex $(TARGET).lst

clean:
	rm -f *.p *.bin *.hex *.lst
