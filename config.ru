require 'rack'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

require_relative 'config/application'

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use Prometheus::Middleware::Collector
use MogileFS::Collector
use Prometheus::Middleware::Exporter

run ->(_) { [200, {'Content-Type' => 'text/html'}, ['<html>
<head>
<title>MogileFS Exporter</title>
</head>
<body>
<h1>MogileFS Exporter</h1>
<p><a href="/metrics">Metrics</a></p>
</body>
</html>']] }
