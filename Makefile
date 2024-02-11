roms := \
	pokered.gbc \
	pokeblue.gbc \
	pokeblue_debug.gbc
	pokered-fr.gbc \
	pokeblue-fr.gbc \
	pokeblue_debug-fr.gbc
patches := \
	pokered.patch \
	pokeblue.patch

rom_obj := \
	audio.o \
	home.o \
	main.o \
	maps.o \
	ram.o \
	text.o \
	gfx/pics.o \
	gfx/sprites.o \
	gfx/tilesets.o

pokered_obj        := $(rom_obj:.o=_red.o)
pokeblue_obj       := $(rom_obj:.o=_blue.o)
pokeblue_debug_obj := $(rom_obj:.o=_blue_debug.o)
pokered_vc_obj     := $(rom_obj:.o=_red_vc.o)
pokeblue_vc_obj    := $(rom_obj:.o=_blue_vc.o)


### Build tools

ifeq (,$(shell which sha1sum))
SHA1 := shasum
else
SHA1 := sha1sum
endif

RGBDS ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink


### Build targets

.SUFFIXES:
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:
.PHONY: all red blue blue_debug clean tidy compare tools

all: $(roms)
red:        pokered.gbc
blue:       pokeblue.gbc
blue_debug: pokeblue_debug.gbc
red-fr:     pokered.gbc
blue-fr:    pokeblue.gbc
blue_d-fr:  pokeblue_debug.gbc

clean: tidy
	find gfx \
	     \( -iname '*.1bpp' \
	        -o -iname '*.2bpp' \
	        -o -iname '*.pic' \) \
	     -delete

tidy:
	$(RM) $(roms) \
	      $(roms:.gbc=.sym) \
	      $(roms:.gbc=.map) \
	      $(patches) \
	      $(patches:.patch=_vc.gbc) \
	      $(patches:.patch=_vc.sym) \
	      $(patches:.patch=_vc.map) \
	      $(patches:%.patch=vc/%.constants.sym) \
	      $(pokered_obj) \
	      $(pokeblue_obj) \
	      $(pokeblue_debug_obj) \
	      $(pokered-fr_obj) \
	      $(pokeblue-fr_obj) \
	      $(pokeblue_d-fr_obj) \
	      rgbdscheck.o
	$(MAKE) clean -C tools/

compare: $(roms) $(patches)
	@$(SHA1) -c roms.sha1

tools:
	$(MAKE) -C tools/


RGBASMFLAGS = -hL -Q8 -P includes.asm -Weverything -Wnumeric-string=2 -Wtruncation=1
# Create a sym/map for debug purposes if `make` run with `DEBUG=1`
ifeq ($(DEBUG),1)
RGBASMFLAGS += -E
endif

$(pokered_obj):        RGBASMFLAGS += -D _RED
$(pokeblue_obj):       RGBASMFLAGS += -D _BLUE
$(pokeblue_debug_obj): RGBASMFLAGS += -D _BLUE -D _DEBUG
$(pokered-fr_obj):     RGBASMFLAGS += -D _RED -D _FRENCH
$(pokeblue-fr_obj):    RGBASMFLAGS += -D _BLUE -D _FRENCH
$(pokeblue_d-fr_obj):  RGBASMFLAGS += -D _BLUE -D _DEBUG -D _FRENCH

%.patch: vc/%.constants.sym %_vc.gbc %.gbc vc/%.patch.template
	tools/make_patch $*_vc.sym $^ $@

rgbdscheck.o: rgbdscheck.asm
	$(RGBASM) -o $@ $<

# The dep rules have to be explicit or else missing files won't be reported.
# As a side effect, they're evaluated immediately instead of when the rule is invoked.
# It doesn't look like $(shell) can be deferred so there might not be a better way.
define DEP
$1: $2 $$(shell tools/scan_includes $2) | includes.asm rgbdscheck.o
	$$(RGBASM) $$(RGBASMFLAGS) -o $$@ $$<
