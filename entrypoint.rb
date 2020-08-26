#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

def system_or_fail(*cmd)
  puts "executing #{cmd.inspect}"
  unless system(*cmd)
    puts "execution failed with #{$CHILD_STATUS}"
    exit $CHILD_STATUS
  else
    puts "executed #{cmd.inspect} successfully"
  end
end

basedir = Dir.pwd
Dir.chdir(ENV['INPUT_SOURCE-DIR'])
sourcedir = Dir.pwd

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
FileUtils.cp(File.join(basedir, '/.git/config'), '.git/config')
system_or_fail('git', 'config', 'user.name', ENV['GITHUB_ACTOR'])
system_or_fail('git', 'config', 'user.email', "#{ENV['GITHUB_ACTOR']}@users.noreply.github.com")
system_or_fail('git', 'fetch', '--no-tags', '--no-recurse-submodules', 'origin', "+#{ENV['GITHUB_SHA']}:refs/remotes/origin/source")
if %x(git ls-remote --heads origin) =~ %r{\trefs/heads/#{ENV['INPUT_TARGET-BRANCH']}\n}
  puts "Found target branch '#{ENV['INPUT_TARGET-BRANCH']}', using that as base"
  system_or_fail('git', 'fetch', '--no-tags', '--no-recurse-submodules', 'origin', "+#{ENV['INPUT_TARGET-BRANCH']}:refs/remotes/origin/#{ENV['INPUT_TARGET-BRANCH']}")
  system_or_fail('git', 'reset', '--soft', "origin/#{ENV['INPUT_TARGET-BRANCH']}")
else
  puts "Didn't find target branch '#{ENV['INPUT_TARGET-BRANCH']}', using the source as a base"
  system_or_fail('git', 'reset', '--soft', "origin/source")
end

if File.exist?(File.join(sourcedir, 'CNAME')) && !File.exist?('CNAME')
  puts "Rendering github's CNAME file"
  FileUtils.cp(File.join(sourcedir, 'CNAME'), 'CNAME')
end

system_or_fail('git', 'add', '-A', '.')
system_or_fail('git', 'commit', '-m', 'Update github pages')
system_or_fail('git', 'merge', '-s', 'ours', 'origin/source')
system_or_fail('git', 'push', 'origin', "HEAD:#{ENV['INPUT_TARGET-BRANCH']}")

puts "triggering a github pages deploy"

require 'net/http'
result = Net::HTTP.post(
  URI("https://api.github.com/repos/#{ENV['GITHUB_REPOSITORY']}/pages/builds"),
  "",
  "Content-Type" => "application/json",
  "Authorization" => "token #{ENV['GH_PAGES_TOKEN']}",
)

puts result.body
