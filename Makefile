# Makefile for building and installing the pprzbus ocaml bindings

DESTDIR ?=

#ifneq ($(DESTDIR),)
#OCAMLFINDFLAGS += -destdir $(DESTDIR)
#endif

# Set to "y" to enable backwards compatibility symlink creation
COMPAT_SYMLINK_CREATE ?= n

# Symlink source path modifier between $(DESTDIR)/`ocamlc -where`
# and [glib]pprzbus/PKGFILES
# For linux, nothing; for darwin "site-lib/" with trailing slash
COMPAT_SYMLINK_SRCMOD ?=

# Specify default Macports path on OS X
OSX_MACPORTS_PREFIX ?= /opt/local

DEBUG ?= n


OCAMLC = ocamlc
OCAMLMLI = ocamlc
OCAMLOPT = ocamlopt
OCAMLDEP = ocamldep
OCAMLMKLIB = ocamlmklib

ifeq ($(DEBUG),y)
OCAMLFLAGS = -g
else
OCAMLFLAGS =
endif

OCAMLOPTFLAGS=
CFLAGS+=-Wall
OCAMLINC=-I $(shell ocamlc -where)

GLIB_CFLAGS = $(shell pkg-config --cflags glib-2.0)

PPRZBUS_CINC = $(shell pkg-config --cflags-only-I pprzbus-glib)

PPRZBUS_CLIBS = $(shell pkg-config --libs pprzbus)
ifeq ($(strip $(PPRZBUS_CLIBS)),)
PPRZBUS_CLIBS = -lpprzbus
endif

PPRZBUSGLIB_CLIBS=$(shell pkg-config --libs pprzbus-glib)
ifeq ($(strip $(PPRZBUSGLIB_CLIBS)),)
PPRZBUSGLIB_CLIBS = -lglibpprzbus -lglib-2.0
endif

PPRZBUSTCL_CLIBS=$(shell pkg-config --libs pprzbus-tcl)
ifeq ($(strip $(PPRZBUSTCL_CLIBS)),)
PPRZBUSTCL_CLIBS = -ltclpprzbus
endif

REDIS_LDFLAGS = $(shell pkg-config --libs hiredis 2> /dev/null)

# at least on Debian this is a symlink to the latest tcl version if tcl-dev is installed
#TCLVERS = `perl -e '@_=sort map (m|/usr/lib/libtcl(\d\.\d)\.so|, glob ("/usr/lib/libtcl*")); print pop @_'`
TCLVERS:= $(shell perl -e '@_=sort map (m|/usr/lib/libtcl(\d\.\d)\.so|, glob ("/usr/lib/libtcl*")); print pop @_')
ifndef TCLVERS
TCLVERS:= $(shell perl -e '@_=sort map (m|/usr/lib64/libtcl(\d\.\d)\.so|, glob ("/usr/lib64/libtcl*")); print pop @_')
endif
ifndef TCLVERS
#TCLVERS=8.4
TCLVERS=
endif

TKINC = -I/usr/include/tcl$(TCLVERS)

# by default use fPIC on all systems
FPIC ?= -fPIC

uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
ifeq ($(uname_S),Darwin)
  LIBRARYS = -L$(OSX_MACPORTS_PREFIX)/lib
  PPRZBUS_CINC += -I$(OSX_MACPORTS_PREFIX)/include
endif


PPRZBUS = pprzbus.ml pprzbusLoop.ml

PPRZBUSCMO= $(PPRZBUS:.ml=.cmo)
PPRZBUSCMI= $(PPRZBUS:.ml=.cmi)
PPRZBUSMLI= $(PPRZBUS:.ml=.mli)
PPRZBUSCMX= $(PPRZBUS:.ml=.cmx)

GLIBPPRZBUS = pprzbus.ml glibPprzbus.ml

