# Copyright (c) 2021 Garry T. Williams

INSTALL = /usr/bin/install
POD2MAN = /usr/bin/pod2man
SYSTEMD = /usr/bin/systemctl
BIN     = /home/garry/bin
MAN     = /home/garry/man/man1
EXECS   = dyn-update
MANS    = dyn-update.1
SERVICE = dyn-update.service
SVCDIR  = /home/garry/.config/systemd/user
PFLAGS  = -c "Update DynDNS IP Address"

.SUFFIXES: .pl .1

.pl:
	@perl -c $<
	@cp $< $@
	@chmod 0755 $@

.pl.1:
	$(POD2MAN) $(PFLAGS) -n$* $< >$@

default: $(EXECS) $(SERVICE) $(MANS)
	@mkdir -p $(BIN) $(MAN)
	@for f in $(EXECS) ; do \
	    $(INSTALL) -vm 0555 $$f $(BIN) ; \
	done
	@for f in $(MANS) ; do \
	    $(INSTALL) -vm 00444 $$f $(MAN) ; \
	done
	@ $(INSTALL) -vm 0444 $(SERVICE) $(SVCDIR)
	$(SYSTEMD) --user daemon-reload
	$(SYSTEMD) --user enable $(SERVICE)

clean:
	rm -f $(EXECS) $(MANS)

# vim: set ts=8 sw=4 ai noet syntax=make:

