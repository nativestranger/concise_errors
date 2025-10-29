## [Unreleased]

## [0.3.0] - 2025-10-29

- Add production mode support via `enable_in_production` configuration option
- Add beautiful Rails-branded error page styling with red gradient header
- Add code context section showing 3 lines before/after the error with highlighting
- Add numbered stack trace with dark theme
- Remove "View full Rails error page" button (simplified design)
- Improve stack trace extraction to work reliably in both dev and production
- Add `ShowExceptions` middleware for production error handling

## [0.2.0] - 2025-10-25

- Add a "View full Rails error page" button to the HTML view.
  - Clicking the button replays the request (method, headers, and body when applicable)
    to the same URL with the `concise_errors_full=1` flag, letting Rails render its
    original full-featured debug page (or Web Console when present).
  - Configurable via `config.concise_errors.full_error_param` (defaults to
    `"concise_errors_full"`). Set to `nil` or empty to disable the button entirely.

## [0.1.0] - 2025-10-22

- Initial release
