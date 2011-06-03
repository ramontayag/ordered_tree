module OrderedTree
  module InstanceMethods
    module Tree
      ## Tree Read Methods

      # returns the top node in the object's tree
      #
      #   return is cached, unless nil
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
      #   instead of returning "<parent_node not loaded yet>"
      #
      #   return is cached, unless nil
      #   use parent(true) to force a reload
      def parent(reload=false)
        reload = true if !@parent
        reload ? parent_node(true) : @parent
      end

      # returns an array of the object's immediate children
      #   auto-loads itself on first access
      #   instead of returning "<child_nodes not loaded yet>"
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

      ## Tree Update Methods

      # shifts a node to another parent, optionally specifying it's position
      #   (descendants will follow along)
      #
      #   shift_to()
      #     defaults to the bottom of the "roots" list
      #
      #   shift_to(nil, new_sibling)
      #     will move the item to "roots",
      #     and position the item above new_sibling
      #
      #   shift_to(new_parent)
      #     will move the item to the new parent,
      #     and position at the bottom of the parent's list
      #
      #   shift_to(new_parent, new_sibling)
      #     will move the item to the new parent,
      #     and position the item above new_sibling
      #
      def shift_to(new_parent = nil, new_sibling = nil)
        if new_parent
          ok = new_parent.children(true) << self
        else
          ok = orphan
        end
        if ok && new_sibling
          ok = move_above(new_sibling) if self_and_siblings(true).include?(new_sibling)
        end
        return ok
      end

      # orphans the node (sends it to the roots list)
      #   (descendants follow)
      def orphan
        self[foreign_key_column] = 0
        self.save
      end

      # orphans the node's children
      #   sends all immediate children to the 'roots' list
      def orphan_children
        self.class.transaction do
          children(true).each{|child| child.orphan}
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
          orphan
        end
      end

      # hands children off to parent (if possible), then orphans itself
      def orphan_self_and_parent_adopts_children
        self.class.transaction do
          parent_adopts_children
          orphan
        end
      end
    end

    protected

    def check_parentage #:nodoc:
      if !self_and_siblings(true).include?(self)
        if self.parent == self
          errors.add(:base, "cannot be a parent to itself.")
        elsif (self.parent && self.descendants(true).include?(self.parent))
          errors.add(:base, "is an ancestor of the new parent.")
        end
      end
    end

    private

    def find_root
      node = self
      node = node.parent while node.parent(true)
      node
    end

    def find_ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent(true)
      nodes
    end

    # recursive method
    def find_descendants(node)
      @descendants ||= []
      node.children(true).each do |child|
        @descendants << child
        find_descendants(child)
      end
      @descendants
    end

  end
end

