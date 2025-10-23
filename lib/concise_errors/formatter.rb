# frozen_string_literal: true

require "erb"
require "rack/utils"

module ConciseErrors
  # Builds the compact error payload for browser responses.
  class Formatter
    OMITTED_SUFFIX = "... %<count>d more lines omitted"

    def initialize(wrapper, request, configuration)
      @wrapper = wrapper
      @request = request
      @configuration = configuration
    end

    def body
      response_format == :html ? html_payload : text_payload
    end

    def content_type
      response_format == :html ? "text/html" : "text/plain"
    end

    private

    attr_reader :wrapper, :request, :configuration

    def response_format
      return :text if prefers_plain_text?

      configuration.format
    end

    def text_payload
      [heading_line, status_line, "", *truncated_trace].compact.join("\n")
    end

    def html_payload
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <title>#{html_escape(heading_line)}</title>
          </head>
          <body>
            <h1>#{html_escape(heading_line)}</h1>
            <p>#{html_escape(status_line)}</p>
            <pre>#{html_escape(truncated_trace.join("\n"))}</pre>
          </body>
        </html>
      HTML
    end

    def heading_line
      "#{wrapper.exception_class_name}: #{wrapper.message}".strip
    end

    def status_line
      status = wrapper.status_code
      message = Rack::Utils::HTTP_STATUS_CODES[status] || "Internal Server Error"
      "HTTP #{status} (#{message})"
    end

    def truncated_trace
      full_trace = Array(wrapper.exception_trace).map { |line| sanitize_trace(line) }
      limit = configuration.stack_trace_lines

      return full_trace if limit.nil? || limit <= 0 || full_trace.size <= limit

      full_trace.first(limit) + [Kernel.format(OMITTED_SUFFIX, count: full_trace.size - limit)]
    end

    def html_escape(string)
      ERB::Util.html_escape(string)
    end

    def prefers_plain_text?
      return true if request.xhr?

      accept = request.get_header("HTTP_ACCEPT").to_s
      return false if accept.empty?

      !accept.downcase.include?("html")
    end

    def sanitize_trace(line)
      root = configuration.application_root.to_s
      return line if root.empty?

      line.sub(%r{\A#{Regexp.escape(root)}/?}, "./")
    end
  end
end
