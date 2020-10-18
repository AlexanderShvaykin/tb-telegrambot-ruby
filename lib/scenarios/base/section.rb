# frozen_string_literal: true

module Teachbase
  module Bot
    module Scenarios
      module Base
        module Section
          def sections_choose(cs_tb_id)
            sections = appshell.data_loader.cs(tb_id: cs_tb_id).sections
            return interface.sys.text.on_empty if sections.empty?

            cs = sections.first.course_session
            interface.section(cs).menu(stages: %i[title],
                                       back_button: { mode: :custom,
                                                      action: router.cs(path: :list, p: [type: :states]).link })
                     .main
          rescue RuntimeError => e
            return interface.sys.text.on_empty if e.http_code == 404
          end

          def sections_by(option, cs_tb_id)
            option = option.to_sym
            all_sections = appshell.data_loader.cs(tb_id: cs_tb_id).sections
            sections_by_option = find_sections_by(option, all_sections)
            return interface.sys.text.on_empty if all_sections.empty? || sections_by_option.empty?

            cs = sections_by_option.first.course_session
            interface.section(cs).menu(stages: %i[title menu],
                                       params: { state: "#{option}_sections" }).show_by_option(sections_by_option, option)
          end

          def section_contents(cs_tb_id, sec_pos)
            section_loader = appshell.data_loader.section(option: :position, value: sec_pos,
                                                          cs_tb_id: cs_tb_id)
            check_status do
              return interface.sys.text.on_empty unless section_loader.contents

              section_loader.progress
            end
            interface.section(section_loader.db_entity)
                     .menu(stages: %i[title], back_button: { mode: :custom,
                                                             action: router.cs(path: :entity, id: cs_tb_id).link })
                     .contents
          end

          def section_additions(cs_tb_id, sec_id)
            section_loader = appshell.data_loader.section(option: :id, value: sec_id, cs_tb_id: cs_tb_id)
            return interface.sys.text.on_empty if section_loader.links.empty?

            interface.sys(section_loader.db_entity)
                     .menu(back_button: build_back_button_data, links: section_loader.links, stages: %i[title]).links
          end

          protected

          def find_sections_by(option, sections)
            case option
            when :find_by_query_num
              interface.sys.text.ask_enter_the_number(:section)
              sections.where(position: appshell.request_data(:string).text)
            when :show_all
              sections
            when :show_avaliable
              sections.where(is_available: true, is_publish: true)
            when :show_unvaliable
              sections.where(is_available: false)
            else
              raise "No such option: '#{option}' for showing sections"
            end
          end
        end
      end
    end
  end
end