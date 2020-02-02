require './lib/answers/answer'

class Teachbase::Bot::AnswerMenu < Teachbase::Bot::Answer
  MENU_TYPES = %i[menu menu_inline].freeze

  def initialize(appshell, param)
    super(appshell, param)
  end

  def create(options)
    super(options)
    buttons = options[:buttons]
    type = options[:type]
    @logger = AppConfigurator.new.get_logger

    raise "No such menu type: #{type}" unless MENU_TYPES.include?(type)
    raise "Buttons is #{buttons.class} but must be an Array" unless buttons.is_a?(Array)

    slices_count = options[:slices_count] || nil
    mode = options[:mode]
    @msg_params[:menu_type] = type
    @msg_params[:mode] = mode
    @msg_params[:menu_data] = init_menu_params(buttons, slices_count)
    MessageSender.new(msg_params).send
  end

  def create_inline_buttons(buttons_names, command_prefix = "")
    buttons = []
    buttons_names.each do |button_name|
      button_name.to_s
      buttons << [text: I18n.t(button_name.to_s), callback_data: "#{command_prefix}#{button_name.to_s}"]
    end
    buttons    
  end

  def create_nums_buttons(numbers, options = {})
    raise "Can't find numbers for 'num_navigation'" unless numbers

    num_buttons = []
    text = options[:text]
    type = options[:type] || :menu_inline
    prefix = options[:prefix] || ""
    back_button = options[:back_button] || false
    numbers.each_with_index { |item, i| num_buttons << i.to_s }

    buttons = create_inline_buttons(num_buttons, prefix)
    buttons << inline_back_button if back_button
    create(buttons: buttons,
           type: type,
           text: text,
           slices_count: num_buttons.size)
  end

  def inline_back_button
    callback = cb_for_back_button
    @logger.debug "cb_for_back_button: #{callback}"
    return unless callback

    [text: I18n.t('inline_back_button'), callback_data: callback]
  end

  def starting(text = I18n.t('start_menu_message').to_s)
    buttons = [@respond.commands.show(:signin), @respond.commands.show(:settings)]
    create(buttons: buttons, type: :menu, text: text, slices_count: 2)
  end

  def after_auth
    buttons = [@respond.commands.show(:course_list_l1),
               @respond.commands.show(:show_profile_state),
               @respond.commands.show(:settings),
               @respond.commands.show(:sign_out)]
    create(buttons: buttons, type: :menu, text: I18n.t('start_menu_message'), slices_count: 2)
  end

  def hide(text)
    raise "Can't find menu destination for message #{@respond.incoming_data}" if destination.nil?

    MessageSender.new(bot: @respond.incoming_data.bot, chat: destination,
                      text: text.to_s, type: :hide_kb).send
  end

  private

  def cb_for_back_button
    callbacks = @tg_user.tg_account_messages.order(created_at: :desc).where(message_type: "callback_data").select(:data)
    raise "Can't find callbacks for back button" unless callbacks

    return callbacks.first.data if callbacks.size == 1

    callbacks.size.times do |i|
      break callbacks[i + 1].data if callbacks[i + 1].data != callbacks[i].data
    end
  end

  def init_menu_params(buttons, slices_count)
    {buttons: buttons, slices: slices_count }
  end

end
