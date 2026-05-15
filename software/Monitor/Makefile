# Universal Monitor for 68k8 Rev1
# ROM: 0x00080000-0x0008ffff, W27C512 x1 / 8-bit bus

.SUFFIXES: .asm .p .lst

ASL   := asl
P2BIN := p2bin
P2HEX := p2hex

TARGET := unimon_68000

DEVS := dev/dev_6850.asm dev/dev_68681.asm dev/dev_68901.asm dev/dev_emily.asm
SRCS := $(TARGET).asm config.inc common.inc $(DEVS)

all: $(TARGET).rev1.bin $(TARGET).rev1.hex $(TARGET).lst

$(TARGET).p $(TARGET).lst: $(SRCS)
	$(ASL) -L $(TARGET).asm

$(TARGET).rev1.bin: $(TARGET).p
	$(P2BIN) -r 0x80000-0x8ffff -l 0xff $(TARGET).p $@

$(TARGET).rev1.hex: $(TARGET).p
	$(P2HEX) -F Intel -r 0x80000-0x8ffff $(TARGET).p $@

check: all
	@echo "generated files:"
	@ls -l $(TARGET).rev1.bin $(TARGET).rev1.hex $(TARGET).lst

clean:
	rm -f *.p *.bin *.hex *.lst
