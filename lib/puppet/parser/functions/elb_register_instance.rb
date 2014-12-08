require 'rubygems'
require 'fog'

module Puppet::Parser::Functions
  newfunction(:elb_register_instance, :doc => <<-EOS
    Registers the instance with the named balancer.
    Note that you still need to add the appropriate
    Zone to the balancer before this works.
    EOS
             ) do |args|

    params = {}

    params[:elb] = args[0]
    params[:instanceid] = lookupvar('ec2_instance_id')
    params[:region] = lookupvar('ec2_placement_availability_zone').chop

    Fog.credentials_path = '/etc/puppet/fog_cred'

    @elbs = Fog::AWS::ELB.new(:region => params[:region])

    @elb = @elbs.load_balancers.get(params[:elb])

    #check to see if the instance is registered
    if ! @elb.attributes[:instances].include?(params[:instanceid])
      #if not, register it
      @elb.register_instances(params[:instanceid])
    end
  end
end



