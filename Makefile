VPATH = .:assets
vpath %.html .:_includes:_layouts:_site
vpath %.scss _sass:assets/css
vpath %.xml _site
vpath %.yaml .:_spec

SASS      = $(wildcard *.scss)
ANYTHING  = $(filter-out _site,$(wildcard *))
MARKDOWN  = $(filter-out README.md,$(wildcard *.md))
AULAS     = $(wildcard _aula/*.md)
SLIDES   := $(patsubst _aula/%.md,_site/slides/%.html,$(AULAS))

PANDOC/CROSSREF := docker run -v "`pwd`:/data" \
	--user "`id -u`:`id -g`" pandoc/crossref:2.11.4
PANDOC/LATEX    := docker run --user "`id -u`:`id -g`" \
	-v "`pwd`:/data" -v "`pwd`/assets/fonts:/usr/share/fonts" \
	pandoc/latex:2.11.4
JEKYLL-PANDOC   := palazzo/jekyll-tufte:4.2.0

manual : $(MARKDOWN) README.md $(SASS) $(AULAS) \
	assets _config.yaml _spec/html.yaml _site .slides | _csl
	@bundle install && bundle exec jekyll build

tau0005.pdf : plano.pdf cronograma.pdf \
	trabalho-1-construcao.pdf trabalho-2-ordens.pdf trabalho-3-tipologia.pdf
	gs -dNOPAUSE -dBATCH -sDevice=pdfwrite \
		-sOutputFile=$@ $^

.slides : $(SLIDES) revealjs.yaml | _site _csl

_site :
	@gh repo clone tau0005 _site -- -b gh-pages --depth=1 --recurse-submodules \
		|| cd _site && git pull

	#docker run -v "`pwd`:/srv/jekyll" \
		#$(JEKYLL-PANDOC) /bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

_site/slides/%.html : _aula/%.md revealjs.yaml biblio.bib | _csl _site/slides
	$(PANDOC/CROSSREF) -o $@ -d _spec/revealjs.yaml $<

%.pdf : %.tex biblio.bib
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts/unb:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

%.tex : %.md latex.yaml biblio.bib
	$(PANDOC/LATEX) -o $@ -d _spec/latex.yaml $<

serve : .slides
	@bundle exec jekyll serve

	#docker run -p 4000:4000 -h 127.0.0.1 \
		#-v "`pwd`:/srv/jekyll" -it $(JEKYLL-PANDOC) \
		#jekyll serve --skip-initial-build --no-watch

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

_site/slides :
	mkdir -p _site/slides

clean :
	-@rm *.aux *.bbl *.bcf *.blg *.fls *.log
