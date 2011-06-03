module OrderedTree
  module ClassMethods
    extend ActiveSupport::Concern

    included do
      belongs_to :parent_node, :class_name => name, :foreign_key => ordered_tree_config[:foreign_key]
      has_many :child_nodes, :class_name => name, :foreign_key => ordered_tree_config[:foreign_key], :order => ordered_tree_config[:order]
      scope :roots, lambda { { :conditions => {ordered_tree_config[:foreign_key] => 0}, :order => ordered_tree_config[:order].to_s } }

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
