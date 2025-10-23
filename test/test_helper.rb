# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "action_dispatch"
require "action_controller"
require "concise_errors"

ConciseErrors.reset_configuration!
