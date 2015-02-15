require 'json'
require 'optparse'
require 'rabbit_swift'

#ruby -I./lib/ this.rb
#bundle exec ruby -I./lib bin/slo_client.rb -s ~/Downloads/test.zip -d /test -c ../chino/conf/conf.json -l 1048576
#bundle exec ruby -I./lib bin/slo_client.rb -s ~/Downloads/test.zip -d /test -c ../chino/conf/conf.json -l 100MB


=begin
-c conf.json
{
 "swift" : {
        "auth_url" : "",　//必須
        "tenantName" : "", //必須
        "username" : "", //必須
        "password" : "", //必須
        "endPoint" : "" //必須ではない、末尾に/はつけない
 }
}
=end

opt = OptionParser.new
Version = '1.0.0'

src_path = nil
dest_path = nil
conf_path = nil
slo_option = {}
swift_conf_json = {}
opt.on('-s SRC_PATH', 'src_file_path') {|v| src_path = v}
opt.on('-d DEST_PATH', 'dest_path') {|v| dest_path = v}
opt.on('-c CONF_PATH', 'conf_path') {|v| conf_path = v}
opt.on('-l LIMIT_BYTE', 'limit_file_size') {|v| slo_option['limit_file_size'] = v}
opt.parse!(ARGV)


File.open conf_path do |file|
  conf = JSON.load(file.read)
  swift_conf_json = conf['swift']

  if dest_path =~ /^\//
    dest_path = swift_conf_json['endPoint'] + dest_path
  end
end

rabbit_swift_client = RabbitSwift::Client.new(swift_conf_json)

LargeObject::Slo_client.new(rabbit_swift_client, src_path, dest_path, slo_option).upload