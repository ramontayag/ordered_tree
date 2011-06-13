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

    belongs_to :parent_node, :class_name => self.name, :foreign_key => ordered_tree_config[:foreign_key]
    has_many :child_nodes, :class_name => self.name, :foreign_key => ordered_tree_config[:foreign_key], :order => ordered_tree_config[:order]
    scope :roots, lambda { |*args|
      scope_condition = args[0]
      where(self.ordered_tree_config[:foreign_key].to_sym => 0).where(scope_condition).order(self.ordered_tree_config[:order])
    }

    # If the scope is something like :person, then turn it into :person_id
    if self.ordered_tree_config[:scope].is_a?(Symbol) && self.ordered_tree_config[:scope].to_s !~ /_id$/
      self.ordered_tree_config[:scope] = "#{self.ordered_tree_config[:scope]}_id".intern
    end

    if self.ordered_tree_config[:scope].is_a?(Symbol) # ie :person_id
      define_method "scope_condition" do
        self.class.send(:sanitize_sql_hash_for_conditions, {self.class.ordered_tree_config[:scope].to_sym => send(self.class.ordered_tree_config[:scope].to_sym)})
      end
    end

    include OrderedTree::ClassMethods
    include OrderedTree::InstanceMethods
  end #ordered_tree
end #module OrderedTree

ActiveRecord::Base.extend OrderedTree
