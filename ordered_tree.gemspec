# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ordered_tree}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ramon Tayag"]
  s.date = %q{2011-06-13}
  s.description = %q{Uses parent_id and position to create an ordered tree.}
  s.email = %q{ramon@tayag.net}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.textile"
  ]
  s.files = [
    ".rvmrc",
    "CHANGELOG",
    "Gemfile",
    "Gemfile.lock",
    "Guardfile",
    "LICENSE.txt",
    "README.textile",
    "Rakefile",
    "VERSION",
    "lib/ordered_tree.rb",
    "lib/ordered_tree/class_methods.rb",
    "lib/ordered_tree/instance_methods.rb",
    "lib/ordered_tree/instance_methods/destroy.rb",
    "lib/ordered_tree/instance_methods/list.rb",
    "lib/ordered_tree/instance_methods/misc.rb",
    "lib/ordered_tree/instance_methods/tree.rb",
    "ordered_tree.gemspec",
    "spec/fixtures/page.rb",
    "spec/fixtures/person.rb",
    "spec/ordered_tree_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/ramontayag/ordered_tree}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Gem version of Wizard's ActsAsTree}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<libnotify>, [">= 0"])
      s.add_development_dependency(%q<rb-inotify>, [">= 0"])
    else
      s.add_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<libnotify>, [">= 0"])
      s.add_dependency(%q<rb-inotify>, [">= 0"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 3.0.0"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<libnotify>, [">= 0"])
    s.add_dependency(%q<rb-inotify>, [">= 0"])
  end
end

