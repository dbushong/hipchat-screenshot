#!/usr/bin/env ruby

require 'optparse'
require 'tempfile'
require 'hipchat'
require 'rbconfig'
require 'yaml'
require 'open3'

def die(msg)
  $stderr.puts "#{Prog}: #{msg}"
  exit 1
end

Prog = File.basename($0)
opts = OptionParser.new
opts.banner = "usage: #{Prog} [options]"
opts.on_tail('-h', '--help', 'Show this message') { puts opts ; exit 1 }
begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => e
  die "#{e}\n#{opts}"
end

conf_file = File.join ENV['HOME'], '.hipchat-screenshot.yml'

unless File.exists?(conf_file)
  skeleton = {
    'api_token' => 'FIXME',
    'rooms' => { 'FIXME Room Name' => 123456, 'FIXME Another' => 789012 },
    'username' => 'FIXME: Your HipChat username'
  }
  File.open(conf_file, 'w') {|f| f.write skeleton.to_yaml }
  File.chmod(0600, conf_file)
  die "skeleton #{conf_file} created; edit then re-run"
end

conf = YAML.load_file(conf_file)

die "you need to EDIT #{conf_file} first" if conf['api_token'] == 'FIXME'

# right now we assume mac or gnomeish desktop w/ zenity
mac = !!(RbConfig::CONFIG['host_os'] =~ /darwin|mac os/)

png = if (save_dir = conf['save_dir'])
  die "no such directory #{save_dir}" unless Dir.exists? save_dir
  File.join save_dir, Time.now.strftime('hcss-%Y-%m-%d-%H-%M-%S.png')
else
  tmp = Tempfile.new([Prog, '.png'])
  tmp.close
  tmp.path
end

room_name = room_id = nil

def_room_name   = conf['rooms'].first.first
single_question = "Upload screenshot to #{def_room_name}?"
multi_prompt    = 'Upload screenshot to which room?'

def run(*cmd)
  out, st = Open3.capture2e(*cmd)
  out.chomp!
  die(out) unless st == 0
  out
end

room_name = if mac
  run 'screencapture', '-i', png

  oscript = if conf['rooms'].size > 1 
    <<-EOF
      tell application "System Events"
        activate
        set room to choose from list {#{conf['rooms'].keys.map{|k| %{"#{k}"}}.join(',')}} with prompt "#{multi_prompt}" with title "HipChat Screenshot" default items {"#{def_room_name}"}
      end tell
    EOF
  else
    <<-EOF
      tell application "System Events"
        activate
        set question to display dialog "#{single_question}" with title "HipChat Screenshot" buttons {"Cancel", "OK"} cancel button "Cancel" default button "OK"
      end tell
    EOF
  end

  # osascript seems to always exit with non-zero status (!?)
  out, = Open3.capture2e('osascript', stdin_data: oscript)
  out.chomp!
  out == 'button returned:OK' ? def_room_name : out
else
  # FIXME: should use something like this to determine if you have zenity
  # available: https://github.com/vertiginous/pik/blob/master/lib/pik/which.rb
  raise 'requires zenity' unless File.exists? '/usr/bin/zenity'

  run 'gnome-screenshot', '--area', '--file', png

  if conf['rooms'].size > 1
    out, = Open3.capture2e('zenity', '--list', "--title=#{multi_prompt}",
                           '--column', 'Room Name', *conf['rooms'].keys)
    out.gsub(/\|.*|\n/, '')
  else
    system('zenity', '--question', '--text', single_question) && def_room_name
  end
end

room_id = conf['rooms'][room_name]
exit(1) unless room_id

client = HipChat::Client.new(conf['api_token'], api_version: 'v2')
client[room_id].send_file(conf['username'], '', File.open(png))
