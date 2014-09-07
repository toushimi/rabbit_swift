# RabbitSwift

OpenStack Swift Simple Client

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rabbit_swift'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rabbit_swift

## Usage

### Set server information

```ruby
   swift_conf = {
     auth_url: "https://ident-r1nd9999.cnode.jp/v2.0/tokens",
     tenantName: "1234567",
     username: "chino",
     password: "password"
    }
```

### Get token

    rabbit_swift_client = RabbitSwift::Client.new(swift_conf);
    token = rabbit_swift_client.get_token

### Upload File or Folder

    //dest_url = ex) https://objectstore-r1nd1111.cnode.jp/v1/XXXXXXXXXXX/container_name
    status = rabbit_swift_client.upload(token, dest_url, src_file_path)

### Check Result
    if (status == RabbitSwift::Client::UPLOAD_SUCCESS_HTTP_STATUS_CODE) 
        puts "upload success!"
    end 
    

## Contributing

1. Fork it ( https://github.com/AKB428/rabbit_swift/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
