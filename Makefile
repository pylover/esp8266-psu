############################################################# 
# Discard this section from all parent makefiles
# Expected variables (with automatic defaults):
#   CSRCS (all "C" files in the dir)
#   SUBDIRS (all subdirs with a Makefile)
#   GEN_LIBS - list of libs to be generated ()
#   GEN_IMAGES - list of object file images to be generated ()
#   GEN_BINS - list of binaries to be generated ()
#   COMPONENTS_xxx - a list of libs/objs in the form
#     subdir/lib to be extracted and rolled up into
#     a generated lib/image xxx.a ()
#

HOST ?= amp.psu
COMPILE ?= gcc

SPI_SIZE_MAP := 6
TARGET = eagle
#FLAVOR = release
FLAVOR = debug

#EXTRA_CCFLAGS += -u

ifndef PDIR # {
GEN_IMAGES= eagle.app.v6.out
GEN_BINS= eagle.app.v6.bin
SPECIAL_MKTARGETS=$(APP_MKTARGETS)
SUBDIRS=    \
	user \
	ringbuffer \
	httpd \
	http \
	uns 

endif # } PDIR

BINDIR = ./bin
APPDIR = .
LDDIR = $(SDK_PATH)/ld

INDEXHTML_SECTOR_MAP2 = 0x70
INDEXHTML_SECTOR_MAP4 = 0x100
INDEXHTML_SECTOR_MAP6 = 0x200
INDEXHTML = webui/public/build/index.bundle.html
INDEXHTML_BIN = $(INDEXHTML).bin
INDEXHTML_DEFLATE = $(INDEXHTML).deflate

CCFLAGS += \
	-Os \
	-DSPI_SIZE_MAP=$(SPI_SIZE_MAP) \
	-DINDEXHTML_SECTOR_MAP6=$(INDEXHTML_SECTOR_MAP6) \
	-DINDEXHTML_SECTOR_MAP4=$(INDEXHTML_SECTOR_MAP4) \
	-DINDEXHTML_SECTOR_MAP2=$(INDEXHTML_SECTOR_MAP2) 

TARGET_LDFLAGS =		\
	-nostdlib		\
	-Wl,-EL \
	--longcalls \
	--text-section-literals

ifeq ($(FLAVOR),debug)
    TARGET_LDFLAGS += -g -O2
endif

ifeq ($(FLAVOR),release)
    TARGET_LDFLAGS += -g -O0
endif

COMPONENTS_eagle.app.v6 = \
	user/libuser.a \
	ringbuffer/libringbuffer.a \
	httpd/libhttpd.a \
	http/libhttp.a \
	uns/libuns.a

LINKFLAGS_eagle.app.v6 = \
	-L$(SDK_PATH)/lib        \
	-nostdlib	\
    -T$(LD_FILE)   \
	-Wl,--no-check-sections	\
	-Wl,--gc-sections	\
    -u call_user_start	\
	-Wl,-static						\
	-Wl,--start-group					\
	-lc					\
	-lgcc					\
	-lphy	\
	-lpp	\
	-lnet80211	\
	-llwip	\
	-lwpa	\
	-lcrypto	\
	-lmain	\
	-lupgrade\
	-ldriver \
	-lhal					\
	$(DEP_LIBS_eagle.app.v6)					\
	-Wl,--end-group

#	-ljson	\
#	-lsmartconfig \
#	-lmbedtls	\
#	-lpwm	\
	
DEPENDS_eagle.app.v6 = \
                $(LD_FILE) \
                $(LDDIR)/eagle.rom.addr.v6.ld

#############################################################
# Configuration i.e. compile options etc.
# Target specific stuff (defines etc.) goes in here!  # Generally values applying to a tree are captured in the
#   makefile at its root level - these are then overridden
#   for a subtree within the makefile rooted therein
#

#UNIVERSAL_TARGET_DEFINES =		\

# Other potential configuration flags include:
#	-DTXRX_TXBUF_DEBUG
#	-DTXRX_RXBUF_DEBUG
#	-DWLAN_CONFIG_CCX
CONFIGURATION_DEFINES =	-DICACHE_FLASH \
                        -DGLOBAL_DEBUG_ON

DEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)

DDEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)


#############################################################
# Recursion Magic - Don't touch this!!
#
# Each subtree potentially has an include directory
#   corresponding to the common APIs applicable to modules
#   rooted at that subtree. Accordingly, the INCLUDE PATH
#   of a module can only contain the include directories up
#   its parent path, and not its siblings
#
# Required for each makefile to inherit from the parent
#

INCLUDES := $(INCLUDES) \
	-I $(PDIR)include \
	-I $(PDIR)/ringbuffer \
	-I $(PDIR)/httpd/include \
	-I $(PDIR)/http/include \
	-I $(PDIR)/uns/include \
	-I $(PDIR)/debug

PDIR = $(SDK_PATH)/
sinclude $(SDK_PATH)/Makefile

#################
# ESPTOOL options
#################
BAUDRATE := 115200
FLASH_BAUDRATE := 460800
PORT := /dev/ttyUSB0
ESPTOOL = esptool.py --baud $(FLASH_BAUDRATE) --port $(PORT)
ESPTOOL_WRITE = $(ESPTOOL)  write_flash -u --flash_mode qio --flash_freq 40m
ESPTOOL_WRITE_DIO = $(ESPTOOL)  write_flash -u --flash_mode dio --flash_freq 40m

############################
# Project specific variables
############################
MAP2FILE1 = $(BINDIR)/upgrade/user2.1024.new.2.bin
MAP2FILE2 = $(BINDIR)/upgrade/user1.1024.new.2.bin

MAP4FILE1 = $(BINDIR)/upgrade/user2.4096.new.4.bin
MAP4FILE2 = $(BINDIR)/upgrade/user1.4096.new.4.bin

MAP6FILE1 = $(BINDIR)/upgrade/user2.4096.new.6.bin
MAP6FILE2 = $(BINDIR)/upgrade/user1.4096.new.6.bin

############################
# Common flash & debug tools
############################

.PHONY: erase_flash
erase_flash:
	$(ESPTOOL) erase_flash

.PHONY: screen
screen:
	screen $(PORT) $(BAUDRATE)

.PHONY: toggleboot
toggleboot:
	-uns http toggle $(HOST)/boots

########
# Web UI
########
.PHONY: webui
webui:
	-webui/build.sh
	
.PHONY: upload-webui
upload-webui: webui
	-uns http post $(HOST) :$(INDEXHTML_DEFLATE)

##################
# SPI MAP 2 common
##################
.PHONY: boot_user1map2
boot_user1map2:
	$(ESPTOOL) read_flash 0xff000 0x1000 $(BINDIR)/map2-user1-0ff.bin
	printf '\x01' \
		| dd of=$(BINDIR)/map2-user1-0ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 1MB \
		0xff000 $(BINDIR)/map2-user1-0ff.bin

.PHONY: boot_user2map2
boot_user2map2:
	$(ESPTOOL) read_flash 0xff000 0x1000 $(BINDIR)/map2-user2-0ff.bin
	printf '\x00' \
		| dd of=$(BINDIR)/map2-user2-0ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 1MB \
		0xff000 $(BINDIR)/map2-user2-0ff.bin

.PHONY: fotamap2
fotamap2: map2user1 map2user2 
	-uns http upgrade $(HOST)/firmware :$(MAP2FILE$(shell uns h info $(HOST) \
		| grep --color=never -oP '^Boot:\s+\w+\K\d'))


###############
# SPI MAP 2 QIO
###############
map2user1:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=2

map2user2:
	make clean
	make COMPILE=gcc BOOT=new APP=2 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=2

flash_map2user1: map2user1
	$(ESPTOOL_WRITE) --flash_size 1MB  \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.1024.new.2.bin \
		0xfc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0xfb000 $(SDK_PATH)/bin/blank.bin \
		0xfe000 $(SDK_PATH)/bin/blank.bin

flash_map2user2: map2user2
	$(ESPTOOL_WRITE) --flash_size 1MB  \
		0x81000  $(BINDIR)/upgrade/user2.1024.new.2.bin \


.PHONY: cleanup_map2user1_params
cleanup_map2user1_params:
	$(ESPTOOL_WRITE) --flash_size 1MB  \
		0x78000 $(SDK_PATH)/bin/blank.bin \
		0x79000 $(SDK_PATH)/bin/blank.bin \
		0x7a000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map2webui
