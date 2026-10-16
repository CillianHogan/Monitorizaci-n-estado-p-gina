# frozen_string_literal: true

threads_count = ENV.fetch('RAILS_MAX_THREADS', 3)
threads threads_count, threads_count

# Modo single-process para dynos estándar de 512MB (ahorra ~150MB de RAM)
workers 0

port ENV.fetch('PORT', 3000)

plugin :tmp_restart
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']

pidfile ENV['PIDFILE'] if ENV['PIDFILE']
