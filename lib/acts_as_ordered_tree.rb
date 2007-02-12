# Acts As Ordered Tree v.0.2
# Copyright (c) 2006 Brian D. Burns <wizard.rb@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module WizardActsAsOrderedTree #:nodoc:
  module Acts #:nodoc:
    module OrderedTree #:nodoc:
      def self.included(base)
        base.extend AddActsAsMethod
      end

      module AddActsAsMethod
        # Configuration:
        #
        #   class Person < ActiveRecord::Base
        #     acts_as_ordered_tree :foreign_key => :parent_id,
        #                          :order       => :position
        #   end
        #
        #   class CreatePeople < ActiveRecord::Migration
        #     def self.up
        #       create_table :people do |t|
        #         t.column :parent_id ,:integer
        #         t.column :position  ,:integer
        #       end
        #       add_index(:people, :parent_id)
        #     end
        #   end
        #
        def acts_as_ordered_tree(options = {})
          # TODO: add counter_cache option
          configuration = { :foreign_key   => :parent_id ,
                            :order         => :position  }
          configuration.update(options) if options.is_a?(Hash)

          belongs_to :parent_node,
                     :class_name    => name,
                     :foreign_key   => configuration[:foreign_key]

          has_many   :child_nodes,
                     :class_name    => name,
                     :foreign_key   => configuration[:foreign_key],
                     :order         => configuration[:order]

          class_eval <<-EOV
            include WizardActsAsOrderedTree::Acts::OrderedTree::InstanceMethods

            def foreign_key_column
              '#{configuration[:foreign_key]}'
            end

            def order_column
              '#{configuration[:order]}'
            end

            # returns an ordered array of all nodes without a parent
            #   think of their parent as being the tree trunk
            def self.roots(reload = false)
              reload = true if !@roots
              reload ? find(:all, :conditions => "#{configuration[:foreign_key]} IS NULL", :order => "#{configuration[:order]}") : @roots
            end

            before_update  :check_list_changes
            after_update   :reorder_old_list
            before_create  :add_to_list
            before_destroy :destroy_descendants
            after_destroy  :remove_from_list
          EOV
        end #acts_as_ordered_tree
      end #module AddActsAsMethod

      module InstanceMethods
        ## Tree Read Methods

        # returns the top node in the object's tree
        #
        #   return is cached
        #   use root(true) to force a reload
        def root(reload = false)
          reload = true if !@root
          reload ? find_root : @root
        end

        # returns an array of ancestors, starting from parent until root.
        #   return is cached
        #   use ancestors(true) to force a reload
        def ancestors(reload = false)
          reload = true if !@ancestors
          reload ? find_ancestors : @ancestors
        end

        # returns object's parent in the tree
        #   auto-loads itself on first access
        #   instead of getting "<parent_node not loaded yet>"
        #
        #   return is cached
        #   use parent(true) to force a reload
        def parent(reload=false)
          reload = true if !@parent
          reload ? parent_node(true) : @parent
        end

        # returns an array of the object's immediate children
        #   auto-loads itself on first access
        #   instead of "<child_nodes not loaded yet>"
        #
        #   return is cached
        #   use children(true) to force a reload
        def children(reload=false)
          reload = true if !@children
          reload ? child_nodes(true) : @children
        end

        # returns an array of the object's descendants
        #
        #   return is cached
        #   use descendants(true) to force a reload
        def descendants(reload = false)
          @descendants = nil if reload
          reload = true if !@descendants
          reload ? find_descendants(self) : @descendants
        end

        ## List Read Methods

        # returns an array of the object's syblings, including itself
        #
        #   return is cached
        #   use self_and_syblings(true) to force a reload
        def self_and_syblings(reload = false)
          parent(reload) ? parent.children(reload) : self.class.roots(reload)
        end

        # returns an array of the object's syblings, excluding itself
        #
        #   return is cached
        #   use syblings(true) to force a reload
        def syblings(reload = false)
          self_and_syblings(reload) - [self]
        end

        # returns object's position in the list
        #   the list will either be parent.children,
        #   or self.class.roots
        #
        # i.e. self.position
        def position_in_list
          self[order_column]
        end

        ## Tree Update Methods

        # shifts a node to another parent, optionally specifying it's position
        #   (descendants will follow along)
        #
        #   shift_to()
        #     defaults to the bottom of the "roots" list
        #
        #   shift_to(nil, new_sybling)
        #     will move the item to "roots",
        #     and position the item above new_sybling
        #
        #   shift_to(new_parent)
        #     will move the item to the new parent,
        #     and position at the bottom of the parent's list
        #
        #   shift_to(new_parent, new_sybling)
        #     will move the item to the new parent,
        #     and position the item above new_sybling
        #
        def shift_to(new_parent = nil, new_sybling = nil)
          if new_parent
            ok = new_parent.children(true) << self
          else # shifting to roots
            ok = orphan_self
          end
          if ok && new_sybling
            ok = move_above(new_sybling) if self_and_syblings(true).include?(new_sybling)
          end
          return ok
        end

        # orphans the node (sends it to the roots list)
        #   (descendants follow)
        def orphan_self
          self[foreign_key_column] = nil
          self.update
        end

        # orphans the node's children
        #   sends all immediate children to the 'roots' list
        def orphan_children
          self.class.transaction do
            children(true).each{|child| child.orphan_self}
          end
        end

        # hands children off to parent
        #   if no parent, children will be orphaned
        def parent_adopts_children
          if parent(true)
            self.class.transaction do
              children(true).each{|child| parent.children << child}
            end
          else
            orphan_children
          end
        end

        # sends self and immediate children to the roots list
        def orphan_self_and_children
          self.class.transaction do
            orphan_children
            orphan_self
          end
        end

        # hands children off to parent (if possible), then orphans itself
        def orphan_self_and_parent_adopts_children
          self.class.transaction do
            parent_adopts_children
            orphan_self
          end
        end

        ## List Update Methods

        # moves the item above sybling in the list
        #   defaults to the top of the list
        def move_above(sybling = nil)
          if sybling
            return if (!self_and_syblings(true).include?(sybling) || (sybling == self))
            if sybling.position_in_list > position_in_list
              move_to(sybling.position_in_list - 1)
            else
              move_to(sybling.position_in_list)
            end
          else
            move_to_top
          end
        end

        # move to the top of the list
        def move_to_top
          return if position_in_list == 1
          move_to(1)
        end

        # swap with the node above self
        def move_up
          return if position_in_list == 1
          move_to(position_in_list - 1)
        end

        # swap with the node below self
        def move_down
          return if self == self_and_syblings.last
          move_to(position_in_list + 1)
        end

        # move to the bottom of the list
        def move_to_bottom
          return if self == self_and_syblings.last
          move_to(self_and_syblings(true).last.position_in_list)
        end

        ## Destroy Methods

        # sends immediate children to the 'roots' list, then destroy's self
        #   i.e. self.orphan_children && self.destroy
        def destroy_and_orphan_children
          self.class.transaction do
            orphan_children
            self.destroy
          end
        end

        # hands immediate children of to it's parent, then destroy's self
        #   i.e. self.parent_adopts_children && self.destroy
        def destroy_and_parent_adopts_children
          self.class.transaction do
            parent_adopts_children
            self.destroy
          end
        end

        private
          def find_root
            node = self
            node = node.parent while node.parent
            node
          end

          # TODO: add ceiling option?
          def find_ancestors
            node, nodes = self, []
            nodes << node = node.parent while node.parent
            nodes
          end

          # TODO: add depth option?
          # recursive method
          def find_descendants(node)
            @descendants ||= []
            node.children(true).each do |child|
              @descendants << child
              find_descendants(child)
            end
            @descendants
          end

          def add_to_list
            new_position = position_in_list if (1..self_and_syblings(true).size).include?(position_in_list.to_i)
            add_to_list_bottom
            move_to(new_position, true) if new_position
          end

          def add_to_list_bottom
            self[order_column] = self_and_syblings.size + 1
          end

          def move_to(new_position, on_create = false)
            if parent(true)
              scope = "#{foreign_key_column} = #{parent.id}"
            else
              scope = "#{foreign_key_column} IS NULL"
            end
            if new_position < position_in_list
              # moving from lower to higher, increment all in between
              # #{order_column} >= #{new_position} AND #{order_column} < #{position_in_list}
              self.class.transaction do
                self.class.update_all(
                  "#{order_column} = (#{order_column} + 1)", "#{scope} AND (#{order_column} BETWEEN #{new_position} AND #{position_in_list - 1})"
                )
                if on_create
                  self[order_column] = new_position
                else
                  update_attribute(order_column, new_position)
                end
              end
            else
              # moving from higher to lower, decrement all in between
              # #{order_column} > #{position_in_list} AND #{order_column} <= #{new_position}
              self.class.transaction do
                self.class.update_all(
                  "#{order_column} = (#{order_column} - 1)", "#{scope} AND (#{order_column} BETWEEN #{position_in_list + 1} AND #{new_position})"
                )
                update_attribute(order_column, new_position)
              end
            end
          end

          def reorder_children
            self.class.transaction do
              children(true).each do |child|
                new_position = children.index(child) + 1
                child.update_attribute(order_column, new_position) if (child.position_in_list != new_position)
              end
            end
          end

          def reorder_roots
            self.class.transaction do
              self.class.roots(true).each do |root|
                new_position = self.class.roots.index(root) + 1
                root.update_attribute(order_column, new_position) if (root.position_in_list != new_position)
              end
            end
          end

          protected
            def destroy_descendants #:nodoc:
              # before_destroy callback (recursive)
              self.children(true).each{|child| child.destroy}
            end

            def check_list_changes #:nodoc:
              # before_validation_on_update callback
              #
              # Note: to shift to another parent AND specify a position, use shift_to()
              # i.e. don't assign the object a new position, then new_parent << obj
              # this will end up at the bottom of the list.
              #
              if !self_and_syblings(true).include?(self)
                add_to_list_bottom
                @old_parent = self.class.find(self).parent
                @old_parent ||= 'root'
              end
            end

            def validate #:nodoc:
              if !self_and_syblings(true).include?(self)
                if self.parent == self
                  errors.add_to_base("cannot be a parent to itself.")
                elsif (self.parent && self.descendants(true).include?(self.parent))
                  errors.add_to_base("is an ancestor of the new parent.")
                end
              end
            end

            def reorder_old_list #:nodoc:
              # after_update callback
              # if our parent changed, re-order the old list
              if @old_parent == 'root'
                reorder_roots
              elsif @old_parent
                @old_parent.reorder_children
              end
            end

            def remove_from_list #:nodoc:
              # after_destroy callback
              # re-order the list we were removed from
              parent ? parent.reorder_children : reorder_roots
            end

          #protected
        #private
      end #module InstanceMethods
    end #module OrderedTree
  end #module Acts
end #module WizardActsAsOrderedTree
