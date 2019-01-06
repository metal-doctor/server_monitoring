#!/bin/bash
# Unpacking.
tar -xf prometheus_server.tar
# Changing permissions of prometheus storage catalog.
sudo chmod -R o+w prometheus_server/prometheus/data
# Changing owner of grafana storage catalog, because grafana started from user with ID 472.
sudo chown -R 472:472 prometheus_server/grafana/grafana-storage