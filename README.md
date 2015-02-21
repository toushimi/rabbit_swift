# RabbitSwift

OpenStack Object Storage (Swift) Client

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

```
   swift_conf = {
     auth_url: "https://ident-r1nd9999.cnode.jp/v2.0/tokens",
     tenantName: "1234567",
     username: "chino",
     password: "password",
     endPoint: "https://objectstore.node.jp/v1/77777777"
    }
```

### Get token

    rabbit_swift_client = RabbitSwift::Client.new(swift_conf);
    token = rabbit_swift_client.get_token

### Upload File or Folder

    dest_url = "https://objectstore-r1nd1111.cnode.jp/v1/XXXXXXXXXXX/container_name"
    status = rabbit_swift_client.upload(token, dest_url, src_file_path)

#### Check Result
    if (status == RabbitSwift::Client::UPLOAD_SUCCESS_HTTP_STATUS_CODE) 
        puts "upload success!"
    end

### Get Object
    rabbit_swift_client.get_object(token, url) #save current directory
    rabbit_swift_client.get_object(token, url, dest_path)

### Support Static Large Object

#### SLO Object Download Support
    rabbit_swift_client.get_object(token, slo_manifest_url) --> enable SLO object download

#### When upload object size 5GB over. Auto change mode SLO
    rabbit_swift_client.upload(token, dest_url, 5GB_under_file.zip) --> normal upload
    rabbit_swift_client.upload(token, dest_url, 5GB_over_file.zip) --> static large object upload

#### SLO Upload Flow
1. split file
2. upload split files
3. create manifest json (to memory)
4. upload manifest file
5. delete split file

### bin utils

#### List Container
    bundle exec ruby -I./lib bin/container_list.rb -l /test -c ../chino/conf/conf.json

#### Get Object Client

    bundle exec ruby -I./lib bin/get_object.rb -t /test/file.jpg -c ../chino/conf/conf.json
    bundle exec ruby -I./lib bin/get_object.rb -t /test/file.jpg -d ./save_folder/ -c ../chino/conf/conf.json

#### SLO Upload Client
    bundle exec ruby -I./lib bin/slo_client.rb -s ~/Downloads/test.zip -d /test -c ../chino/conf/conf.json -l 100MB



## Contributing

1. Fork it ( https://github.com/AKB428/rabbit_swift/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
