require 'spec_helper'

describe OrderedTree do
  before do
    reload_test_tree
    @people = Person.all
  end

  describe "when a scope is supplied" do
    # This is especially important for working with root items that may belong to different accounts
    it "should only work within that scope" do
      # when the scope is an association
      ordered_tree Page, :scope => :person do
        Page.create(:person => @people[0]).position.should == 1
        Page.create(:person => @people[2]).position.should == 1
        Page.create(:person => @people[0]).position.should == 2
        Page.create(:person => @people[1]).position.should == 1
      end

      # when the scope is an association id
      ordered_tree Page, :scope => :person_id do
        Page.create(:person => @people[0]).position.should == 3
        Page.create(:person => @people[2]).position.should == 2
        Page.create(:person => @people[0]).position.should == 4
        Page.create(:person => @people[1]).position.should == 2
      end

      # when the scope_condition method is overridden
      Page.class_eval do
        def scope_condition
          "person_id = #{person_id} AND name = '#{name}'"
        end
      end
      Page.create(:person => @people[3], :name => "frankenstein").position.should == 1
      Page.create(:person => @people[3], :name => "steiners").position.should == 1
      Page.create(:person => @people[3], :name => "frankenstein").position.should == 2
    end
  end

  describe "when assigning parent" do
    it "should do a bunch of tests on validation" do
      # "should not allow an ancestor of a node to be a child of that node"
      (@people[4].children << @people[0]).should be_false
      @people[0].errors[:base].should include("is an ancestor of the new parent.")
      (@people[7].children << @people[2]).should be_false
      @people[0].errors[:base].should include("is an ancestor of the new parent.")

      # "should not allow a node to be a parent of itself"
      (@people[3].children << @people[3]).should be_false
      @people[3].errors[:base].should include("cannot be a parent to itself.")

      # I guess what this means that if there's an operation that fails, it should stay that
      # way until it's reloaded.
      # "should remember that the failed operations leave you with tainted objects"
      @people[2].parent == @people[7]
      @people[2].reload
      @people[0].reload
      @people[2].parent != @people[7]
    end
  end

  describe "when validate :on => :update is called," do
    it "should reload the descendants" do
      @people[2].descendants # load descendants, so we can begin tests to see if it's reloaded again later
      @people[5].children << @people[7]
      @people[5].children.should include(@people[7])

      # since people[2].descendants has already been loaded above,
      # it still includes people[7] as a descendant
      @people[2].descendants.should include(@people[7])

      # so, without the reload on people[2].descendants in validate_on_update,
      # the following would fail

      # How to test for this?
      #(@people[7].children << @people[2]).should be_false
      # assert people[7].children << people[2], 'Validation Failed: descendants must be reloaded in validate_on_update'
    end
  end

  describe "on descendants" do
    it "should give the correct count" do
      roots = Person.roots
      roots.should_not be_empty
      count = 0
      roots.each {|root| count = count + root.descendants.size + 1}
      count.should == Person.count
    end

    it "it should destroy them properly" do
      7.should == @people[2].descendants.size + 1
      @people[2].destroy
      Person.count.should == @people.size - 7
    end
  end

  describe "#ancestors" do
    it "should return the ancestors in proper order" do
      @people[7].ancestors.should == [@people[4], @people[2], @people[0]]
    end
  end

  describe "#root" do
    it "should return the root of the current node" do
      @people[7].root.should == @people[0]
    end
  end

  describe "class#roots" do
    it "should return all the roots" do
      Person.roots.should == [@people[0], @people[11]]
    end
  end

  it "should reorder the list when stuff are destroyed" do
    @people[0].descendants.should == [@people[1],@people[2],@people[3],@people[4],@people[7],@people[8],@people[9],@people[10],@people[5],@people[6]]
    @people[5].self_and_siblings.should == [@people[1],@people[2],@people[5],@people[6]]
    @people[5].position_in_list.should == 3
    # taint people[2].parent (since the plugin protects against this)
    @people[10].children << @people[2]
    @people[2].parent.should == @people[10]
    @people[2].destroy.should_not be_nil
    Person.count.should == @people.count - 7
    # Note that I don't need to reload self_and_siblings or children in this case,
    # since the re-ordering action is actually happening against people[0].children
    # (which is what self_and_syblings returns)
    @people[5].self_and_siblings.should == @people[0].children
    @people[5].self_and_siblings.should == [@people[1],@people[5],@people[6]]
    @people[5].reload
    @people[5].position_in_list.should == 2
    # of course, descendants must always be reloaded
    @people[0].descendants.should include(@people[7])
    @people[0].descendants(true).should_not include(@people[7])
  end

  it "should reorder properly" do
    # when moving a child to another parent
    (@people[13].children << @people[4]).should_not be_false
    @people[4].position_in_list.should == 5
    @people[9].reload
    @people[9].position_in_list.should == 2
    # when moving root to a child of another
    (@people[13].children << @people[0]).should_not be_false
    @people[0].position_in_list.should == 6
    @people[11].reload
    @people[11].position_in_list.should == 1
  end

  describe "#move_higher" do
    it "should properly update the position" do
      (@people[9].move_higher).should_not be_false
      @people[9].position_in_list.should == 2
      @people[4].reload
      @people[4].position_in_list.should == 3
    end
  end

  describe "#move_lower" do
    it "should peroperly update the position" do
      (@people[4].move_lower).should_not be_false
      @people[4].position_in_list.should == 3
      @people[9].reload
      @people[9].position_in_list.should == 2
    end
  end

  describe "#move_to_top" do
    it "should do properly set the position_in_list" do
      (@people[4].move_to_top).should_not be_false
      @people = Person.all
      @people[4].position_in_list.should == 1
      @people[3].position_in_list.should == 2
      @people[9].position_in_list.should == 3
      @people[10].position_in_list.should == 4
    end
  end

  describe "#move_to_bottom" do
    it "should do properly set the position_in_list" do
      @people = Person.find(:all)
      (@people[4].move_to_bottom).should_not be_false
      @people = Person.find(:all)
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
      @people[4].position_in_list.should == 4
    end
  end

  describe "#move_above, moving higher," do
    it "should do properly set the position_in_list" do
      (@people[10].move_above(@people[4])).should_not be_false
      @people = Person.all
      @people[2].children.should == [@people[3],@people[10],@people[4],@people[9]]
      @people[3].position_in_list.should == 1
      @people[10].position_in_list.should == 2
      @people[4].position_in_list.should == 3
      @people[9].position_in_list.should == 4
    end
  end

  describe "#move_above, moving_lower," do
    it "should do something" do
      (@people[3].move_above(@people[10])).should_not be_false
      @people = Person.all
      @people[2].children.should == [@people[4],@people[9],@people[3],@people[10]]
      @people[4].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[3].position_in_list.should == 3
      @people[10].position_in_list.should == 4
    end
  end

  describe "#shift_to, with_position," do
    it "should do properly set the position_in_list" do
      (@people[4].shift_to(@people[13], @people[20])).should_not be_false
      @people = Person.all
      @people[2].children.should == [@people[3],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
      @people[13].children.should == [@people[14],@people[15],@people[4],@people[20],@people[21]]
      @people[14].position_in_list.should == 1
      @people[15].position_in_list.should == 2
      @people[4].position_in_list.should == 3
      @people[20].position_in_list.should == 4
      @people[21].position_in_list.should == 5
    end
  end

  describe "#shift_to, without_position" do
    before do
      @people[4].shift_to(@people[13])
      @people = Person.all
    end

    it "should change the old siblings position_in_list accordingly" do
      @people[2].children.should == [@people[3],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
    end

    it "should go to the bottom of the new parent's children" do
      @people[13].children.should == [@people[14],@people[15],@people[20],@people[21],@people[4]]
      @people[14].position_in_list.should == 1
      @people[15].position_in_list.should == 2
      @people[20].position_in_list.should == 3
      @people[21].position_in_list.should == 4
      @people[4].position_in_list.should == 5
    end
  end

  describe "#shift_to roots (without position, ie orphan)" do
    before do
      @people[4].orphan
      @people = Person.all
    end

    it "should do adjust the old siblings accordingly" do
      @people[2].children.should == [@people[3],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
    end

    it "should move it to the root, and add it to the bottom of the root list" do
      Person.roots.should == [@people[0],@people[11],@people[4]]
      @people[0].position_in_list.should == 1
      @people[11].position_in_list.should == 2
      @people[4].position_in_list.should == 3
    end
  end

  describe "#shift_to roots with position argument" do
    before do
      @people[4].shift_to(nil, @people[11])
      @people = Person.all
    end

    it "should do properly collapse the position of the old siblings" do
      @people[2].children.should == [@people[3],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
    end

    it "should add the node to the root, at the specified location" do
      Person.roots.should == [@people[0],@people[4],@people[11]]
      @people[0].position_in_list.should == 1
      @people[4].position_in_list.should == 2
      @people[11].position_in_list.should == 3
    end
  end

  describe "#orphan_children" do
    it "should do properly move the children to the root" do
      @people[2].orphan_children
      @people = Person.all
      @people[2].children.should be_empty
      Person.roots.should == [@people[0],@people[11],@people[3],@people[4],@people[9],@people[10]]
    end
  end

  describe "#parent_adopts_children" do
    it "should do make the node belong to the parent" do
      @people[4].parent_adopts_children
      @people = Person.all
      @people[4].children.should be_empty
      @people[2].children.should == [@people[3],@people[4],@people[9],@people[10],@people[7],@people[8]]
    end
  end

  describe "#orphan_self_and_children" do
    it "should do move self and children to the roots" do
      @people[2].orphan_self_and_children
      @people = Person.all
      @people[2].children.should be_empty
      Person.roots.should == [@people[0],@people[11],@people[3],@people[4],@people[9],@people[10],@people[2]]
    end
  end

  describe "#orphan_self_and_parent_adopts_children" do
    before do
      @people[4].orphan_self_and_parent_adopts_children
      @people = Person.all
    end

    it "should do make itself an orphan" do
      @people[4].children.should be_empty
      Person.roots.should == [@people[0],@people[11],@people[4]]
    end

    it "should let the parent adopt its children" do
      @people[2].children.should == [@people[3],@people[9],@people[10],@people[7],@people[8]]
      @people[3].position_in_list.should == 1
      @people[9].position_in_list.should == 2
      @people[10].position_in_list.should == 3
      @people[7].position_in_list.should == 4
      @people[8].position_in_list.should == 5
    end
  end

  describe "#destroy_and_orphan_children" do
    before do
      @people[2].destroy_and_orphan_children
      @people = Person.all
    end

    it "should do destroy itself, and make children root" do
      # remember, since we deleted @people[2], all below get shifted up
      Person.roots.should == [@people[0],@people[10],@people[2],@people[3],@people[8],@people[9]]
      @people[0].children.should == [@people[1],@people[4],@people[5]]
      @people[1].position_in_list.should == 1
      @people[4].position_in_list.should == 2
      @people[5].position_in_list.should == 3
    end
  end

  describe "#destroy_and_parent_adopts_children" do
    before do
      @people[4].destroy_and_parent_adopts_children
      @people = Person.all
    end

    it "should destroy self, and let the parent adopt the children" do
      # remember, since we deleted @people[4], all below get shifted up
      @people[2].children.should == [@people[3],@people[8],@people[9],@people[6],@people[7]]
      @people[3].position_in_list.should == 1
      @people[8].position_in_list.should == 2
      @people[9].position_in_list.should == 3
      @people[6].position_in_list.should == 4
      @people[7].position_in_list.should == 5
    end
  end

  describe "when inserting a new node with a position already set" do
    before do
      @people[2].children << Person.new(:position => 3, :name => 'Person_23')
      @people = Person.all
    end

    it "should do insert that node in the position, shifting down the other nodes" do
      @people[2].children.should == [@people[3],@people[4],@people[22],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[4].position_in_list.should == 2
      @people[22].position_in_list.should == 3
      @people[9].position_in_list.should == 4
      @people[10].position_in_list.should == 5
    end
  end

  describe "creating a node, passing the parent_id and position already" do
    before do
      Person.create(:parent_id => @people[2].id, :position => 2, :name => 'Person_23')
      @people = Person.all
    end

    it "should insert the new node in that position, under that parent" do
      @people[2].children.should == [@people[3],@people[22],@people[4],@people[9],@people[10]]
      @people[3].position_in_list.should == 1
      @people[22].position_in_list.should == 2
      @people[4].position_in_list.should == 3
      @people[9].position_in_list.should == 4
      @people[10].position_in_list.should == 5
    end
  end

  describe "creating a child node with a position already set" do
    before do
      @people[2].children.create(:position => 4, :name => 'Person_23')
      @people = Person.all
    end

    it "should insert that child in that position (pushing the others down)" do
      @people[2].children.should == [@people[3],@people[4],@people[9],@people[22],@people[10]]
      @people[3].position_in_list.should == 1
      @people[4].position_in_list.should == 2
      @people[9].position_in_list.should == 3
      @people[22].position_in_list.should == 4
      @people[10].position_in_list.should == 5
    end
  end

  describe "creating a root with a position already set" do
    before do
      Person.create(:position => 2, :name => 'Person_23')
      @people = Person.all
    end

    it "should do insert it in the root, pushing down the others" do
      Person.roots.should == [@people[0],@people[22],@people[11]]
      @people[0].position_in_list.should == 1
      @people[22].position_in_list.should == 2
      @people[11].position_in_list.should == 3
    end
  end

  describe "creating with a position that's higher than the bottom" do
    it "should go to the bottom of the list" do
      person_23 = @people[2].children.create(:position => 15, :name => 'Person_23')
      person_23.position_in_list.should == 5
    end
  end
end
