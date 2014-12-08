require 'rubygems'
require 'fog'

module Puppet::Parser::Functions
  newfunction(:s3_get_etag, :type => :rvalue, :doc => <<-EOS
    Returns the md5 hash of the s3 object specified by the bucket and key.
    Note: This will not work if the object was uploaded with Multipart.
    EOS
             ) do |args|
    bucket   = args[0]
    key      = args[1]
    Fog.credentials_path = '/etc/puppet/fog_cred'
    s3 = Fog::Storage.new(:provider => 'AWS')
    s3bucket = s3.directories.get(bucket)
    if s3bucket.files.head(key).nil? then
      raise Puppet::ParseError, "s3 object does not exist: #{key}"
    end
    etag = s3bucket.files.head(key).etag
    if etag.match(/-/) then
      raise Puppet::ParseError, "md5 etag is broken, Don't upload with Multipart."
    end
    return etag
  end
end
