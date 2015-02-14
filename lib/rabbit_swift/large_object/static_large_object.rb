require 'digest/md5'
require 'rabbit_file_split'
require 'json'

module RabbitSwift::LargeObject
  class StaticLargeObject

    LIMIT_FILE_SIZE = 5368709120;

    # 参考　http://blog.bit-isle.jp/bird/2013/06/35
    # Swift Server SLO https://github.com/openstack/swift/blob/7a9a0e14b1c6a8f51454379beac95cd594a4193b/swift/common/middleware/slo.py
    # GNU Core Util split http://git.savannah.gnu.org/cgit/coreutils.git/tree/src/split.c

    @file_path = nil
    @split_file_path = nil
    @dest_container_path = nil
    @limit_file_size = nil

    def initialize(file_path, dest_container_path,  split_file_path: nil, limit_file_size: LIMIT_FILE_SIZE)
      @file_path = file_path
      @split_file_path = split_file_path
      @dest_container_path = dest_container_path
      @limit_file_size = limit_file_size.to_i
    end

    def split
      rabbit_file_split = RabbitFileSplit::Bytes.new(@file_path)
      #p @file_path
      #p @limit_file_size
      rabbit_file_split.split(@limit_file_size)
      rabbit_file_split
    end

    def create_manifest_list(file_path_list)
      manifest = file_path_list.map{|file_path|
        md5 = Digest::MD5.file(file_path).to_s
        {path:  File.join(@dest_container_path, File.basename(file_path)), etag: md5, size_bytes: File.size(file_path)}
      }
      JSON.generate(manifest)
    end

    def self.is_over_default_limit_object_size(file_size)
      LIMIT_FILE_SIZE > file_size
    end

  end
end