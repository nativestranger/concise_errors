# ConciseErrors

ConciseErrors swaps Rails’ `ActionDispatch::DebugExceptions` middleware with a compact error page that focuses on the class, message, and a truncated backtrace. It was designed to give human developers and AI assistants the minimum viable context needed to diagnose a failure without the noise of the default HTML-heavy debugger.

## Features

- Tiny plain-text payloads by default (no inline assets, no copious markup).
- Optional single-file HTML view optimised for dark/light mode without external CSS.
- Configurable backtrace depth with an omission indicator.
- Automatic fallback to `text/plain` when the request is `xhr?` or clients negotiate non-HTML `Accept` headers.
- HTML view includes a button to open Rails' full-featured error page.

## Installation

Add the gem to your Gemfile:

```ruby
gem "concise_errors"
```

Run `bundle install` and restart your Rails server. ConciseErrors automatically swaps the middleware when the gem loads.

## Configuration

ConciseErrors ships with opinionated defaults — HTML output, no CSS, and Web Console middleware is automatically removed in development — so simply installing the gem is enough. Override anything you need from `config/application.rb` or an environment-specific config:

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.concise_errors.tap do |cfg|
    cfg.stack_trace_lines = 5   # default: 10
    cfg.format = :html          # available: :text (default) or :html
    cfg.enabled = true          # flip to false to restore the stock debug page
    cfg.application_root = Rails.root.to_s # optional: trim this prefix from traces
    cfg.logger = Rails.logger              # optional: reuse your preferred logger
    cfg.full_error_param = "concise_errors_full" # optional: query param to trigger full page; set nil/"" to disable
  end
end
```

You can also steer the default format via `ENV["CONCISE_ERRORS_FORMAT"]` (`text` or `html`).

ConciseErrors only affects the debug middleware (the screen you see when `config.consider_all_requests_local` is true). Production 500 pages continue to use whatever `ActionDispatch::ShowExceptions` is configured to serve.

### Viewing the full Rails error page

When rendering HTML, ConciseErrors shows a "View full Rails error page" button. Clicking it performs a same-origin request back to the same URL with the `concise_errors_full=1` flag (or your configured `full_error_param`). The original request method, CSRF token, and content type are preserved; for non-GET/HEAD requests the request body is replayed.

- To disable the button entirely, set `config.concise_errors.full_error_param = nil` or `""`.
- If Web Console is installed, the fallback will go through its middleware; otherwise Rails' stock `ActionDispatch::DebugExceptions` page is shown.

## Sample Output

Plain text format (default):

```
RuntimeError: bang
HTTP 500 (Internal Server Error)

app/controllers/widgets_controller.rb:12:in `show'
app/controllers/widgets_controller.rb:12:in `show'
...
```

HTML format renders the same content inside a single `<pre>` block with minimal inline styling suitable for AI agents that prefer HTML responses.

## Development

After checking out the repo run:

```bash
bin/setup
bundle exec rake test
```

`bin/console` opens an IRB session with the gem loaded. To try the middleware in a real app, add a `path:` entry to a Rails application's Gemfile pointing at your local clone.

Before cutting a release:

1. Update `ConciseErrors::VERSION` and `CHANGELOG.md`.
2. Run `bundle exec rake release` to tag, build, and push the gem.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/obie/concise_errors. All contributions are expected to follow the [code of conduct](https://github.com/obie/concise_errors/blob/main/CODE_OF_CONDUCT.md).
