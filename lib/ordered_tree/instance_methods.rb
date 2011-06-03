require 'ordered_tree/instance_methods/tree'
require 'ordered_tree/instance_methods/list'
require 'ordered_tree/instance_methods/destroy'
require 'ordered_tree/instance_methods/misc'

module OrderedTree
  module InstanceMethods
    include OrderedTree::InstanceMethods::Tree
    include OrderedTree::InstanceMethods::List
    include OrderedTree::InstanceMethods::Destroy
    include OrderedTree::InstanceMethods::Misc
  end 
end
