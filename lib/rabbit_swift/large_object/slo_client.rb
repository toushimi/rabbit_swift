require 'rabbit_swift'
require 'digest/md5'

module RabbitSwift::LargeObject
  class Slo_client

    attr_accessor :rabbit_swift_client, :src_path, :dest_path, :original_dest_path, :slo_option, :original_file_md5sum

    def initialize(rabbit_swift_client, src_path, dest_path, slo_option = {})
      @rabbit_swift_client = rabbit_swift_client
      @src_path = src_path
      @dest_path = dest_path
      #TODO かなり無理があるので改修必要
      @original_dest_path = dest_path.sub(/https:\/\/.*\/v1\/.*\//, '/')


      @slo_option = slo_option
    end

    def upload
      original_file_md5sum = Digest::MD5.file(src_path).to_s
      if  @slo_option.has_key?('limit_file_size')
        slo = RabbitSwift::LargeObject::StaticLargeObject.new(src_path, dest_path, limit_file_size: @slo_option['limit_file_size'])
      else
        slo = RabbitSwift::LargeObject::StaticLargeObject.new(src_path, dest_path)
      end
      # (指定されたファイルサイズ単位で)ファイルを分割する
      rabbit_file_split = slo.split
      # JSONマニフェストファイルをつくる
      manifest_json = slo.create_manifest_list(rabbit_file_split.file_list)

      token = rabbit_swift_client.get_token

      #TODO with etag
      #ファイルを全てアップロード
      rabbit_file_split.file_list.each do |file_path|
        status = rabbit_swift_client.upload(token, dest_path, file_path)
        if (status == RabbitSwift::Client::UPLOAD_SUCCESS_HTTP_STATUS_CODE)
          ;
        else
          return
        end
      end

      #マニフェストをアップロード
      rabbit_swift_client.upload_manifest(token, dest_path, @original_dest_path, @src_path, manifest_json, original_file_md5sum)

      #分割したファイルを削除
      rabbit_file_split.delete_all

    end

  end



end