endef

# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean tidy tools,$(MAKECMDGOALS)))

$(info $(shell $(MAKE) -C tools))

# Dependencies for objects (drop _red and _blue from asm file basenames)
$(foreach obj, $(pokered_obj), $(eval $(call DEP,$(obj),$(obj:_red.o=.asm))))
$(foreach obj, $(pokeblue_obj), $(eval $(call DEP,$(obj),$(obj:_blue.o=.asm))))
$(foreach obj, $(pokeblue_debug_obj), $(eval $(call DEP,$(obj),$(obj:_blue_debug.o=.asm))))
$(foreach obj, $(pokered-fr_obj), $(eval $(call DEP,$(obj),$(obj:_red-fr.o=.asm))))
$(foreach obj, $(pokeblue-fr_obj), $(eval $(call DEP,$(obj),$(obj:_blue-fr.o=.asm))))
$(foreach obj, $(pokeblue_d-fr_obj), $(eval $(call DEP,$(obj),$(obj:_blue_d-fr.o=.asm))))

# Dependencies for VC files that need to run scan_includes
%.constants.sym: %.constants.asm $(shell tools/scan_includes %.constants.asm) | includes.asm rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) $< > $@

endif


%.asm: ;


pokered_pad        = 0x00
pokeblue_pad       = 0x00
pokeblue_debug_pad = 0xff
pokered-fr_pad     = 0x00
pokeblue-fr_pad    = 0x00
pokeblue_d-fr_pad  = 0xff

pokered_opt        = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON RED"
pokeblue_opt       = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON BLUE"
pokeblue_debug_opt = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON BLUE"
pokered-fr_opt     = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON ROUGE"
pokeblue-fr_opt    = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON BLEUE"
pokeblue_d-fr_opt  = -Cjv -n 0 -k 01 -l 0x33 -m 0x1B -r 03 -t "POKEMON BLEUE"

%.gbc: $$(%_obj) layout.link
	$(RGBLINK) -p $($*_pad) -d -m $*.map -n $*.sym -l layout.link -o $@ $(filter %.o,$^)
	$(RGBFIX) -p $($*_pad) $($*_opt) $@


### Misc file-specific graphics rules

gfx/battle/move_anim_0.2bpp: tools/gfx += --trim-whitespace
gfx/battle/move_anim_1.2bpp: tools/gfx += --trim-whitespace

gfx/intro/blue_jigglypuff_1.2bpp: rgbgfx += -Z
gfx/intro/blue_jigglypuff_2.2bpp: rgbgfx += -Z
gfx/intro/blue_jigglypuff_3.2bpp: rgbgfx += -Z
gfx/intro/red_nidorino_1.2bpp: rgbgfx += -Z
gfx/intro/red_nidorino_2.2bpp: rgbgfx += -Z
gfx/intro/red_nidorino_3.2bpp: rgbgfx += -Z
gfx/intro/gengar.2bpp: rgbgfx += -Z
gfx/intro/gengar.2bpp: tools/gfx += --remove-duplicates --preserve=0x19,0x76

gfx/credits/the_end.2bpp: tools/gfx += --interleave --png=$<

gfx/slots/red_slots_1.2bpp: tools/gfx += --trim-whitespace
gfx/slots/blue_slots_1.2bpp: tools/gfx += --trim-whitespace

gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace
gfx/tilesets/reds_house.2bpp: tools/gfx += --preserve=0x48

gfx/trade/game_boy.2bpp: tools/gfx += --remove-duplicates


### Catch-all graphics rules

%.png: ;

%.2bpp: %.png
	$(RGBGFX) $(rgbgfx) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -o $@ $@)

%.1bpp: %.png
	$(RGBGFX) $(rgbgfx) -d1 -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -d1 -o $@ $@)

%.pic: %.2bpp
	tools/pkmncompress $< $@
