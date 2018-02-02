# MogileFS Exporter
Prometheus Exporter for MogileFS

## Prerequisites

* Modern Ruby (Ruby MRI >= 2.4.0 tested.)
* Build environment

## Installation

```bash
    git clone https://github.com/KKBOX/mogilefs-exporter.git
    cd mogilefs-exporter
    gem install bundler
    bundle install
```

## Running

```bash
    export MOGILEFS_HOSTS="HOST:PORT[[,HOST:PORT]...]"
    puma -p 9413
```

## Using Docker

```bash
docker run -d -p 9413:9413 -e MOGILEFS_HOSTS=HOST:PORT[[,HOST:PORT]...] kkbox/mogilefs-exporter
```
