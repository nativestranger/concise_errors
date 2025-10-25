## [Unreleased]

## [0.2.0] - 2025-10-25

- Add a "View full Rails error page" button to the HTML view.
  - Clicking the button replays the request (method, headers, and body when applicable)
    to the same URL with the `concise_errors_full=1` flag, letting Rails render its
    original full-featured debug page (or Web Console when present).
  - Configurable via `config.concise_errors.full_error_param` (defaults to
    `"concise_errors_full"`). Set to `nil` or empty to disable the button entirely.

## [0.1.0] - 2025-10-22

- Initial release
