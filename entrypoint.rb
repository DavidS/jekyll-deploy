#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

def system_or_fail(*cmd)
  puts "executing #{cmd.inspect}"
  exit $CHILD_STATUS unless system(*cmd)
end

system_or_fail('bundle', 'config', 'set', 'path', 'vendor/gems')
system_or_fail('bundle', 'config', 'set', 'deployment', 'true')
system_or_fail('bundle', 'install', '--jobs=4', '--retry=3')

if ENV['INPUT_BUILD-ONLY'] == "true"
  system_or_fail('bundle', 'exec', 'jekyll', 'build', '--future', '--verbose', '--trace')
  exit
else
  system_or_fail('bundle', 'exec', 'jekyll', 'build', '--verbose', '--trace')
end

Dir.chdir('_site')
File.open('.nojekyll', 'w') { |f| f.puts 'Skip Jekyll' }

system_or_fail('git', 'init', '.')
FileUtils.cp('../.git/config', '.git/config')
system_or_fail('git', 'config', 'user.name', ENV['GITHUB_ACTOR'])
system_or_fail('git', 'config', 'user.email', "#{ENV['GITHUB_ACTOR']}@users.noreply.github.com")
system_or_fail('git', 'fetch', '--no-tags', '--no-recurse-submodules', '--depth=1', 'origin', '+gh-pages:refs/remotes/origin/gh-pages')
system_or_fail('git', 'reset', '--soft', 'origin/gh-pages')
system_or_fail('git', 'add', '-A', '.')
system_or_fail('git', 'commit', '-m', 'Update github pages')
system_or_fail('git', 'push', 'origin', 'HEAD:gh-pages')

puts "triggering a github pages deploy"

require 'net/http'
result = Net::HTTP.post(
  URI("https://api.github.com/repos/#{ENV['GITHUB_REPOSITORY']}/pages/builds"),
  "",
  "Content-Type" => "application/json",
  "Authorization" => "token #{ENV['GH_PAGES_TOKEN']}",
)

puts result.body
