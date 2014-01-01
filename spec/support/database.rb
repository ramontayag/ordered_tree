ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

def reset_database
  %W(people pages categories).each do |table_name|
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS '#{table_name}'")
  end
  ActiveRecord::Base.connection.create_table(:people) do |t|
    t.integer :parent_id, null: false, default: 0
    t.integer :position
    t.string :name
    #add_index :people, [:parent_id], name: "index_people_on_parent_id"
  end
  ActiveRecord::Base.connection.create_table(:pages) do |t|
    t.integer :parent_id
    t.integer :position
    t.string :name
    t.integer :person_id
  end
  ActiveRecord::Base.connection.create_table(:categories) do |t|
    t.integer :parent_id
    t.integer :position
    t.integer :alt_id
    t.integer :person_id
  end
end
