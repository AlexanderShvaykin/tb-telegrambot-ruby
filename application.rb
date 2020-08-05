# frozen_string_literal: true

require 'telegram/bot'
require 'gemoji'
require 'async'
require 'encrypted_strings'
require 'sanitize'
require 'English'
require 'open-uri'

require './lib/app_configurator'
require './lib/emoji'
require './lib/emoji_aliaser'
require './lib/formatter'
require './lib/validator'
require './lib/viewers/viewers'
require './lib/message_responder'
require './lib/message_sender'

AppConfigurator.new.configure
