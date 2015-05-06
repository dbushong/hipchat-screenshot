#!/usr/bin/env ruby

require 'optparse'
require 'tempfile'
require 'hipchat'
require 'rbconfig'
require 'yaml'

prog = File.basename($0)
opts = OptionParser.new
opts.banner = "usage: #{prog} [options]"
opts.on_tail('-h', '--help', 'Show this message') { puts opts ; exit 1 }
begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => e
  $stderr.puts "#{prog}: #{e}\n#{opts}"
  exit 1
end

conf_file = "#{ENV['HOME']}/.hipchat-screenshot.yml"

unless File.exists?(conf_file)
  skeleton = {
    'api_token' => 'FIXME',
    'rooms' => { 'FIXME Room Name' => 123456, 'FIXME Another' => 789012 },
    'username' => 'FIXME: Your HipChat username',
  }
  File.open(conf_file, 'w') {|f| f.write skeleton.to_yaml }
  $stderr.puts "Skeleton #{conf_file} created; edit then re-run"
  exit(1)
end

conf = YAML.load_file(conf_file)

if conf['api_token'] == 'FIXME'
  $stderr.puts "You need to EDIT #{conf_file} first"
  exit(1)
end

mac  = !!(RbConfig::CONFIG['host_os'] =~ /darwin|mac os/)

png = Tempfile.new([prog, '.png'])
png.close
message = "Screenshot from #{ENV['USER']} at #{Time.now}"
room_name = room_id = nil

if mac
  require 'shellwords'
  require 'open3'

  system("screencapture -i #{png.path.shellescape} 2>/dev/null") || exit(1)

  def_room_name = conf['rooms'].first.first

  oscript = if conf['rooms'].size > 1 
    <<-EOF
      tell application "System Events"
        activate
        set room to choose from list {#{conf['rooms'].keys.map{|k| %{"#{k}"}}.join(',')}} with prompt "Upload screenshot to which room?" with title "HipChat Screenshot" default items {"#{def_room_name}"}
      end tell
    EOF
  else
    <<-EOF
      tell application "System Events"
        activate
        set question to display dialog "Upload screenshot to #{def_room_name}?" with title "HipChat Screenshot" buttons {"Cancel", "OK"} cancel button "Cancel" default button "OK"
      end tell
    EOF
  end

  out, = Open3.capture2e('osascript', stdin_data: oscript)
  out.chomp!
  room_name = out == 'button returned:OK' ? def_room_name : out
  room_id = conf['rooms'][room_name]

  exit(1) unless room_id
else
  system('gnome-screenshot', '--area', '--file', png.path) || exit(1)

  raise 'room selector for zenity not ready yet'

  # FIXME: should use something like this to determine if you have a prompter
  # available: https://github.com/vertiginous/pik/blob/master/lib/pik/which.rb
  if File.exists? '/usr/bin/zenity'
    system('zenity', '--question', '--text', 'Post screenshot?') || exit(1)
  end
end

client = HipChat::Client.new(conf['api_token'], api_version: 'v2')
client[room_id].send_file(conf['username'], '', File.open(png.path))
