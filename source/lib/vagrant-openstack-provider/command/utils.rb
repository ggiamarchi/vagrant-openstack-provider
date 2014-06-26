module VagrantPlugins
  module Openstack
    module Command
      module Utils
        def display_item_list(items)
          left_pad = '  '
          id_col_len = items.map   { |i| i.id.length   }.sort.last
          name_col_len = items.map { |i| i.name.length }.sort.last
          separator_len = id_col_len + name_col_len + 7
          @env.ui.info('')
          @env.ui.info("#{left_pad}#{''.center(separator_len, '-')}")
          @env.ui.info("#{left_pad}| #{'id'.center(id_col_len)} | #{'name'.center(name_col_len)} |")
          @env.ui.info("#{left_pad}#{''.center(separator_len, '-')}")
          items.each do |image|
            @env.ui.info("#{left_pad}| #{image.id.ljust(id_col_len)} | #{image.name.ljust(name_col_len)} |")
          end
          @env.ui.info("#{left_pad}#{''.center(separator_len, '-')}")
          @env.ui.info('')
        end
      end
    end
  end
end
