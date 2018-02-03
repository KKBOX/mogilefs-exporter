require 'dotenv'
require_relative '../app/collector'

Dotenv.load

raise 'ENV MOGILEFS_HOSTS is undefined.' unless ENV['MOGILEFS_HOSTS']

MogileFS::HOSTS = ENV['MOGILEFS_HOSTS'].split(',')
