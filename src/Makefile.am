include $(top_srcdir)/common.am

plugin_LTLIBRARIES = libdactl-arduino-udp.la
plugin_DATA = arduino-udp.plugin

gresource_file = arduino-udp.gresource.xml
resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies $(gresource_file))
resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=. --generate-source $<

BUILT_SOURCES = resources.c

libdactl_arduino_udp_la_SOURCES = \
	$(BUILT_SOURCES) \
	dactl-arduino-udp-plugin.vala \
	dactl-arduino-udp-factory.vala \
	dactl-arduino-udp-control.vala

libdactl_arduino_udp_la_VALAFLAGS = \
	$(VALAFLAGS) \
	--gresources $(gresource_file) \
	--vapidir=$(srcdir) \
	$(PLUGIN_MODULES_VALAFLAGS)

libdactl_arduino_udp_la_CFLAGS = \
	--include config.h \
	-DG_LOG_DOMAIN='"ArduinoUDP"' \
	$(PLUGIN_DEPS_CFLAGS)

libdactl_arduino_udp_la_LIBADD = \
	$(PLUGIN_DEPS_LIBS)

libdactl_arduino_udp_la_LDFLAGS = \
	$(PLUGIN_LINKER_FLAGS)

MAINTAINERCLEANFILES += $(libdactl_arduino_udp_la_SOURCES:.vala=.c)

EXTRA_DIST = \
	$(gresource_file) \
	$(resource_files) \
	arduino-udp.plugin.in