flash_map2webui: webui
	$(ESPTOOL_WRITE) --flash_size 1MB  \
		$(INDEXHTML_SECTOR_MAP2)000 $(INDEXHTML_BIN)
		
###############
# SPI MAP 2 DIO
###############
.PHONY: map2user1dio
map2user1dio:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=DIO SPI_SIZE_MAP=2

.PHONY: flash_map2user1dio
flash_map2user1dio: map2user1dio
	$(ESPTOOL_WRITE_DIO) --flash_size 1MB  \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.1024.new.2.bin \
		0xfc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0xfb000 $(SDK_PATH)/bin/blank.bin \
		0xfe000 $(SDK_PATH)/bin/blank.bin

.PHONY: flash_map2webuidio
flash_map2webuidio: webui
	$(ESPTOOL_WRITE_DIO) --flash_size 1MB  \
		$(INDEXHTML_SECTOR_MAP2)000 $(INDEXHTML_BIN)

##################
# SPI MAP 6 common
##################
.PHONY: boot_user1map6
boot_user1map6:
	$(ESPTOOL) read_flash 0x3ff000 0x1000 $(BINDIR)/map6-user1-3ff.bin
	printf '\x01' \
		| dd of=$(BINDIR)/map6-user1-3ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 4MB-c1 \
		0x3ff000 $(BINDIR)/map6-user1-3ff.bin

.PHONY: boot_user2map6
boot_user2map6:
	$(ESPTOOL) read_flash 0x3ff000 0x1000 $(BINDIR)/map6-user2-3ff.bin
	printf '\x00' \
		| dd of=$(BINDIR)/map6-user2-3ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 4MB-c1 \
		0x3ff000 $(BINDIR)/map6-user2-3ff.bin

.PHONY: fotamap6
fotamap6: map6user1 map6user2 
	-uns http upgrade $(HOST)/firmware :$(MAP6FILE$(shell uns h info $(HOST) \
		| grep --color=never -oP '^Boot:\s+\w+\K\d'))


###############
# SPI MAP 6 QIO
###############
.PHONY: map6user1
map6user1:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=6

.PHONY: map6user2
map6user2:
	make clean
	make COMPILE=gcc BOOT=new APP=2 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=6

.PHONY: flash_map6user1
flash_map6user1: map6user1
	$(ESPTOOL_WRITE) --flash_size 4MB-c1  \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.4096.new.6.bin \
		0x3fc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0x3fb000 $(SDK_PATH)/bin/blank.bin \
		0x3fe000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map6user2
flash_map6user2: map6user2
	$(ESPTOOL_WRITE) --flash_size 4MB-c1  \
		0x101000  $(BINDIR)/upgrade/user2.4096.new.6.bin

.PHONY: flash_map6webui
flash_map6webui: webui
	$(ESPTOOL_WRITE) --flash_size 4MB-c1  \
		$(INDEXHTML_SECTOR_MAP6)000 $(INDEXHTML_BIN)

.PHONY: cleanup_map6params
cleanup_map6params:
	$(ESPTOOL_WRITE) --flash_size 4MB-c1  \
		0xf8000 $(SDK_PATH)/bin/blank.bin \
		0xf9000 $(SDK_PATH)/bin/blank.bin \
		0xfa000 $(SDK_PATH)/bin/blank.bin 

###############
# SPI MAP 6 DIO
###############
.PHONY: map6user1dio
map6user1dio:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=DIO SPI_SIZE_MAP=6

.PHONY: flash_map6user1dio
flash_map6user1dio: map6user1dio
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB-c1  \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.4096.new.6.bin \
		0x3fc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0x3fb000 $(SDK_PATH)/bin/blank.bin \
		0x3fe000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map6webuidio
flash_map6webuidio: webui
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB-c1  \
		$(INDEXHTML_SECTOR_MAP6)000 $(INDEXHTML_BIN) 

.PHONY: cleanup_map6paramsdio
cleanup_map6paramsdio:
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB-c1  \
		0xf8000 $(SDK_PATH)/bin/blank.bin \
		0xf9000 $(SDK_PATH)/bin/blank.bin \
		0xfa000 $(SDK_PATH)/bin/blank.bin 


