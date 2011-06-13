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

      private

      # Overwrite this method to define the scope of the list changes
      def scope_condition
        "1=1"
      end
    end
  end
end
