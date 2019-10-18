require './models/command'
require './lib/app_configurator'
require 'gemoji'

module Teachbase
  module Bot
    class CommandList
      attr_reader :all

      def initialize
        @all = []
        create
      end

      def create
        sign_emoji = [:signin, Emoji.find_by_alias('rocket').raw],
                    [:settings, Emoji.find_by_alias('wrench').raw]
        sign_emoji.each { |data| all << Teachbase::Bot::Command.new(data[0], data[1]) }
        all
        raise "'CommandList' not created" if all.empty?
      end

      def command_by_value?(value)
        all.any? { |command| command.value == value}
      end

      def find_by_value(value)
        return unless command_by_value?(value)

        command = all.select { |command| command.value == value}
        command.first
      end

      def get_value(key)
        raise "No such command with key: #{key}" unless all.any? { |command| command.key == key}

        command = all.select { |command| command.key == key}   
        command.first.value     
      end
    end
  end
end