##################
# SPI MAP 4 common
##################
.PHONY: boot_user1map4
boot_user1map4:
	$(ESPTOOL) read_flash 0x3ff000 0x1000 $(BINDIR)/map4-user1-3ff.bin
	printf '\x01' \
		| dd of=$(BINDIR)/map4-user1-3ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 4MB \
		0x3ff000 $(BINDIR)/map4-user1-3ff.bin

.PHONY: boot_user2map4
boot_user2map4:
	$(ESPTOOL) read_flash 0x3ff000 0x1000 $(BINDIR)/map4-user2-3ff.bin
	printf '\x00' \
		| dd of=$(BINDIR)/map4-user2-3ff.bin bs=1 count=1 conv=notrunc
	$(ESPTOOL_WRITE) --flash_size 4MB \
		0x3ff000 $(BINDIR)/map4-user2-3ff.bin

.PHONY: fotamap4
fotamap4: map4user1 map4user2
	-uns http upgrade $(HOST)/firmware :$(MAP4FILE$(shell uns h info $(HOST) \
		| grep --color=never -oP '^Boot:\s+\w+\K\d'))


###############
# SPI MAP 4 QIO
###############
.PHONY: map4user1
map4user1:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=4

.PHONY: map6user2
map4user2:
	make clean
	make COMPILE=gcc BOOT=new APP=2 SPI_SPEED=40 SPI_MODE=QIO SPI_SIZE_MAP=4

.PHONY: flash_map4user1
flash_map4user1: map4user1
	$(ESPTOOL_WRITE) --flash_size 4MB  \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.4096.new.4.bin \
		0x3fc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0x3fb000 $(SDK_PATH)/bin/blank.bin \
		0x3fe000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map4user2
flash_map4user2: map4user2
	$(ESPTOOL_WRITE) --flash_size 4MB  \
		0x081000  $(BINDIR)/upgrade/user2.4096.new.4.bin

.PHONY: cleanup_map4params
cleanup_map4params:
	$(ESPTOOL_WRITE) --flash_size 4MB  \
		0x7C000 $(SDK_PATH)/bin/blank.bin \
		0x7D000 $(SDK_PATH)/bin/blank.bin \
		0x7E000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map4webui
flash_map4webui: webui
	$(ESPTOOL_WRITE) --flash_size 4MB \
		$(INDEXHTML_SECTOR_MAP4)000 $(INDEXHTML_BIN)


###############
# SPI MAP 4 DIO
###############
.PHONY: map4user1dio
map4user1dio:
	make clean
	make COMPILE=gcc BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=DIO SPI_SIZE_MAP=4

.PHONY: map6user2dio
map4user2dio:
	make clean
	make COMPILE=gcc BOOT=new APP=2 SPI_SPEED=40 SPI_MODE=DIO SPI_SIZE_MAP=4

.PHONY: flash_map4user1dio
flash_map4user1dio: map4user1dio
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB \
		0x0 	$(SDK_PATH)/bin/boot_v1.7.bin \
		0x1000  $(BINDIR)/upgrade/user1.4096.new.4.bin \
		0x3fc000 $(SDK_PATH)/bin/esp_init_data_default_v08.bin \
		0x3fb000 $(SDK_PATH)/bin/blank.bin \
		0x3fe000 $(SDK_PATH)/bin/blank.bin 

.PHONY: flash_map4user2dio
flash_map4user2dio: map4user2dio
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB \
		0x081000  $(BINDIR)/upgrade/user2.4096.new.4.bin

.PHONY: flash_map4webuidio
flash_map4webuidio: webui
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB \
		$(INDEXHTML_SECTOR_MAP4)000 $(INDEXHTML_BIN)


.PHONY: cleanup_map4paramsdio
cleanup_map4paramsdio:
	$(ESPTOOL_WRITE_DIO) --flash_size 4MB  \
		0x7C000 $(SDK_PATH)/bin/blank.bin \
		0x7D000 $(SDK_PATH)/bin/blank.bin \
		0x7E000 $(SDK_PATH)/bin/blank.bin 



