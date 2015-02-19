require 'json'
require 'optparse'
require 'rabbit_swift'

#bundle exec ruby -I./lib bin/get_object.rb -t /test/file.jpg -c ../chino/conf/conf.json
#bundle exec ruby -I./lib bin/get_object.rb -t /test/file.jpg -d ./save_folder/ -c ../chino/conf/conf.json


opt = OptionParser.new
Version = '1.0.0'

conf_path = nil
dest_path = nil
url = nil
swift_conf_json = nil
opt.on('-c CONF_PATH', 'conf_path') {|v| conf_path = v}
opt.on('-d DEST_PATH', 'dest_path') {|v| dest_path = v}
opt.on('-t TARGET_OBJECT', 'target object') {|v| url = v}
opt.parse!(ARGV)
File.open conf_path do |file|
  conf = JSON.load(file.read)
  swift_conf_json = conf['swift']

  if url =~ /^\//
    url = File.join(swift_conf_json['endPoint'] , url)
  end
end

rabbit_swift_client = RabbitSwift::Client.new(swift_conf_json)
token = rabbit_swift_client.get_token
response = rabbit_swift_client.head(token, url)
p response
response = rabbit_swift_client.get_object(token, url, dest_path)
p response