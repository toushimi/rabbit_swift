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

# TODO
def decode_large_object_md5(encode_md5)
  encode_md5.gsub(/\"/,'')
end

rabbit_swift_client = RabbitSwift::Client.new(swift_conf_json)
token = rabbit_swift_client.get_token
response = rabbit_swift_client.head(token, url)

is_large_object = response.has_key?('X-Static-Large-Object') ? true : false
original_file_size = response['Content-Length']

response.each do |k, v|
  puts k + ' = '+ v
end

original_file_md5 = response['Etag']
if is_large_object && response.has_key?(RabbitSwift::LargeObject::StaticLargeObject::ORIGINAL_MD5SUM_META_NAME)
  original_file_md5 = response[RabbitSwift::LargeObject::StaticLargeObject::ORIGINAL_MD5SUM_META_NAME]
end

save_file_path = rabbit_swift_client.get_object(token, url, dest_path)
puts save_file_path

#ref SLO md5 https://github.com/openstack/python-swiftclient/blob/06c73c6020e5af873e3ce245a27035da3448de7b/swiftclient/service.py#L330
# self._expected_etag: ヘッダーのEtag
# 保存したファイルのmd5 self._actual_md5

save_file_size = File.size(save_file_path)
puts original_file_size + ' --> original_file_size'
puts save_file_size.to_s + ' --> save_file_size'

if original_file_size.to_i == save_file_size
  puts 'OK! file size'
else
  puts 'BAD file size  ><'
end


#when SLO don't check md5.
if (!is_large_object || response.has_key?(RabbitSwift::LargeObject::StaticLargeObject::ORIGINAL_MD5SUM_META_NAME))
  save_file_md5 = Digest::MD5.file(save_file_path).to_s
  puts original_file_md5 + ' --> original_file_md5'
  puts save_file_md5 + ' --> save_file_md5'

  if original_file_md5 == save_file_md5
    puts 'OK! MD5 checksum'
  else
    puts 'BAD MD5 checksum  ><'
  end
end

