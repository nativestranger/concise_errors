# ConciseErrors

ConciseErrors swaps Rails’ `ActionDispatch::DebugExceptions` middleware with a compact error page that focuses on the class, message, and a truncated backtrace. It was designed to give human developers and AI assistants the minimum viable context needed to diagnose a failure without the noise of the default HTML-heavy debugger.

## Features

- Beautiful, minimal error pages with Rails-brand styling and dark code themes
- Code context showing 3 lines before/after the exception with highlighted error line
- Formatted stack trace with line numbers
- Configurable backtrace depth with an omission indicator
- Automatic fallback to `text/plain` when the request is `xhr?` or clients negotiate non-HTML `Accept` headers
- "Show original error page" button in development to access Rails' full error page
- Mobile responsive design

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
    cfg.stack_trace_lines = 10         # default: 10; number of stack trace lines to show
    cfg.format = :html                 # available: :text or :html (default)
    cfg.enabled = true                 # flip to false to restore the stock debug page
    cfg.application_root = Rails.root.to_s # optional: trim this prefix from traces
    cfg.logger = Rails.logger          # optional: reuse your preferred logger
    cfg.enable_in_production = false   # default: false; set true to use in production (see below)
  end
end
```

You can also steer the default format via `ENV["CONCISE_ERRORS_FORMAT"]` (`text` or `html`).

### Using in Production

By default, ConciseErrors only affects the debug middleware (the screen you see when `config.consider_all_requests_local` is true). To enable ConciseErrors in production, add to your production config:

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.concise_errors.enable_in_production = ENV['SHOW_CONCISE_PRODUCTION_ERRORS'] == 'true'
end
```

Then set the environment variable when needed:

```bash
SHOW_CONCISE_PRODUCTION_ERRORS=true rails server -e production
```

When enabled, ConciseErrors will replace the generic "Something went wrong" 500 page with detailed error output including stack traces and code context.


## Sample Output

**Plain text format:**

```
RuntimeError: bang
HTTP 500 (Internal Server Error)

app/controllers/widgets_controller.rb:12:in `show'
app/controllers/widgets_controller.rb:12:in `show'
...
```

**HTML format** renders a beautiful error page featuring:
- Exception class and message in a styled red gradient header
- Code context showing the lines around where the error occurred with the error line highlighted
- Formatted stack trace with line numbers in a dark theme

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
