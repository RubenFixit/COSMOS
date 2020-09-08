# encoding: ascii-8bit

# Copyright 2020 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

require 'childprocess'
require 'cosmos'

module Cosmos

  class OperatorProcess
    attr_accessor :process_definition
    attr_reader :scope

    def initialize(process_definition, scope)
      @process = nil
      @process_definition = process_definition
      @scope = scope
    end

    def start
      Logger.info("Starting: #{@process_definition.join(' ')}", scope: @scope)
      @process = ChildProcess.build(*@process_definition)
      @process.leader = true
      @process.start
    end

    def alive?
      if @process
        @process.alive?
      else
        false
      end
    end

    def soft_stop
      Thread.new do
        Logger.info("Soft Shutting down process: #{@process_definition.join(' ')}", scope: @scope)
        Process.kill("SIGINT", @process.pid)
      end
    end

    def hard_stop
      unless @process.exited?
        Logger.info("Hard Shutting down process: #{@process_definition.join(' ')}", scope: @scope)
        @process.stop
      end
      @process = nil
    end

  end

  class Operator
    def initialize
      Logger.level = Logger::INFO
      Logger.microservice_name = 'MicroserviceOperator'
      Logger.tag = "operator.log"

      @ruby_process_name = ENV['COSMOS_RUBY']
      if RUBY_ENGINE != 'ruby'
        @ruby_process_name ||= 'jruby'
      else
        @ruby_process_name ||= 'ruby'
      end

      @processes = {}
      @new_processes = {}
      @changed_processes = {}
      @remove_processes = {}
      @mutex = Mutex.new
      @shutdown = false
      @shutdown_complete = false
    end

    def update
      raise "Implement in subclass"
    end

    def start_new
      @mutex.synchronize do
        if @new_processes.length > 0
          # Start all the processes
          Logger.info("#{self.class} starting each new process...")
          @new_processes.each { |name, p| p.start }
          @new_processes = {}
        end
      end
    end

    def respawn_changed
      @mutex.synchronize do
        @changed_processes.each do |name, p|
          break if @shutdown
          shutdown_processes(@changed_processes)
          @changed_processes.each { |name, p| p.start }
          @changed_processes = {}
        end
      end
    end

    def remove_old
      @mutex.synchronize do
        if @remove_processes.length > 0
          shutdown_processes(@remove_processes)
          @remove_processes = {}
        end
      end
    end

    def respawn_dead
      @mutex.synchronize do
        @processes.each do |name, p|
          break if @shutdown
          unless p.alive?
            # Respawn process
            Logger.error("Unexpected process died... respawning! #{p.process_definition.join(' ')}", scope: p.scope)
            p.start
          end
        end
      end
    end

    def shutdown_processes(processes)
      processes.each { |name, p| p.soft_stop }
      sleep(2)
      processes.each { |name, p| p.hard_stop }
    end

    def run
      # Use at_exit to shutdown cleanly
      at_exit do
        @shutdown = true
        @mutex.synchronize do
          Logger.info("Shutting down processes...")
          shutdown_processes(@processes)
          @shutdown_complete = true
        end
      end

      # Monitor processes and respawn if died
      Logger.info("#{self.class} Monitoring processes...")
      loop do
        update()
        remove_old()
        respawn_changed()
        start_new()
        respawn_dead()
        break if @shutdown
        sleep(2)
        break if @shutdown
      end

      loop do
        break if @shutdown_complete
        sleep(1)
      end

    ensure
      Logger.info("#{self.class} shutdown complete")
    end

    def self.run
      a = self.new
      a.run
    end

  end # class Operator

end # module Cosmos