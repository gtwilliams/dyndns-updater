# Copyright (c) 2021 Garry T. Williams

INSTALL  = /usr/bin/install
POD2MAN  = /usr/bin/pod2man
PFLAGS   = -c "Update DynDNS IP Address"
SYSTEMD  = /usr/bin/systemctl

BIN      = $(HOME)/.local/bin
MAN      = $(HOME)/man/man1
SVCDIR   = $(HOME)/.config/systemd/user

EXECS    = dyn-update
MANS     = dyn-update.1
SERVICE  = dyn-update.service
INSTALLS = $(addprefix $(BIN)/,$(EXECS)) $(addprefix $(MAN)/,$(MANS)) \
	   $(addprefix $(SVCDIR)/,$(SERVICE))

.INTERMEDIATE: $(EXECS) $(MANS)
.PHONY: install

install: $(BIN) $(MAN) $(INSTALLS)

$(BIN)/%: %
	$(INSTALL) -m 00555 $< $@

$(MAN)/%: %
	$(INSTALL) -m 00444 $< $@

$(SVCDIR)/%: %
	$(INSTALL) -m 00444 $< $@
	$(SYSTEMD) --user daemon-reload

%: %.pl
	@perl -c $<
	@cp $< $@
	@chmod 0755 $@

%.1: %.pl
	$(POD2MAN) $(PFLAGS) -n$* $< >$@

$(BIN):
	mkdir -p $@

$(MAN):
	mkdir -p $@

# vim: set ts=8 sw=4 ai noet syntax=make:
