# frozen_string_literal: true

require './lib/scenarios/base'
require './lib/scenarios/standart_learning'
require './lib/scenarios/marathon'
require './lib/scenarios/battle'

module Teachbase
  module Bot
    module Scenarios
      LIST = %w[standart_learning marathon battle].freeze
    end
  end
end
