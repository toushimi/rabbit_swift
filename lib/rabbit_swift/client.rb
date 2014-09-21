require 'net/http'
require 'uri'
require 'json'
require 'httpclient'
require 'pathname'
require 'mime/types'

module RabbitSwift

  class Client

    UPLOAD_SUCCESS_HTTP_STATUS_CODE = 201

    def initialize(opt)
      @auth_url = opt['auth_url']
      @tenantName = opt['tenantName']
      @username = opt['username']
      @password = opt['password']
      @send_timeout = opt['send_timeout'];
      @web_mode = opt['web_mode'];
    end

    #curl -i 'https://********.jp/v2.0/tokens' -X POST -H "Content-Type: application/json" -H "Accept: application/json"  -d '{"auth": {"tenantName": "1234567", "passwordCredentials": {"username": "1234567", "password": "************"}}}'
    def get_token
      body =  build_auth_json

      http_client = HTTPClient.new
	
      response = http_client.post_content(@auth_url, body, 'Content-Type' => 'application/json')
      response_json_body = JSON.load(response)

      response_json_body['access']['token']['id']
    end

    # curl -i -X PUT -H "X-Auth-Token: トークン" オブジェクトストレージエンドポイント/コンテナ名/ -T オブジェクトへのパス
    def upload(token, end_point, input_file_path)
      #相対パスがきた時のために絶対パスに変換
      path_name_obj = Pathname.new(input_file_path);
      file_path = path_name_obj.expand_path.to_s
      auth_header = {
          'X-Auth-Token' => token,
          'Content-Type' => MIME::Types.type_for(file_path)[0].to_s
      }
      auth_header['X-Web-Mode'] = 'true' if @web_mode

      http_client = HTTPClient.new
      http_client.send_timeout = @send_timeout.to_i unless(@send_timeout.nil?)

      target_url = add_filename_to_url(end_point, file_path)

      puts 'upload_url -> ' + target_url

      if File::ftype(file_path) == 'directory'
        auth_header['Content-Length'] = 0
        auth_header['Content-Type'] = 'application/directory'
        if @web_mode 
          auth_header['X-Container-Read'] = '.r:*' + ',.rlistings'
          auth_header['X-Container-Meta-Web-Index'] = 'index.html'
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
        File.open(file_path) do |file|
          @res = http_client.put(URI.parse(URI.encode(target_url)), file, auth_header)
        end
      end

      #p @res
      @res.status
    end

    private

    def build_auth_json
      auth_json = {
          auth: {
              tenantName: @tenantName,
              passwordCredentials: {
                  username: @username,
                  password: @password
              }
          }
      }
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

  end

end
