BINOUT = ./bin/
PATHSRC = ./
PATHOBJS = $(BINOUT)
TARGET = $(BINOUT)mdmac

CC = psp-gcc
CXX = psp-gcc
AS = psp-as

CPP_FILES = $(wildcard $(PATHSRC)*.cpp)
PATHFILES = $(CPP_FILES) kcall.S

OBJS = $(notdir $(patsubst %.cpp, %.o, $(patsubst %.S, %.o, $(PATHFILES))))
OBJS := $(sort $(OBJS:%.o=$(PATHOBJS)%.o))

PSPSDK = $(shell psp-config --pspsdk-path)

CFLAGS = -I. -I$(PSPSDK)/include -I/usr/local/pspdev/psp/sdk/include -Os -G0 -Wall \
         -I./kernel/src -D_PSP_FW_VERSION=660 \
         -Wextra -Werror

CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti -std=c++11
ASFLAGS = $(CFLAGS) -x assembler-with-cpp

LDFLAGS = -L. -L$(PSPSDK)/lib -L/usr/local/pspdev/psp/sdk/lib \
          -Wl,-zmax-page-size=128 -Wl,-q \
          -specs=$(PSPSDK)/lib/prxspecs \
          -Wl,-T$(PSPSDK)/lib/linkfile.prx

LIBS = -lpspdebug -lpspdisplay -lpspge -lpspctrl \
       -lpspnet -lpspsdk -lpsppower -lc -lm

EXPORT_OBJ = $(PSPSDK)/lib/prxexports.o

PSP_EBOOT_SFO = $(BINOUT)PARAM.SFO
PSP_EBOOT_TITLE = Me Dmacplus Transfer

.PHONY: kernel

all: kernel $(TARGET).elf $(TARGET).prx $(BINOUT)EBOOT.PBP

kernel:
	$(MAKE) -C ./kernel

kcall.S: kernel
	@

$(TARGET).elf: $(OBJS) $(EXPORT_OBJ)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@ $(LIBS)
	psp-fixup-imports $@

$(TARGET).prx: $(TARGET).elf
	psp-prxgen $< $@

$(PATHOBJS)%.o: $(PATHSRC)%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(PATHOBJS)%.o: $(PATHSRC)%.S
	$(CC) $(ASFLAGS) -c $< -o $@

$(BINOUT)EBOOT.PBP: $(TARGET).elf
	mksfo "$(PSP_EBOOT_TITLE)" $(PSP_EBOOT_SFO)
	psp-strip $(TARGET).elf -o $(TARGET)_strip.elf
	pack-pbp $(BINOUT)EBOOT.PBP $(PSP_EBOOT_SFO) NULL \
	NULL NULL NULL \
	NULL $(TARGET)_strip.elf NULL
	rm -f $(TARGET)_strip.elf

clean:
	-rm -f $(TARGET).elf $(TARGET).prx $(OBJS) $(BINOUT)EBOOT.PBP $(PSP_EBOOT_SFO) kcall.S $(BINOUT)kcall.prx
	$(MAKE) -C ./kernel clean
