module OrderedTree
  module InstanceMethods
    module Misc
      protected

      def foreign_key_column
        :"#{ordered_tree_config[:foreign_key]}"
      end

      def order_column
        :"#{ordered_tree_config[:order]}"
      end
    end
  end
end
