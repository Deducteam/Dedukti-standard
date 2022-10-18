all: README.pdf README.html

clean:
	rm README.pdf README.html

%.tex: %.md header.tex
	pandoc $< -s -o $@ -H header.tex

%.pdf: %.tex
	pdflatex $<

%.html: operators.sty %.md
	pandoc $^ -s -o $@
