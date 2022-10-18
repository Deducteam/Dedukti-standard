all: README.pdf

clean:
	rm README.pdf

%.tex: %.md
	pandoc $< -s -o $@

%.pdf: %.tex
	pdflatex $<
