all: README.pdf

clean:
	rm README.pdf

%.tex: %.md header.tex
	pandoc $< -s -o $@ -H header.tex

%.pdf: %.tex
	pdflatex $<
