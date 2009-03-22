# 

SOURCES = b16.lyx Makefile \
	b16.nw b16.v b16.fs

all:	b16.v b16.pdf

%.nw:	%.lyx
	-rm $@
	lyx -e literate $<

%.tex:	%.nw
	noweave -delay -latex $< | sed -e 's/1<<dep/1<{}<dep/g' >$@
	latex $@

%.v:	%.nw
	notangle -Rb16.v $< >$@

%.dvi:	%.tex
	latex $<

%.ps:	%.dvi
	dvips -Pams -Pcmz -Ppdf $< -o $@

%.ps.gz:	%.ps
	gzip <$< >$@

%.pdf:	%.ps
	ps2pdf $< $@

la:	la.c
	gcc -O2 la.c -o la

dist:	$(SOURCES)
	mkdir b16
	cp $(SOURCES) b16
	tar jcf b16.tar.bz2 b16
	rm -rf b16
