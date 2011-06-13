module OrderedTree
  module ClassMethods
    extend ActiveSupport::Concern
    included do
      def foreign_key_column
        :"#{ordered_tree_config[:foreign_key]}"
      end

      def order_column
        :"#{ordered_tree_config[:order]}"
      end

      before_create :add_to_list
      before_update :check_list_changes
      after_update :reorder_old_list
      before_destroy :destroy_descendants
      after_destroy :reorder_old_list
      validate :check_parentage, :on => :update
    end
  end
end
