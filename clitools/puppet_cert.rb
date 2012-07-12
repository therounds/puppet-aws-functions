#!/usr/bin/env ruby
#
# Utility to manage puppet client certificates via the REST api
#
#       Requirements:
#               A valid puppet cert/key pair with the CA of the master
#                       in ./puppetcred/puppet.{key,crt} and ca_cert.pem
#               Access to the puppetmaster REST endpoint port 8140
#
#


require 'rubygems'
require 'optparse'
require 'json'
require 'yaml'
require 'rest_client'

options = {}

usage = "Usage: puppet-cert.rb -a ACTION -c CERTNAME -e ENVIRONMENT"

optparse = OptionParser.new do|opts|
        opts.banner = usage

        opts.on( '-v', '--verbose', 'Output more information' ) do
                RestClient.log = 'stdout'
        end

        options[:output] = 'yaml'
        opts.on( '-o', '--output FORMAT', 'Output Format' ) do|format|
                options[:output] = format
        end

        opts.on( '-h', '--help', 'Display this screen' ) do
                puts opts
                exit
        end
        options[:action] = nil
        opts.on( '-a', '--action ACTION', 'status|revoke|delete|sign|waitandsign' ) do|action|
                options[:action] = action
        end

        options[:certname] = nil
        opts.on( '-c', '--certname NAME', 'Query cert NAME' ) do|cert|
                options[:certname] = cert
        end

        options[:env] = 'development'
        opts.on( '-e', '--environment ENV', 'Puppet Environment (development)' ) do|env|
                options[:env] = env
        end


end

optparse.parse!

abort(usage) if ! options[:certname]
abort(usage) if ! options[:action]

rest_path  = nil
method = nil
put_body = {}
case options[:action]
when "status"
        rest_path = "certificate_status"
        method = 'get'
when "sign"
        rest_path = "certificate_status"
        method = 'put'
        put_body[:desired_state] = 'signed'
        options[:output] = 'plain'
when "waitandsign"
        rest_path = "certificate_status"
        method = 'waitandsign'
        put_body[:desired_state] = 'signed'
        options[:output] = 'plain'
when "delete"
        rest_path = "certificate_status"
        method = 'delete'
        options[:output] = 'plain'
when "revoke"
        rest_path = "certificate_status"
        method = 'put'
        put_body[:desired_state] = 'revoked'
        options[:output] = 'plain'
else
        abort(usage)
end

cert_request = RestClient::Resource.new("https://puppet.janrain.com:8140/#{options[:env]}/#{rest_path}/#{options[:certname]}",
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("#{ENV['HOME']}/.puppetcred/puppet.crt")),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("#{ENV['HOME']}/.puppetcred/puppet.key")),
        :ssl_ca_file      =>  "#{ENV['HOME']}/.puppetcred/ca_crt.pem",
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
)

case method
when 'get'
        begin
                response = cert_request.get :accept => 'pson'
        rescue => e
                if e.http_code == 404
                        puts "No such Certificate"
                        exit
                else
                        puts e.to_yaml
                end
        end

when 'delete'
        begin
                response = cert_request.delete :accept => 'pson'
        rescue => e
                puts e.to_yaml
                exit
        end

when 'put'
        begin
                response = cert_request.put put_body.to_json, :accept => 'pson', :content_type => 'text/pson'
        rescue => e
                puts e.to_yaml
                exit
        end
when 'waitandsign'
        puts "Waiting for request"
        begin
                response = cert_request.get :accept => 'pson'
        rescue => e
                if e.http_code == 404
                        sleep 10
                        puts '.'
                        retry
                else
                        puts e.to_yaml
                        exit
                end
        end
        #request must exist, lets sign it
        begin
                response = cert_request.put put_body.to_json, :accept => 'pson', :content_type => 'text/pson'
        rescue => e
                 puts e.to_yaml
                 exit
        end
end

case options[:output]
when 'yaml'
        puts JSON.parse(response).to_yaml
when 'json'
        puts response.to_json
when 'plain'
        puts response
end