GLIBPPRZBUSCMO= $(GLIBPPRZBUS:.ml=.cmo)
GLIBPPRZBUSCMI= $(GLIBPPRZBUS:.ml=.cmi)
GLIBPPRZBUSMLI= $(GLIBPPRZBUS:.ml=.mli)
GLIBPPRZBUSCMX= $(GLIBPPRZBUS:.ml=.cmx)

TKPPRZBUS = pprzbus.ml tkPprzbus.ml

TKPPRZBUSCMO= $(TKPPRZBUS:.ml=.cmo)
TKPPRZBUSCMI= $(TKPPRZBUS:.ml=.cmi)
TKPPRZBUSMLI= $(TKPPRZBUS:.ml=.mli)
TKPPRZBUSCMX= $(TKPPRZBUS:.ml=.cmx)


PPRZBUSLIBS = pprzbus-ocaml.cma pprzbus-ocaml.cmxa
GLIBPPRZBUSLIBS = glibpprzbus-ocaml.cma glibpprzbus-ocaml.cmxa
TKLIBS = tkpprzbus-ocaml.cma tkpprzbus-ocaml.cmxa

PPRZBUSSTATIC = libpprzbus-ocaml.a pprzbus-ocaml.a
GLIBPPRZBUSSTATIC = libglibpprzbus-ocaml.a glibpprzbus-ocaml.a
TKPPRZBUSSTATIC = libtkpprzbus-ocaml.a tkpprzbus-ocaml.a
LIBS = pprzbus-ocaml.cma glibpprzbus-ocaml.cma
XLIBS = pprzbus-ocaml.cmxa glibpprzbus-ocaml.cmxa


all : $(LIBS) $(XLIBS) $(TKLIBS)

deb :
	dpkg-buildpackage -rfakeroot

pprzbus : $(PPRZBUSLIBS)
glibpprzbus : $(GLIBPPRZBUSLIBS)
tkpprzbus : $(TKLIBS)

PPRZBUS_ALL_LIBS = $(PPRZBUSLIBS) $(PPRZBUSSTATIC) dllpprzbus-ocaml.so
GLIBPPRZBUS_ALL_LIBS = $(GLIBPPRZBUSLIBS) $(GLIBPPRZBUSSTATIC) dllglibpprzbus-ocaml.so
TKPPRZBUS_ALL_LIBS = $(TKPPRZBUSLIBS) $(TKPPRZBUSSTATIC) dlltkpprzbus-ocaml.so

PPRZBUS_INST_FILES = $(PPRZBUSMLI) $(PPRZBUSCMI) $(PPRZBUSCMX) $(PPRZBUS_ALL_LIBS)
GLIBPPRZBUS_INST_FILES = $(GLIBPPRZBUSMLI) $(GLIBPPRZBUSCMI) $(GLIBPPRZBUSCMX) $(GLIBPPRZBUS_ALL_LIBS)
TKPPRZBUS_INST_FILES = $(TKPPRZBUSMLI) $(TKPPRZBUSCMI) $(TKPPRZBUSCMX) $(TKPPRZBUS_ALL_LIBS)

install : $(PPRZBUS_INST_FILES) $(GLIBPPRZBUS_INST_FILES) $(TKPPRZBUS_INST_FILES)
	mv META.pprzbus META && ocamlfind install $(OCAMLFINDFLAGS) pprzbus META $(PPRZBUS_INST_FILES) && mv META META.pprzbus || (mv META META.pprzbus && exit 1)
	mv META.glibpprzbus META && ocamlfind install $(OCAMLFINDFLAGS) glibpprzbus META $(GLIBPPRZBUS_INST_FILES) && mv META META.glibpprzbus || (mv META META.glibpprzbus && exit 1)
	mv META.tkpprzbus META && ocamlfind install $(OCAMLFINDFLAGS) tkpprzbus META $(TKPPRZBUS_INST_FILES) && mv META META.tkpprzbus || (mv META META.tkpprzbus && exit 1)
