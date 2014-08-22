require 'terminal-table'

module VagrantPlugins
  module Openstack
    module Command
      module Utils
        def display_item_list(items)
          rows = []
          items.each do |item|
            rows << [item.id, item.name]
          end
          display_table(%w('Id' 'Name'), rows)
        end

        def display_table(headers, rows)
          table = Terminal::Table.new headings: headers, rows: rows
          @env.ui.info("\n#{table}\n")
        end
      end
    end
  end
end
