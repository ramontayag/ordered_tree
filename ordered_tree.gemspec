require "ordered_tree/version"

Gem::Specification.new do |s|
  s.name = %q{ordered_tree}
  s.version = OrderedTree::VERSION

  s.authors = ["Ramon Tayag"]
  s.date = %q{2011-11-13}
  s.description = %q{Uses parent_id and position to create an ordered tree.}
  s.homepage = %q{http://github.com/ramontayag/ordered_tree}
  s.licenses = ["MIT"]
  s.summary = %q{Gem version of Wizard's ActsAsTree}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.email = %q{ramon@tayag.net}

  s.add_runtime_dependency(%q<activerecord>, [">= 3.1.1"])
  s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
  s.add_development_dependency(%q<sqlite3>, [">= 0"])
end