ifeq ($(COMPAT_SYMLINK_CREATE), y)
	# make some symlinks for backwards compatibility
	@echo "Creating symlinks for backwards compatibility..."
	$(foreach file,$(PPRZBUSLIBS) $(PPRZBUSSTATIC) $(PPRZBUSCMI) $(PPRZBUSMLI), \
		cd $(DESTDIR)/`ocamlc -where`; ln -fs $(COMPAT_SYMLINK_SRCMOD)pprzbus/$(file) $(file);)
	$(foreach file,$(GLIBPPRZBUSLIBS) $(GLIBPPRZBUSSTATIC) glibPprzbus.cmi, \
		cd $(DESTDIR)/`ocamlc -where`; ln -fs $(COMPAT_SYMLINK_SRCMOD)glibpprzbus/$(file) $(file);)
endif

uninstall :
	ocamlfind remove pprzbus
	ocamlfind remove glibpprzbus
	ocamlfind remove tkpprzbus
#	cd `ocamlc -where`; rm -f $(SYMLINKS)

pprzbus-ocaml.cma : $(PPRZBUSCMO) cpprzbus.o cpprzbusloop.o
	$(OCAMLMKLIB) -o pprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUS_CLIBS) $(REDIS_LDFLAGS)

pprzbus-ocaml.cmxa : $(PPRZBUSCMX) cpprzbus.o cpprzbusloop.o
	$(OCAMLMKLIB) -o pprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUS_CLIBS) $(REDIS_LDFLAGS)

glibpprzbus-ocaml.cma : $(GLIBPPRZBUSCMO) cpprzbus.o cglibpprzbus.o
	$(OCAMLMKLIB) -o glibpprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUSGLIB_CLIBS) -lpcre $(REDIS_LDFLAGS)

glibpprzbus-ocaml.cmxa : $(GLIBPPRZBUSCMX) cpprzbus.o cglibpprzbus.o
	$(OCAMLMKLIB) -o glibpprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUSGLIB_CLIBS) -lpcre $(REDIS_LDFLAGS)

tkpprzbus-ocaml.cma : $(TKPPRZBUSCMO) cpprzbus.o ctkpprzbus.o
	$(OCAMLMKLIB) -o tkpprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUSTCL_CLIBS) $(REDIS_LDFLAGS)

tkpprzbus-ocaml.cmxa : $(TKPPRZBUSCMX) cpprzbus.o ctkpprzbus.o
	$(OCAMLMKLIB) -o tkpprzbus-ocaml $^ $(LIBRARYS) $(PPRZBUSTCL_CLIBS) $(REDIS_LDFLAGS)


.SUFFIXES:
.SUFFIXES: .ml .mli .mly .mll .cmi .cmo .cmx .c .o .out .opt

.ml.cmo :
	$(OCAMLC) $(OCAMLFLAGS) $(INCLUDES) -c $<
.c.o :
	$(CC) -Wall -c $(FPIC) $(OCAMLINC) $(PPRZBUS_CINC) $(TKINC) $(GLIB_CFLAGS) $<
.mli.cmi :
	$(OCAMLMLI) $(OCAMLFLAGS) -c $<
.ml.cmx :
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<
.mly.ml :
	ocamlyacc $<
.mll.ml :
	ocamllex $<
.cmo.out :
	$(OCAMLC) -custom -o $@ unix.cma -I . pprzbus.cma $< -cclib -lpprzbus
.cmx.opt :
	$(OCAMLOPT) -o $@ unix.cmxa -I . pprzbus.cmxa $< -cclib -lpprzbus

clean:
	\rm -fr *.cm* *.o *.a .depend *~ *.out *.opt .depend *.so *-stamp debian/pprzbus-ocaml debian/files debian/pprzbus-ocaml.debhelper.log debian/pprzbus-ocaml.substvars debian/*~

.PHONY: all dev pprzbus glibpprzbus tkpprzbus install uninstall clean

.depend:
	$(OCAMLDEP) $(INCLUDES) *.mli *.ml > .depend

ifneq ($(MAKECMDGOALS),clean)
-include .depend
endif

