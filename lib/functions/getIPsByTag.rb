require 'rubygems'
require 'fog'

module Puppet::Parser::Functions
  newfunction(:getIPsByTag, :type => :rvalue, :doc => <<-EOS
    Returns a hash of instance-id => private-ip pairs for a given
    ec2 tag key, value or kv pair.
    EOS
             ) do |args|
    filter = { 'key' => args[0] }
    filter = { 'value' => args[1] }
    instances  = {}
    region = lookupvar('ec2_placement_availability_zone').chop

    Fog.credentials_path = '/etc/puppet/fog_cred'

    # new compute provider from AWS
    compute = Fog::Compute.new(:provider => 'AWS', :region => region)

    # print resource id's by the hash {key => value}
    compute.describe_tags(filter).body['tagSet'].each do|tag|
      instance_facts = compute.describe_instances('instance-id' => tag['resourceId']).body['reservationSet'][0]['instancesSet'][0]
      instances[tag['resourceId']] = instance_facts['privateIpAddress']
    end

    #An empty result causes a parse error, for safety sake
    raise Puppet::ParseError, "Result is empty for key:" + filter['key'] +
      " value: " + filter['value'] if instances.empty?

    return instances

  end
end
