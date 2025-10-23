# frozen_string_literal: true

require "action_dispatch/http/content_security_policy"
require "action_dispatch/http/mime_type"
require "action_dispatch/http/parameters"
require "action_dispatch/http/request"
require "action_dispatch/middleware/debug_exceptions"

module ConciseErrors
  # Replacement middleware that keeps the existing API while producing concise output.
  class DebugExceptions < ::ActionDispatch::DebugExceptions
    def call(env)
      env["action_dispatch.backtrace_cleaner"] ||= ConciseErrors.configuration.cleaner
      super
    end

    private

    def render_for_browser_request(request, wrapper)
      formatter = Formatter.new(wrapper, request, ConciseErrors.configuration)
      render(wrapper.status_code, formatter.body, formatter.content_type)
    end

    def logger(request)
      ConciseErrors.logger || super
    end
  end
end
