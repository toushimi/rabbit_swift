require 'net/http'
require 'uri'
require 'json'
require 'httpclient'
require 'pathname'
require 'mime/types'
require 'digest/md5'

module RabbitSwift

  class Client

    HEAD_SUCCESS_HTTP_STATUS_CODE = 200
    UPLOAD_SUCCESS_HTTP_STATUS_CODE = 201
    DELETE_SUCCESS_HTTP_STATUS_CODE = 204

    @token = nil

    def initialize(opt)
      @auth_url = opt['auth_url']
      @tenantName = opt['tenantName']
      @tenantId = opt['tenantId']
      @username = opt['username']
      @password = opt['password']
      @send_timeout = opt['send_timeout'];
      @web_mode = opt['web_mode'];
      @web_file_listing = opt['web_file_listing'];
      @delete_at = opt['delete_at']
      @delete_after = opt['delete_after']
      @meta_data_hash = opt['meta_data_hash']
    end

    #curl -i 'https://********.jp/v2.0/tokens' -X POST -H "Content-Type: application/json" -H "Accept: application/json"  -d '{"auth": {"tenantName": "1234567", "passwordCredentials": {"username": "1234567", "password": "************"}}}'
    def get_token
      return @token if !@token.nil?
      body =  build_auth_json

      http_client = HTTPClient.new

      p @auth_url
      p body
	
      response = http_client.post_content(@auth_url, body, 'Content-Type' => 'application/json')
      response_json_body = JSON.load(response)

      @token = response_json_body['access']['token']['id']
    end

    def head(token, url)
      auth_header = {
          'X-Auth-Token' => token
      }
      http_client = HTTPClient.new
      response = http_client.head(URI.parse(URI.encode(url)), nil, auth_header)
      header = {}
      if HEAD_SUCCESS_HTTP_STATUS_CODE !=  response.status
        raise 'ERROR HTTP_STATUS = ' + response.status
      end
      response.header.all.each do |header_list|
        header[header_list[0]] = header_list[1]
      end
      header
    end

    # TODO folder all save
    def get_object(token, url, dest_folder = nil)
      auth_header = {
          'X-Auth-Token' => token
      }
      query = nil
      dest_file = nil

      if dest_folder.nil?
        dest_file = File.join('./', File.basename(url))
      else
        dest_file = File.join(dest_folder, File.basename(url))
      end

      http_client = HTTPClient.new
      http_client.receive_timeout = 60 * 120

      open(dest_file, 'wb') do |file|
        
         http_client.get_content(URI.parse(URI.encode(url)), query, auth_header) do |chunk|
           file.write chunk
         end

      end
      dest_file
    end

    def get_meta_data(token, url)
      response = head(token, url)
      meta_data = {}
      response.each do |header_list|
        if (header_list[0] =~ /^X-Object-Meta/)
          meta_data[header_list[0].gsub('X-Object-Meta-', '')] = header_list[1]
        end
      end
      meta_data
    end

    def delete(token, url)
      auth_header = {
          'X-Auth-Token' => token
      }
      http_client = HTTPClient.new
      args = {:body => nil, :header => auth_header, :query => nil}
      response = http_client.delete(URI.parse(URI.encode(url)), args)
      header = {}
      response.header.all.each do |header_list|
        header[header_list[0]] = header_list[1]
      end
      p response
      header
    end

    # curl -i -X PUT -H "X-Auth-Token: トークン" オブジェクトストレージエンドポイント/コンテナ名/ -T オブジェクトへのパス
    def upload(token, end_point, input_file_path)
      #相対パスがきた時のために絶対パスに変換
      path_name_obj = Pathname.new(input_file_path);
      file_path = path_name_obj.expand_path.to_s
      mime = MIME::Types.type_for(file_path)[0]
      auth_header =
          if mime.nil?
            {'X-Auth-Token' => token}
          else
            {'X-Auth-Token' => token,
             'Content-Type' => MIME::Types.type_for(file_path)[0].to_s
            }
          end

      auth_header['X-Web-Mode'] = 'true' if @web_mode

      http_client = HTTPClient.new
      http_client.send_timeout = @send_timeout.to_i unless(@send_timeout.nil?)

      target_url = add_filename_to_url(end_point, file_path)

      puts 'upload_url -> ' + target_url

      if @delete_at
        auth_header['X-Delete-At'] = @delete_at
      end
      if @delete_after
        auth_header['X-Delete-After'] = @delete_after
      end
      if @meta_data_hash
        create_meta_data_header(auth_header, @meta_data_hash)
      end

      if File::ftype(file_path) == 'directory'
        auth_header['Content-Length'] = 0
        auth_header['Content-Type'] = 'application/directory'
        if @web_mode
          if @web_file_listing
           auth_header['X-Container-Read'] = '.r:*' + ',.rlistings'
           auth_header['X-Container-Meta-Web-Index'] = 'index.html'
          else
            auth_header['X-Container-Read'] = '.r:*'
          end
          #auth_header['X-Container-Meta-Web-Listings'] = 'true'
          #auth_header['X-Container-Meta-Web-Listings-CSS'] = 'listing.css'
        end
        p auth_header
        @res = http_client.put(URI.parse(URI.encode(target_url)), file_path, auth_header)
        if @res.status == UPLOAD_SUCCESS_HTTP_STATUS_CODE
          Dir::foreach(file_path) {|f|
            next if (f == '.' || f == '..')
            begin
              child_path = path_name_obj.join(f)
              # 再帰
              upload(token, add_filename_to_url(end_point, File::basename(file_path)), child_path)
            rescue => e
              puts e
            end
          }
        end
      else
        p auth_header

        if LargeObject::StaticLargeObject.is_over_default_limit_object_size(File.size(file_path))
          #Auto SLO Mode
          p File.size(file_path)
          puts '------ Over limit object size! change Static Large Object Mode. ------- '
          LargeObject::Slo_client.new(self, input_file_path, end_point).upload
        else
          File.open(file_path) do |file|
            @res = http_client.put(URI.parse(URI.encode(target_url)), file, auth_header)
          end
        end

      end

      #p @res
      @res.status
    end

    def upload_manifest(token, end_point, dest_container,input_file_path, manifest_json, original_file_md5sum)
      #相対パスがきた時のために絶対パスに変換
      path_name_obj = Pathname.new(input_file_path);
      file_path = path_name_obj.expand_path.to_s
      target_url = add_filename_to_url(end_point, file_path)

      manifest_path = File.join(dest_container, File.basename(input_file_path))
      p end_point
      p File.basename(input_file_path)
      p manifest_path
      manifest_path.sub!(/^./,'')
      p manifest_path
      auth_header =
            {'X-Auth-Token' => token,
            'X-Object-Manifest' => manifest_path+'_',
            'X-STATIC-LARGE-OBJECT' => true,
            'Content-Type' => 'application/json',
            LargeObject::StaticLargeObject::ORIGINAL_MD5SUM_META_NAME => original_file_md5sum
            }
      http_client = HTTPClient.new
      url = URI.parse(URI.encode(target_url + '?multipart-manifest=put'))
      p url
      p auth_header
      response = http_client.put(url, manifest_json, auth_header)
      p response
      p response.status
    end

    private

    def build_auth_json
      auth_json = {
          'auth' =>  {
              'passwordCredentials' =>  {
                  'username' => @username,
                  'password' =>  @password
              }
          }
      }
      auth_json['auth']['tenantName'] = @tenantName unless @tenantName.nil?
      auth_json['auth']['tenantId'] = @tenantId unless @tenantId.nil?
      JSON.dump(auth_json)
    end

    #URLにファイル名を付与
    def add_filename_to_url(url, file_path)
      filename = File::basename(file_path)

      decorate_url = nil

      if /\/$/ =~ url
        decorate_url = url + filename
      else
        decorate_url = url + '/' + filename
      end

      return decorate_url
    end

    def create_meta_data_header(auth_header, meta_data_hash)
      #X-Object-Meta-{name}
      meta_data_hash.each{|key, value|
        auth_header['X-Object-Meta-' + key] = value
      }
    end

  end

end
