# frozen_string_literal: true

module Viewers
  module Task
    include Formatter

    def title
      "#{attach_emoji(:task)} #{I18n.t('task').capitalize}: #{name}"
    end
  end
end
