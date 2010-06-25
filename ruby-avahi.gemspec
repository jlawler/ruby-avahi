# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-avahi}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["pangdudu", "jlawler"]
  s.date = %q{2010-06-25}
  s.description = %q{A small pure ruby avahi library using ruby-dbus.}
  s.email = %q{jeremylawler@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
     "Rakefile",
     "VERSION",
     "examples/callback_test.rb",
     "examples/publish_test.rb",
     "lib/avahi.rb",
     "lib/avahi/callback.rb",
     "lib/avahi/constants.rb",
     "lib/avahi/manager.rb",
     "lib/avahi/service.rb",
     "lib/avahi/service_list.rb",
     "ruby-avahi.gemspec"
  ]
  s.homepage = %q{http://github.com/jlawler/ruby-avahi}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{pure ruby avahi library}
  s.test_files = [
    "examples/publish_test.rb",
     "examples/callback_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

