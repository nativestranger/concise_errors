# frozen_string_literal: true

require "erb"
require "json"
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
            #{full_error_controls}
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

    def full_error_controls
      return "" unless flag_parameter

      payload = full_error_payload
      return "" unless payload

      button_id = "concise-errors-view-full"
      payload_id = "#{button_id}-payload"
      payload_json = ERB::Util.json_escape(JSON.generate(payload))

      <<~HTML
        <button type="button" id="#{button_id}">View full Rails error page</button>
        <script type="application/json" id="#{payload_id}">#{payload_json}</script>
        <script>
          (function() {
            var button = document.getElementById("#{button_id}");
            var payloadScript = document.getElementById("#{payload_id}");
            if (!button || !payloadScript) { return; }

            if (!window.fetch) {
              button.addEventListener("click", function() {
                window.location.assign("#{html_escape(payload.fetch(:url))}");
              });
              return;
            }

            var payloadText = payloadScript.textContent || payloadScript.innerText || "{}";
            var data;

            try {
              data = JSON.parse(payloadText);
            } catch (error) {
              console.error("Failed to parse full error request payload", error);
              return;
            }

            button.addEventListener("click", function(event) {
              event.preventDefault();

              var options = {
                method: data.method,
                credentials: "same-origin"
              };

              if (data.headers && Object.keys(data.headers).length > 0) {
                options.headers = data.headers;
              }

              if (data.body && data.body.length > 0 && data.method !== "GET" && data.method !== "HEAD") {
                options.body = data.body;
              }

              fetch(data.url, options).then(function(response) {
                return response.text().then(function(html) {
                  var doc = document;
                  doc.open();
                  doc.write(html);
                  doc.close();
                });
              }).catch(function(error) {
                console.error("Failed to load full Rails error page", error);
              });
            });
          })();
        </script>
      HTML
    end

    def full_error_payload
      return unless flagged_url

      {
        method: request.request_method,
        url: flagged_url,
        body: replay_body,
        headers: replay_headers
      }
    end

    def replay_body
      return "" if %w[GET HEAD].include?(request.request_method)

      request.raw_post.to_s
    rescue EOFError
      ""
    end

    def replay_headers
      headers = {}
      content_type = request.get_header("CONTENT_TYPE").to_s
      headers["Content-Type"] = content_type unless content_type.empty?

      csrf = request.get_header("HTTP_X_CSRF_TOKEN").to_s
      headers["X-CSRF-Token"] = csrf unless csrf.empty?

      headers
    end

    def flagged_url
      flag = flag_parameter
      return unless flag

      params = request.query_parameters.dup
      params[flag] = "1"

      query = Rack::Utils.build_nested_query(params)
      base_path = request.fullpath.split("?", 2).first
      return base_path if query.empty?

      "#{base_path}?#{query}"
    end

    def flag_parameter
      value = configuration.full_error_param
      return if value.nil?

      string = value.to_s.strip
      string.empty? ? nil : string
    end
  end
end
