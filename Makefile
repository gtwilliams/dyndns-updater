# Copyright (c) 2021 Garry T. Williams

INSTALL  = /usr/bin/install
POD2MAN  = /usr/bin/pod2man
PFLAGS   = -c "Update DynDNS IP Address"
SYSTEMD  = /usr/bin/systemctl
PREFIX   = /home/garry
BIN      = $(PREFIX)/bin
MAN      = $(PREFIX)/man/man1
SVCDIR   = $(PREFIX)/.config/systemd/user

EXECS    = dyn-update
MANS     = dyn-update.1
SERVICE  = dyn-update.service
INSTALLS = $(addprefix $(BIN)/,$(EXECS)) $(addprefix $(MAN)/,$(MANS)) \
	   $(addprefix $(SVCDIR)/,$(SERVICE))

.SUFFIXES: .pl .1

.pl:
	@perl -c $<
	@cp $< $@
	@chmod 0755 $@

.pl.1:
	@$(POD2MAN) $(PFLAGS) -n$* $< >$@

install: $(INSTALLS)

$(BIN)/%: %
	@$(INSTALL) -vm 00555 $< $@

$(MAN)/%: %
	@$(INSTALL) -vm 00444 $< $@

$(SVCDIR)/%: %
	@$(INSTALL) -vm 00444 $< $@
	$(SYSTEMD) --user daemon-reload

clean:
	rm -f $(EXECS) $(MANS)

# vim: set ts=8 sw=4 ai noet syntax=make:

