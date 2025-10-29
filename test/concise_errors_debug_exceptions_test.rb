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

    assert_includes payload, "<!DOCTYPE html>"
    assert_includes payload, "<h1>RuntimeError</h1>"
    assert_includes payload, "bang"
    assert_includes payload, "Stack Trace"
  end

  def test_html_output_includes_full_error_button_in_dev
    ConciseErrors.configure { |config| config.format = :html }

    _status, _headers, body = middleware.call(build_env)

    payload = response_body_string(body)

    assert_includes payload, "Show original error page"
    assert_includes payload, "concise_errors_full=1"
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

  def test_flagged_request_uses_fallback_handler
    ConciseErrors.configure { |config| config.format = :html }

    fallback_response = [599, { "content-type" => "text/plain" }, ["fallback"]]
    env = build_env_for_path("/?concise_errors_full=1")

    middleware.stub(:fallback_web_console, -> { ->(_env) { fallback_response } }) do
      status, headers, body = middleware.call(env)

      assert_equal fallback_response[0], status
      assert_equal fallback_response[1], headers
      assert_equal fallback_response[2], body
    end
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
    build_env_for_path("/", overrides)
  end

  def build_env_for_path(path, overrides = {})
    Rack::MockRequest.env_for(
      path,
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
