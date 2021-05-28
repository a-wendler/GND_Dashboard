.DEFAULT_GOAL: all

SHELL := /bin/bash
PICA ?= pica

DUMPFILE = DNBGNDtitel.dat.gz
PARTITIONS = data/partitions
USERDIR = data/user
TEMPDIR = data/tmp
STATSDIR = stats
SCRIPTS = scripts

#
# PREPARE
#

.PHONY: prepare
prepare:
	@mkdir -p $(PARTITIONS) $(USERDIR) $(TEMPDIR) $(STATSDIR)

#
# PARTITIONS
#

partitions: $(DUMPFILE)
	$(PICA) partition "002@.0" --skip-invalid $< -o $(PARTITIONS)

#
# USER DUMPS
#

USEROBJ := T.dat titel.dat gnd.dat
user: $(addprefix $(USERDIR)/,$(USEROBJ)) | prepare

$(USERDIR)/T.dat: partitions
	$(PICA) cat $(PARTITIONS)/T*.dat -o $@

$(USERDIR)/gnd.dat: $(USERDIR)/T.dat
	$(PICA) filter "!008@.a? && 007K.a == 'gnd'" $< -o $@

$(USERDIR)/titel.dat: $(DUMPFILE)
	$(PICA) filter -s -v "002@.0 =^ 'T'" $< -o $@

#
# STATS
#

STATSOBJ = entity_types.csv
stats: $(addprefix $(STATSDIR)/,$(STATSOBJ)) title-analysis | prepare

title-analysis: $(USERDIR)/titel.dat
	$(PICA) filter "041A/*.9?" $< -o $(TEMPDIR)/041A_9.dat
	$(PICA) select "003@.0,041A/*{9?, 9, 7, a}" $(TEMPDIR)/041A_9.dat \
		-H "idn,gnd_id,bbg,name" -o $(TEMPDIR)/041A_9.csv
	$(SCRIPTS)/041A_9.py $(TEMPDIR)/041A_9.csv

$(STATSDIR)/entity_types.csv: $(USERDIR)/gnd.dat
	$(PICA) frequency "002@.0" $< -o $@

#
# ALL
#

all: partitions user stats | prepare

#
# CLEAN
#

.PHONY: clean
clean:
	-rm -rf $(PARTITIONS) $(USERDIR) $(TEMPDIR) $(STATSDIR)
