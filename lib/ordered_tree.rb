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
    self.ordered_tree_config.update(options) if options.is_a?(Hash)
    include OrderedTree::ClassMethods
    include OrderedTree::InstanceMethods
  end #ordered_tree
end #module OrderedTree

ActiveRecord::Base.extend OrderedTree
