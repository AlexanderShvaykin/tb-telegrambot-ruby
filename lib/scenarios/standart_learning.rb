module Teachbase
  module Bot
    module Scenarios
      module StandartLearning
        include Teachbase::Bot::Scenarios::Base
        LIMIT_COUNT_PAGINAION = 3

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods; end

        def show_profile_state
          appshell.user_info
          profile = appshell.profile
          user = appshell.user

          answer.send_out "<b>#{Emoji.t(:mortar_board)} #{I18n.t('profile_state')}</b>
                          \n  <a href='#{user.avatar_url}'>#{user.first_name} #{user.last_name}</a>
                          \n  #{Emoji.t(:school)} #{I18n.t('average_score_percent')}: #{profile.average_score_percent}%
                          \n  #{Emoji.t(:hourglass)} #{I18n.t('total_time_spent')}: #{profile.total_time_spent / 3600} #{I18n.t('hour')}
                          \n  #{Emoji.t(:green_book)} #{I18n.t('courses')}:
                          #{I18n.t('active_courses')}: #{profile.active_courses_count}
                          #{I18n.t('archived_courses')}: #{profile.archived_courses_count}"
        end

        def show_course_sessions_list(state, limit_count = LIMIT_COUNT_PAGINAION, offset_num = 0)
          offset_num = offset_num.to_i
          limit_count = limit_count.to_i
          course_sessions = appshell.course_sessions_list(state, limit_count, offset_num)
          сs_count = appshell.cs_count_by(state) 
          answer.send_out "#{Emoji.t(:books)} <b>#{I18n.t("#{state}_courses").capitalize}</b>"
          return answer.send_out "#{Emoji.t(:soon)} <i>#{I18n.t('empty')}</i>" if course_sessions.empty?
          
          course_sessions.each do |cs|
            buttons = [[text: I18n.t('open').to_s, callback_data: "cs_sec_by_id:#{cs.tb_id}"],
                       [text: I18n.t('course_results').to_s, callback_data: "cs_info_id:#{cs.tb_id}"]]
            menu.create(buttons: buttons,
                        type: :menu_inline,
                        mode: :none,
                        text: "#{show_breadcrumbs(:course, [:name],
                                                  course_icon_url: cs.icon_url,
                                                  course_name: cs.name)}",
                        slices_count: 2)
          end

          offset_num += limit_count
          unless offset_num >= сs_count
            menu.inline_more_button(limit: limit_count,
                                    offset: offset_num,
                                    sum: сs_count,
                                    cb_prefix: "show_course_sessions_list:#{state}")
          end
        #rescue RuntimeError => e
        #  answer.send_out I18n.t('error').to_s
        end

        def show_course_session_info(cs_id)
          cs = appshell.course_session_info(cs_id)
          deadline = cs.deadline.nil? ? "\u221e" : Time.parse(Time.at(cs.deadline).strftime("%d.%m.%Y %H:%M"))
                                                       .strftime("%d.%m.%Y %H:%M")
          started_at = cs.started_at.nil? ? "-" : Time.parse(Time.at(cs.started_at).strftime("%d.%m.%Y %H:%M"))
                                                      .strftime("%d.%m.%Y %H:%M")
          text = "#{show_breadcrumbs(:course, [:name, :info], course_name: cs.name)}
                  \n  #{Emoji.t(:runner)}#{I18n.t('started_at')}: #{started_at}
                  \n  #{Emoji.t(:alarm_clock)}#{I18n.t('deadline')}: #{deadline}
                  \n  #{Emoji.t(:chart_with_upwards_trend)}#{I18n.t('progress')}: #{cs.progress}%
                  \n  #{Emoji.t(:star2)}#{I18n.t('complete_status')}: #{I18n.t("complete_status_#{cs.complete_status}")}
                  \n  #{Emoji.t(:trophy)}#{I18n.t('success')}: #{I18n.t("success_#{cs.success}")}"
          menu.create(buttons: [menu.inline_back_button],
                      type: :menu_inline,
                      text: text)
        rescue RuntimeError => e
          answer.send_out I18n.t('error').to_s
        end

        def show_sections_list_l1(cs_id)
          sections = appshell.course_session_sections(cs_id)
          cs = appshell.course_session_info(cs_id)
          if sections.empty?
            answer.send_out "\n#{show_breadcrumbs(:course, [:name, :contents], course_name: cs.name)}
                             \n#{Emoji.t(:soon)} <i>#{I18n.t('empty')}</i>"
          else
            params = %i[find_by_query_num show_avaliable show_unvaliable show_all]
            buttons = menu.inline_buttons(params, "show_sections_by_csid:#{cs_id}_param:")
            menu.create(buttons: buttons << menu.inline_back_button,
                        type: :menu_inline,
                        text: "#{show_breadcrumbs(:course, [:name, :contents, :sections], course_name: cs.name)}
                               \n#{I18n.t('avaliable')} #{I18n.t('section3')}: #{sections.where(is_available: true).size} #{I18n.t('from')} #{sections.size}",
                        slices_count: 3)
          end
        end

        def show_sections(cs_id, param)
          sections_bd = appshell.course_session_sections(cs_id, :without_api)
          return answer.empty_message if sections_bd.empty?

          cs_name = appshell.course_session_info(cs_id).name
          sections = case param
                     when :find_by_query_num
                       menu_mode = :none
                       answer.send_out "#{Emoji.t(:pencil2)} <b>#{I18n.t('enter_the_number')} #{I18n.t('section2')}:</b>"
                       sections_bd.where(position: appshell.request_data(:string))
                     when :show_all
                       sections_bd
                     when :show_avaliable
                       sections_bd.where(is_available: true, is_publish: true)
                     when :show_unvaliable
                       sections_bd.where(is_available: false)
                     else
                       raise "No such param: '#{param}' for showing sections"
                     end

          menu.create(buttons: [menu.inline_back_button],
                      mode: menu_mode || :edit_msg,
                      type: :menu_inline,
                      text: "#{show_breadcrumbs(:course, [:name, :contents, :section_menu], course_name: cs_name, section_menu: param)}
                             #{group_sections_by_status(sections, cs_id)}")
        rescue RuntimeError => e
          answer.send_out I18n.t('error').to_s
        end

        def show_section_contents(section_position, cs_id)
          contents = appshell.course_session_section_contents(section_position, cs_id)
          return answer.empty_message unless contents

          cs_name = contents[:section].course_session.name
          buttons = []
          contents[:section_content].keys.each do |content_type|
            emoji = attach_emoji(content_type)
            contents[:section_content][content_type].each do |object|
              callback = "open_content:#{content_type}_by_csid:#{cs_id}_secid:#{object.section_id}_objid:#{object.tb_id}"
              buttons << [text: "#{emoji} #{object.name}", callback_data: callback]
              @logger.debug "callback: #{callback}"
            end
          end
          menu.create(buttons: buttons << menu.inline_back_button,
                      mode: :none,
                      type: :menu_inline,
                      text: "#{show_breadcrumbs(:course, [:name, :contents, :section], course_name: cs_name, section: contents[:section])}")
        end

        def open_section_content(content_type, cs_tb_id, sec_id, content_tb_id)
          content = appshell.course_session_section_open_content(content_type, cs_tb_id, sec_id, content_tb_id)
          return answer.empty_message unless content

          cs_name = content.course_session.name
          section_bd = content.section        
          content_body = case content.content_type.to_sym
                         when :image
                           answer_content.photo(content.source)
                         when :video
                           answer_content.video(content.source)
                         when :pdf
                           answer_content.document(content.source)
                         when :audio
                           answer_content.audio(content.sourse)
                         when :vimeo, :youtube, :iframe
                           answer.send_out "<a href='#{content.source}'>OPEN IT</a>"
                         else
                           answer.send_out "Can't show such content type: #{content.content_type}"
                         end

          menu.create(buttons: [menu.inline_back_button],
                      type: :menu_inline,
                      text: "#{show_breadcrumbs(:course,
                                                [:name, :contents, :section, :content],
                                                course_name: cs_name,
                                                section: section_bd,
                                                content_type: content_type,
                                                content_name: content.name)}")
        end

        def update_course_sessions
          answer.send_out "#{Emoji.t(:arrows_counterclockwise)} <b>#{I18n.t('updating_data')}</b>"
          appshell.update_all_course_sessions
          answer.send_out "#{Emoji.t(:thumbsup)} #{I18n.t('updating_success')}"
        end

        def course_list_l1
          buttons = [[text: I18n.t('active_courses').capitalize, callback_data: "active_courses"],
                     [text: I18n.t('archived_courses').capitalize, callback_data: "archived_courses"],
                     [text: "#{Emoji.t(:arrows_counterclockwise)} #{I18n.t('update_course_sessions')}", callback_data: "update_course_sessions"]]
          menu.create(buttons: buttons,
                      mode: :none,
                      type: :menu_inline,
                      text: "#{Emoji.t(:books)}<b>#{I18n.t('show_course_list')}</b>",
                      slices_count: 2)
        end

        def match_data
          on %r{signin} do
            signin
          end

          on %r{edit_settings} do
            edit_settings
          end

          on %r{^settings:localization} do
            choose_localization
          end

          on %r{^language_param:} do
            @message_value =~ %r{^language_param:(\w*)}
            change_language($1)
          end

          on %r{settings:scenario} do
            choose_scenario
          end

          on %r{^scenario_param:} do
            @message_value =~ %r{^scenario_param:(\w*)}
            mode = $1
            change_scenario(mode)
            answer.send_out "#{Emoji.t(:floppy_disk)} #{I18n.t('editted')}. #{I18n.t('scenario')}: <b>#{I18n.t(mode)}</b>"
          end

          on %r{archived_courses} do
            show_course_sessions_list(:archived)
          end

          on %r{active_courses} do
            show_course_sessions_list(:active)
          end

          on %r{show_course_sessions_list} do
            @message_value =~ %r{^show_course_sessions_list:(\w*)_lim:(\d*)_offset:(\d*)}
            show_course_sessions_list($1, $2, $3)
          end

          on %r{update_course_sessions} do
            update_course_sessions
          end

          on %r{^cs_info_id:} do
            @message_value =~ %r{^cs_info_id:(\d*)}
            show_course_session_info($1)
          end

          on %r{^cs_sec_by_id:} do
            @message_value =~ %r{^cs_sec_by_id:(\d*)}
            show_sections_list_l1($1)
          end

          on %r{^show_sections_by_csid:} do
            @message_value =~ %r{^show_sections_by_csid:(\d*)_param:(\w*)}
            show_sections($1, $2.to_sym)
          end

          on %r{^open_content:} do
            @message_value =~ %r{^open_content:(\w*)_by_csid:(\d*)_secid:(\d*)_objid:(\d*)}
            open_section_content($1, $2, $3, $4)
          end
        end

        def match_text_action
          on %r{^/sec(\d*)_cs(\d*)} do
            @message_value =~ %r{^/sec(\d*)_cs(\d*)}
            show_section_contents($1, $2)
          end

          on %r{^/start} do
            answer.greeting_message
            menu.starting
          end

          on %r{^/settings} do
            settings
          end

          on %r{^/close} do
            menu.hide("<b>#{answer.user_fullname(:string)}!</b> #{I18n.t('farewell_message')} :'(")
          end
        end
        
        private

        def init_breadcrumbs(params)
          # TODO: Convert in Breadcrumbs class
          course_name = params[:course_name] || ""
          course_icon_url = params[:course_icon_url] || ""
          section_menu = params[:section_menu] || ""
          section = params[:section] || ""
          content_name = params[:content_name] || ""
          content_type = params[:content_type] || ""
          content_source = params[:content_source] || ""
          { course: { name: "#{Emoji.t(:book)} <a href='#{course_icon_url}'>#{I18n.t('course')}</a>: #{course_name}",
                      info: "#{Emoji.t(:information_source)} #{I18n.t('information')}",
                      contents: "#{Emoji.t(:arrow_down)} #{I18n.t('course_sections')}",
                      section_menu: "#{Emoji.t(:open_file_folder)} #{section_menu_title(section_menu)}",
                      section: "#{section_title(section, :string)}",
                      sections: "#{Emoji.t(:open_file_folder)} #{I18n.t('section2').capitalize}",
                      content: "#{attach_emoji(content_type.to_sym)} #{I18n.t('content').capitalize}: #{content_name}" }
          }
        end

        def section_menu_title(menu_state)
          case menu_state
          when :find_by_query_num
            "#{I18n.t('find_by_query_num').capitalize} #{I18n.t('section2')}"
          when :show_all
            I18n.t('show_all').capitalize.to_s
          when :show_avaliable
            I18n.t('show_avaliable').capitalize.to_s
          when :show_unvaliable
            I18n.t('show_unvaliable').capitalize.to_s
          end
        end

        def section_title(section_object, style)
          return unless section_object.is_a?(Teachbase::Bot::Section)

          emoji = [:open, :section_unable, :section_delayed, :section_unpublish].include?(style) ? attach_emoji(style) : Emoji.t(:open_file_folder)
          "#{emoji} <b>#{I18n.t('section')} #{section_object.position}:</b> #{section_object.name}"
        end

        def attach_emoji(param)
          case param
          when :open
            Emoji.t(:arrow_forward)
          when :section_unable
            Emoji.t(:no_entry_sign)
          when :section_delayed
            Emoji.t(:no_entry_sign)
          when :section_unpublish
            Emoji.t(:x)
          when :materials
            Emoji.t(:page_facing_up)
          when :tasks
            Emoji.t(:memo)
          when :quizzes
            Emoji.t(:bar_chart)
          when :scorm_packages
            Emoji.t(:computer)
          end
        end

        def group_sections_by_status(sections, cs_id)
          mess = []
          sections.each do |section|
            string = if section.is_publish && section.is_available
                       "\n#{section_title(section, :open)}.\n<i>#{I18n.t('open')}</i>: /sec#{section.position}_cs#{cs_id}"
                     elsif section.is_publish && !section.is_available && !section.opened_at
                       "\n#{section_title(section, :section_unable)}\n<i>#{I18n.t('section_unable')}</i>."
                     elsif section.is_publish && !section.is_available && section.opened_at
                       "\n#{section_title(section, :section_delayed)}:\n<i>#{I18n.t('section_delayed')}</i>: <i>#{Time.at(section.opened_at).utc.strftime('%d.%m.%Y %H:%M')}.</i>"
                     elsif !section.is_publish
                       "\n#{section_title(section, :section_unpublish)}\n<i>#{I18n.t('section_unpublish')}</i>."
                     end
            mess << string
          end
          return "\n#{Emoji.t(:soon)} <i>#{I18n.t('empty')}</i>" if mess.empty?

          mess.join("\n")
        end

      end
    end
  end
end
