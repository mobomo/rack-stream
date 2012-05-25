guard 'bundler' do
  watch 'Gemfile'
  watch 'rack-stream.gemspec'
end

guard 'rspec', :version => 2, :cli => '--pattern=spec/lib/**/*_spec.rb' do
  watch(%r{^spec/lib/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

