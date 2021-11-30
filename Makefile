# Copyright (c) 2021 Garry T. Williams

INSTALL = /usr/bin/install
POD2MAN = /usr/bin/pod2man
SYSTEMD = /usr/bin/systemctl
BIN     = /home/garry/bin
EXECS   = dyn-update
SERVICE = dyn-update.service
SVCDIR  = /home/garry/.config/systemd/user

.SUFFIXES: .pl

.pl:
	@perl -c $<
	@cp $< $@
	@chmod 0755 $@

default: $(EXECS) $(SERVICE)
	@for f in $(EXECS) ; do \
	    $(INSTALL) -vm 0555 $$f $(BIN) ; \
	done
	@ $(INSTALL) -vm 0444 $(SERVICE) $(SVCDIR)
	$(SYSTEMD) --user daemon-reload
	$(SYSTEMD) --user enable $(SERVICE)

clean:
	rm -f $(EXECS)

# vim: set ts=8 sw=4 ai noet syntax=make:

