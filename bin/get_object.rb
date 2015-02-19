require 'json'
require 'optparse'
require 'rabbit_swift'
require 'digest/md5'

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

def decode_large_object_md5(encode_md5)
  encode_md5.gsub(/\"/,'')
end

rabbit_swift_client = RabbitSwift::Client.new(swift_conf_json)
token = rabbit_swift_client.get_token
response = rabbit_swift_client.head(token, url)

is_large_object = response.has_key?('X-Static-Large-Object') ? true : false

response.each do |k, v|
  puts k + ' = '+ v
end

original_file_md5 = is_large_object ? decode_large_object_md5(response['Etag']) : response['Etag']

save_file_path = rabbit_swift_client.get_object(token, url, dest_path)
puts save_file_path
save_file_md5 = Digest::MD5.file(save_file_path).to_s

puts original_file_md5 + ' --> original_file_md5'
puts save_file_md5 + ' --> save_file_md5'

if original_file_md5 == save_file_md5
  puts 'OK! MD5 checksum'
else
  puts 'BAD MD5 checksum  ><'
end

