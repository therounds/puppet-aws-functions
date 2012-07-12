#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'fog'
require 'yaml'

@elbs = Fog::AWS::ELB.new(:region => 'us-east-1')

elb = @elbs.load_balancers

@elbs.load_balancers.each { |balancer| print balancer.attributes[:dns_name] + "\n" }


