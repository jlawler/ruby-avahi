Gem::Specification.new do |s|
  s.name = %q{ruby-avahi}
  s.version = "0.1.0"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["pangdudu"]
  s.date = %q{2009-07-31}
  s.description = %q{A small pure ruby avahi library using ruby-dbus.}
  s.email = %q{pangdudu@github}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc","lib/avahi.rb", "lib/avahi_constants.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/pangdudu/ruby-avahi}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{pure ruby avahi library}
  s.add_dependency(%q<pangdudu-ruby-dbus>, [">= 0"])
end
