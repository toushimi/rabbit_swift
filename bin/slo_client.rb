require 'json'
require 'optparse'
require 'rabbit_swift'

#ruby -I./lib/ this.rb
#bundle exec ruby -I./lib bin/slo_client.rb -s ~/Downloads/test.zip -d /test -c ../chino/conf/conf.json -l 1048576
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
Version = "1.0.0"

src_path = nil
dest_path = nil
conf_path = nil
limit_file_size = nil
opt.on('-s SRC_PATH', 'src_file_path') {|v| src_path = v}
opt.on('-d DEST_PATH', 'dest_path') {|v| dest_path = v}
opt.on('-c CONF_PATH', 'conf_path') {|v| conf_path = v}
opt.on('-l LIMIT_BYTE', 'limit_file_size') {|v| limit_file_size = v}
opt.parse!(ARGV)


class Slo_client

  attr_accessor :src_path, :dest_path, :conf_path, :swift, :token, :limit_file_size, :original_dest_path

  def initialize(src_path, dest_path, conf_path, send_timeout: 7200, limit_file_size:  RabbitSwift::LargeObject::StaticLargeObject::LIMIT_FILE_SIZE)
    @src_path = src_path
    @dest_path = dest_path
    @original_dest_path = dest_path
    @conf_path = conf_path
    @limit_file_size = limit_file_size
    File.open conf_path do |file|
      conf = JSON.load(file.read)
      @swift = conf['swift']

      if @dest_path =~ /^\//
        @dest_path = @swift['endPoint'] + dest_path
      end
    end

    @swift['send_timeout'] = send_timeout
  end

  def upload
    slo = RabbitSwift::LargeObject::StaticLargeObject.new(src_path, dest_path, limit_file_size: @limit_file_size)

    # (指定されたファイルサイズ単位で)ファイルを分割する
    rabbit_file_split = slo.split
    # JSONマニフェストファイルをつくる
    manifest_json = slo.create_manifest_list(rabbit_file_split.file_list)
    puts manifest_json
    
    rabbit_swift_client = RabbitSwift::Client.new(@swift)
    @token = rabbit_swift_client.get_token
    puts 'token -> ' + token

    #ファイルを全てアップロード(with etag)
    rabbit_file_split.file_list.each do |file_path|
      status = rabbit_swift_client.upload(token, dest_path, file_path)
      puts file_path
      puts 'http_status -> ' + status.to_s
      if (status == RabbitSwift::Client::UPLOAD_SUCCESS_HTTP_STATUS_CODE)
        puts 'upload OK'
      else
        puts 'upload NG'
        return
      end
    end

    puts "dest_path->" + dest_path
    #マニフェストをアップロード
    rabbit_swift_client.upload_manifest(token, dest_path, @original_dest_path, @src_path, manifest_json)

    #分割したファイルを削除
    rabbit_file_split.delete_all

  end

end


slo = Slo_client.new(src_path,dest_path,conf_path, limit_file_size: limit_file_size)
slo.upload