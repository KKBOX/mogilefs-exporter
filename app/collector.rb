require 'mogilefs'
require 'prometheus/client'

module Prometheus
  module Client
    class Metric
      def delete(labels)
        @values.delete(label_set_for(labels))
      end
    end
  end
end

module MogileFS
  HOST_STATUS = {
    'readonly' => 3,
    'alive'    => 1,
    'down'     => 0,
    'dead'     => -1,
  }

  DEVICE_STATUS = {
    'readonly' => 3,
    'drain'    => 2,
    'alive'    => 1,
    'down'     => 0,
    'dead'     => -1,
  }

  DEVICE_STATE = {
    'writeable'   => 1,
    'readable'    => 0,
    'unreachable' => -1,
  }

  class Collector
    def initialize(app)
       @app = app
    end

    def call(env)
      if env['PATH_INFO'] == '/metrics'
        export
      end

      @app.call(env)
    end

    def export
      hosts = mogadm.get_hosts.sort_by { |host| host['hostid'] }
      devices = mogadm.get_devices.sort_by { |device| device['devid'] }

      hostname_by_id = {}
      hosts.each do |host|
        hostname = host['hostname']
        status = host['status']

        host_status.set({ host: hostname }, HOST_STATUS[status])

        hostname_by_id[host['hostid']] = hostname
      end

      devices.each do |device|
        hostname = hostname_by_id[device['hostid']]
        devname = "dev#{device['devid']}"
        labels = { host: hostname, device: devname }
        status = device['status']
        state = device['observed_state']
        mb_used = device['mb_used']
        mb_free = device['mb_free']
        mb_total = device['mb_total']

        device_status.set(labels, DEVICE_STATUS[status])
        if state
          device_state.set(labels, DEVICE_STATE[state])
        else
          device_state.delete(labels)
        end
        if mb_used
          device_used_mb.set(labels, mb_used)
        else
          device_used_mb.delete(labels)
        end
        if mb_free
          device_free_mb.set(labels, mb_free)
        else
          device_free_mb.delete(labels)
        end
        if mb_total
          device_total_mb.set(labels, mb_total)
        else
          device_total_mb.delete(labels)
        end
      end
    end

    protected

    def mogadm
      @mogadm ||= Admin.new(hosts: HOSTS)
    end

    def prometheus
      Prometheus::Client.registry
    end

    def host_status
      @host_status ||= prometheus.get :mogilefs_host_status
      unless @host_status
        @host_status =  Prometheus::Client::Gauge.new(:mogilefs_host_status, 'The MogileFS host status: ' + HOST_STATUS.map { |k, v| "#{k} = #{v}" }.join(', '))
        prometheus.register @host_status
      end
      @host_status
    end

    def device_status
      @device_status ||= prometheus.get :mogilefs_device_status
      unless @device_status
        @device_status =  Prometheus::Client::Gauge.new(:mogilefs_device_status, 'The MogileFS device status: ' + DEVICE_STATUS.map { |k, v| "#{k} = #{v}" }.join(', '))
        prometheus.register @device_status
      end
      @device_status
    end

    def device_state
      @device_state ||= prometheus.get :mogilefs_device_state
      unless @device_state
        @device_state =  Prometheus::Client::Gauge.new(:mogilefs_device_state, 'The MogileFS device state: ' + DEVICE_STATE.map { |k, v| "#{k} = #{v}" }.join(', '))
        prometheus.register @device_state
      end
      @device_state
    end

    def device_used_mb
      @device_used_mb ||= prometheus.get :mogilefs_device_used_mb
      unless @device_used_mb
        @device_used_mb =  Prometheus::Client::Gauge.new(:mogilefs_device_used_mb, 'The MogileFS device used space in MB')
        prometheus.register @device_used_mb
      end
      @device_used_mb
    end

    def device_free_mb
      @device_free_mb ||= prometheus.get :mogilefs_device_free_mb
      unless @device_free_mb
        @device_free_mb =  Prometheus::Client::Gauge.new(:mogilefs_device_free_mb, 'The MogileFS device free space in MB')
        prometheus.register @device_free_mb
      end
      @device_free_mb
    end

    def device_total_mb
      @device_total_mb ||= prometheus.get :mogilefs_device_total_mb
      unless @device_total_mb
        @device_total_mb =  Prometheus::Client::Gauge.new(:mogilefs_device_total_mb, 'The MogileFS device total space in MB')
        prometheus.register @device_total_mb
      end
      @device_total_mb
    end
  end
end
