.PHONY: all build clean copy-src local requirements setup test up update-dependencies

CKAN_HOME := /srv/app

all: build

ci:
	docker-compose up -d
	sleep 40
	docker-compose logs db
	docker-compose logs ckan

build:
	docker-compose build

clean:
	docker-compose down -v --remove-orphans

copy-src:
	docker cp catalog-app_ckan_1:$(CKAN_HOME)/src .

dev:
	docker-compose build
	docker-compose up

debug:
	docker-compose build
	docker-compose run --service-ports ckan

requirements:
	docker-compose run --rm -T ckan pip --quiet freeze > requirements-freeze.txt

test:
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

quick-test:
	# if local environment is already build and running 
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build test
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

update-dependencies:
	docker-compose run --rm -T ckan freeze-requirements.sh $(shell id -u) $(shell id -g)
	cp requirements/requirements.txt ckan/requirements.txt
up:
	docker-compose up

test-import-tool:
	cd tools/harvest_source_import && \
		pip install --upgrade pip  && \
		pip install -r dev-requirements.txt && \
		flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics  && \
		flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics  && \
		python -m pytest --vcr-record=none tests/

lint-all:
	docker-compose up -d
	docker-compose exec ckan \
		bash -c "cd $(CKAN_HOME)/src && \
		 		 pip install --upgrade pip  && \
				 pip install flake8 && \
				 flake8 . --count --select=E9 --show-source --statistics"