# 

SOURCES = b16.lyx Makefile \
	b16.nw b16.v b16.fs b16.fig
LYXREV = # set e.g. to 14 for LyX 1.4

all:	b16.v b16-fig.eps b16-fig.pdf b16.pdf

%.nw:	%.lyx$(LYXREV)
	-rm $@
	lyx -e literate $<

%.tex:	%.nw
	noweave -delay -latex $< | sed -e 's/1<<dep/1<{}<dep/g' -e 's/>>/>{}>/g' >$@
	pdflatex $@

%-fig.eps:	%.fig
	fig2dev -L eps $< $@

%-fig.pdf:	%.fig
	fig2dev -L pdf $< $@

%.v:	%.nw
	notangle -Rb16.v $< >$@

%.dvi:	%.tex
	latex $<

%.ps:	%.dvi
	dvips -Pams -Pcmz -Ppdf $< -o $@

%.ps.gz:	%.ps
	gzip <$< >$@

%.pdf:	%.tex
	pdflatex $<

la:	la.c
	gcc -O2 la.c -o la

dist:	$(SOURCES)
	mkdir b16
	cp $(SOURCES) b16
	tar jcf b16.tar.bz2 b16
	rm -rf b16
