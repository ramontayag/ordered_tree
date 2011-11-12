require 'ordered_tree/class_methods'
require 'ordered_tree/instance_methods'

module OrderedTree #:nodoc:
  # Configuration:
  #
  #   class Person < ActiveRecord::Base
  #     ordered_tree :foreign_key   => :parent_id,
  #                  :order         => :position
  #   end
  #
  #   class CreatePeople < ActiveRecord::Migration
  #     def self.up
  #       create_table :people do |t|
  #         t.column :parent_id ,:integer ,:null => false ,:default => 0
  #         t.column :position  ,:integer
  #       end
  #       add_index(:people, :parent_id)
  #     end
  #   end

  def ordered_tree(options = {})
    cattr_accessor :ordered_tree_config
    self.ordered_tree_config ||= {}
    self.ordered_tree_config[:foreign_key] ||= :parent_id
    self.ordered_tree_config[:order] ||= :position
    self.ordered_tree_config[:primary_key] ||= :id
    self.ordered_tree_config.update(options) if options.is_a?(Hash)

    belongs_to :parent_node,
      :class_name  => self.name,
      :foreign_key => ordered_tree_config[:foreign_key],
      :primary_key => ordered_tree_config[:primary_key],
      :conditions  => proc {scope_condition}
    has_many :child_nodes,
      :class_name  => self.name,
      :foreign_key => ordered_tree_config[:foreign_key],
      :primary_key => ordered_tree_config[:primary_key],
      :conditions  => proc {scope_condition},
      :order       => ordered_tree_config[:order]
    scope :roots, lambda { |*args|
      column = "#{self.table_name}.#{self.ordered_tree_config[:foreign_key].to_sym}"
      scope_condition = args[0]
      where(scope_condition).
        where("#{column} = 0 OR #{column} IS NULL").
        order(self.ordered_tree_config[:order])
    }

    include OrderedTree::ClassMethods
    include OrderedTree::InstanceMethods
  end #ordered_tree
end #module OrderedTree

ActiveRecord::Base.extend OrderedTree
