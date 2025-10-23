# frozen_string_literal: true

module ConciseErrors
  # Stores global configuration for the middleware.
  class Configuration
    DEFAULT_STACK_LINES = 10
    DEFAULT_FORMAT = :text

    attr_accessor :stack_trace_lines, :enabled, :logger, :application_root, :cleaner

    def initialize
      reset!
    end

    def format
      (@format || DEFAULT_FORMAT).to_sym
    end

    def enabled?
      enabled != false
    end

    def format=(value)
      @format = value&.to_sym
    end

    def reset!
      @format = :text
      @stack_trace_lines = DEFAULT_STACK_LINES
      @enabled = true
      @logger = nil
      @application_root = nil
      @cleaner = nil
    end
  end
end
