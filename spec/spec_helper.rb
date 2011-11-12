$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'active_record'
require 'rspec'
require 'ordered_tree'
require 'fixtures/person'
require 'fixtures/page'
require 'fixtures/category'

#Allow to connect to SQLite
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
end

def reset_database
  %W(people pages categories).each do |table_name|
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS '#{table_name}'")
  end
  ActiveRecord::Base.connection.create_table(:people) do |t|
    t.integer :parent_id, :null => false, :default => 0
    t.integer :position
    t.string :name
    #add_index :people, [:parent_id], :name => "index_people_on_parent_id"
  end
  ActiveRecord::Base.connection.create_table(:pages) do |t|
    t.integer :parent_id
    t.integer :position
    t.string :name
    t.integer :person_id
  end
  ActiveRecord::Base.connection.create_table(:categories) do |t|
    t.integer :parent_id, :null => false, :default => 0
    t.integer :position
    t.integer :alt_id
    t.integer :person_id
  end
end

def ordered_tree(klass, *opts)
  klass.ordered_tree *opts
  yield
ensure
  klass.ordered_tree
end

# Test Tree
#
# We will be working with this tree through out the tests
#
# people[0]
#   \_ people[1]
#   \_ people[2]
#   |    \_ people[3]
#   |    \_ people[4]
#   |    |   \_ people[7]
#   |    |   \_ people[8]
#   |    \_ people[9]
#   |    \_ people[10]
#   \_ people[5]
#   \_ people[6]
#   |
#   |
# people[11]
#   \_ people[12]
#   \_ people[13]
#   |    \_ people[14]
#   |    \_ people[15]
#   |    |   \_ people[18]
#   |    |   \_ people[19]
#   |    \_ people[20]
#   |    \_ people[21]
#   \_ people[16]
#   \_ people[17]
#
#
#  +----+-----------+----------+-----------+
#  | id | parent_id | position | name      |
#  +----+-----------+----------+-----------+
#  |  1 |         0 |        1 | Person_1  |
#  |  2 |         1 |        1 | Person_2  |
#  |  3 |         1 |        2 | Person_3  |
#  |  4 |         3 |        1 | Person_4  |
#  |  5 |         3 |        2 | Person_5  |
#  |  6 |         1 |        3 | Person_6  |
#  |  7 |         1 |        4 | Person_7  |
#  |  8 |         5 |        1 | Person_8  |
#  |  9 |         5 |        2 | Person_9  |
#  | 10 |         3 |        3 | Person_10 |
#  | 11 |         3 |        4 | Person_11 |
#  | 12 |         0 |        2 | Person_12 |
#  | 13 |        12 |        1 | Person_13 |
#  | 14 |        12 |        2 | Person_14 |
#  | 15 |        14 |        1 | Person_15 |
#  | 16 |        14 |        2 | Person_16 |
#  | 17 |        12 |        3 | Person_17 |
#  | 18 |        12 |        4 | Person_18 |
#  | 19 |        16 |        1 | Person_19 |
#  | 20 |        16 |        2 | Person_20 |
#  | 21 |        14 |        3 | Person_21 |
#  | 22 |        14 |        4 | Person_22 |
#  +----+-----------+----------+-----------+
#
def reload_test_tree
  reset_database
  people = []
  i = 1
  people << Person.create(:name => "Person_#{i}")
  [0,2,0,4,2,-1,11,13,11,15,13].each do |n|
    if n == -1
      i = i.next
      people << Person.create(:name => "Person_#{i}")
      else
        2.times do
          i = i.next
          people << people[n].children.create(:name => "Person_#{i}")
        end
      end
    end
  end
