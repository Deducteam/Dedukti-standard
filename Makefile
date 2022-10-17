all: README.pdf

clean:
	rm README.pdf

%.pdf: %.md
	pandoc $< -o $@
