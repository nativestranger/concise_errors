# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "logger"
require "active_support/backtrace_cleaner"
require "action_dispatch"

class ConciseErrorsDebugExceptionsTest < Minitest::Test
  def setup
    ConciseErrors.reset_configuration!
    ConciseErrors.configure do |config|
      config.stack_trace_lines = 3
    end
  end

  def test_plain_text_output_by_default
    status, headers, body = middleware.call(build_env)

    assert_equal 500, status
    assert_includes headers.fetch("content-type"), "text/plain"

    payload = response_body_string(body)

    assert_includes payload, "RuntimeError: bang"
    assert_includes payload, "HTTP 500"
  end

  def test_renders_html_when_configured
    ConciseErrors.configure { |config| config.format = :html }

    status, headers, body = middleware.call(build_env)

    assert_equal 500, status
    assert_includes headers.fetch("content-type"), "text/html"

    payload = response_body_string(body)

    assert_includes payload, "<pre>"
    assert_includes payload, "RuntimeError: bang"
    refute_includes payload, "color-scheme"
  end

  def test_falls_back_to_text_for_xhr_requests
    ConciseErrors.configure { |config| config.format = :html }

    status, headers, _body = middleware.call(build_env("HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"))

    assert_equal 500, status
    assert_includes headers.fetch("content-type"), "text/plain"
  end

  def test_plain_text_for_non_html_accept
    ConciseErrors.configure { |config| config.format = :html }

    status, headers, _body = middleware.call(build_env("HTTP_ACCEPT" => "application/json"))

    assert_equal 500, status
    assert_includes headers.fetch("content-type"), "text/plain"
  end

  def test_truncates_stack_trace_when_limit_is_low
    ConciseErrors.configure { |config| config.stack_trace_lines = 1 }

    _status, _headers, body = middleware.call(build_env)

    payload = response_body_string(body)

    assert_includes payload, "... "
  end

  def test_application_root_prefix_is_trimmed
    ConciseErrors.configure do |config|
      config.application_root = File.expand_path("..", __dir__)
    end

    _status, _headers, body = middleware.call(build_env)

    payload = response_body_string(body)

    assert_includes payload, "./test/concise_errors_debug_exceptions_test.rb"
  end

  private

  def middleware
    @middleware ||= ConciseErrors::DebugExceptions.new(exception_app)
  end

  def exception_app
    lambda do |_env|
      raise "bang"
    end
  end

  def build_env(overrides = {})
    Rack::MockRequest.env_for(
      "/",
      "HTTP_ACCEPT" => "text/html"
    ).merge(
      "action_dispatch.show_detailed_exceptions" => true,
      "action_dispatch.show_exceptions" => :all,
      "action_dispatch.backtrace_cleaner" => ActiveSupport::BacktraceCleaner.new,
      "action_dispatch.debug_exception_log_level" => Logger::Severity::ERROR,
      "action_dispatch.show_rescues" => true
    ).merge(overrides)
  end

  def response_body_string(body)
    body.each_with_object(String.new) { |chunk, buffer| buffer << chunk }
  ensure
    body.close if body.respond_to?(:close)
  end
end
