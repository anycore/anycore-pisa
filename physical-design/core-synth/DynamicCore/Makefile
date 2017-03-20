SYNTH_DIR	=	SYNTH
PNR_DIR	=	PNR

.PHONY:	synth	pnr clean purge

synth:
	$(MAKE) -C $(SYNTH_DIR) run_new

pnr:
	$(MAKE) -C $(PNR_DIR) route

# Deletes only intermediate files
# Does not delete netlists and reports
clean:
	$(MAKE) -C $(SYNTH_DIR) clean
	$(MAKE) -C $(PNR_DIR) clean
	
# Deletes everything, even netlists and reports	
purge:
	$(MAKE) -C $(SYNTH_DIR) purge
	$(MAKE) -C $(PNR_DIR) purge
	
