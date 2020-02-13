#!make

# This goofy target makes for a nice default help if you just type make
# ____________________________________________________
_______________:
	@echo Install mmake to get help
	@echo "  $$ go get github.com/tj/mmake/cmd/mmake"
	@echo "  $$ alias make=mmake"
	@echo "  $$ make help"

SHELL := /bin/bash
MAKEFLAGS += --silent

include .env
export $(shell sed 's/=.*//' .env)

dev:
	dotenv postgrest postgrest.conf

# Nuke and Reset Database
reset-db:
	bin/nukedb
	cd database && cat setup.sql | psql $(PGDATABASE)
	RAMBLER_HOST=$(PGHOST) RAMBLER_PORT=$(PGPORT)	RAMBLER_USER=$(PGUSER) RAMBLER_PASSWORD=$(PGPASSWORD) RAMBLER_DATABASE=$(PGDATABASE) rambler apply -a
	dotenv postgrest postgrest.conf
.PHONY: reset-db

# Reload API only (keep database intact)
reload-api:
	cd database/app_schema && cat all.sql | psql $(PGDATABASE)
	cd database/api_schema && cat all.sql | psql $(PGDATABASE)
.PHONY: reload-api
