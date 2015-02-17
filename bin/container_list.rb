require 'json'
require 'optparse'
require 'rabbit_swift'

#bundle exec ruby -I./lib bin/container_list.rb -l /test -c ../chino/conf/conf.json

opt = OptionParser.new
Version = '1.0.0'

conf_path = nil
url = nil
swift_conf_json = nil
opt.on('-c CONF_PATH', 'conf_path') {|v| conf_path = v}
opt.on('-l LIST_CONTAINER_TARGET', 'list container target') {|v| url = v}
opt.parse!(ARGV)
File.open conf_path do |file|
  conf = JSON.load(file.read)
  swift_conf_json = conf['swift']

  if url =~ /^\//
    url = swift_conf_json['endPoint'] + url
  end
end

rabbit_swift_client = RabbitSwift::Client.new(swift_conf_json)
token = rabbit_swift_client.get_token
response = rabbit_swift_client.list(token, url)

puts response