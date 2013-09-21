######################################################################
#  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
#  All rights reserved.
#  
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

######################################################################
# == Synopsis
#
#   Uses the aws-sdk gem to communicate with AWS
#
# == Usage
#
#  ruby aws.rb xxxxxxxxxxxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx us-east-1 EC2 launch_server "{\"instance_type\":\"t1.micro\"}"
#  ruby aws.rb access_key secret_key us-east-1 EC2 launch_worker "{\"instance_type\":\"t1.micro\"}"
#
#  ARGV[0] - Access Key
#  ARGV[1] - Secret Key
#  ARGV[2] - Region
#  ARGV[3] - Service (e.g. "EC2" or "CloudWatch")
#  ARGV[4] - Command (e.g. "launch_server")
#  ARGV[5] - Optional json with parameters associated with command
#
######################################################################

require 'aws'
require 'json'
require 'net/http'
require 'net/scp'
require 'net/ssh'
require 'tempfile'

# Not sure how we want to deal with this, but in the tag, I would like to specify the right
# version of openstudio so that in the AWS Management Console it is meaningful.
OPENSTUDIO_VERSION="1.0.5"

def error(code, msg)
  puts ({:error => {:code => code, :message => msg}}.to_json)
  exit(1)
end

if ARGV.length < 4
  error(-1, 'Invalid number of args')
end

if ARGV[0].empty? && ARGV[1].empty?
  error(401, 'AuthFailure')
end

AWS.config(
    :access_key_id => ARGV[0],
    :secret_access_key => ARGV[1],
    :region => ARGV[2],
    :ssl_verify_peer => false
)
@server_image_id = 'ami-155e147c'
@worker_image_id = 'ami-c1450fa8'

if ARGV[3] == "EC2"
  @aws = AWS::EC2.new
elsif ARGV[3] == "CloudWatch"
  @aws = AWS::CloudWatch.new
else
  error(-1, "Unrecognized AWS service: #{ARGV[3]}")
end

if ARGV.length == 6
  @params = JSON.parse(ARGV[5])
end

def create_struct(instance, procs)
  instance_struct = Struct.new(:instance, :id, :ip, :dns, :procs)
  return instance_struct.new(instance, instance.instance_id, instance.ip_address, instance.dns_name, procs)
end

def launch_server
  user_data = File.read(File.expand_path(File.dirname(__FILE__))+'/server_script.sh')
  @server = @aws.instances.create(:image_id => @server_image_id,
                                  :key_pair => @key_pair,
                                  :security_groups => @group,
                                  :user_data => user_data,
                                  :instance_type => @server_instance_type)
  @server.add_tag("Name", :value => "OpenStudio-Server V#{OPENSTUDIO_VERSION}")
  sleep 5 while @server.status == :pending
  if @server.status != :running
    error(-1, "Server status: #{@server.status}")
  end


  processors = send_command(@server.ip_address, 'nproc | tr -d "\n"')
  processors = 0 if processors.nil?  # sometimes this returns nothing, so put in a default
  @server = create_struct(@server, processors)
end

def launch_workers(num, server_ip)
  user_data = File.read(File.expand_path(File.dirname(__FILE__))+'/worker_script.sh.template')
  user_data.gsub!(/SERVER_IP/, server_ip)
  user_data.gsub!(/SERVER_HOSTNAME/, 'MASTER')
  user_data.gsub!(/SERVER_ALIAS/, "")

  instances = []
  num.times do
    worker = @aws.instances.create(:image_id => @worker_image_id,
                                   :key_pair => @key_pair,
                                   :security_groups => @group,
                                   :user_data => user_data,
                                   :instance_type => @worker_instance_type)
    @server.add_tag("Name", :value => "OpenStudio-Worker V#{OPENSTUDIO_VERSION}")
    instances.push(worker)
  end
  sleep 5 while instances.any? { |instance| instance.status == :pending }
  if instances.any? { |instance| instance.status != :running }
    error(-1, "Worker status: Not running")
  end

  # todo: fix this - sometimes returns nil
  processors = send_command(instances[0].ip_address, 'nproc | tr -d "\n"')
  processors = 0 if processors.nil?  # sometimes this returns nothing, so put in a default
  instances.each { |instance| @workers.push(create_struct(instance, processors)) }
end

def upload_file(host, local_path, remote_path)
  retries = 0
  begin
    Net::SCP.start(host, 'ubuntu', :key_data => [@private_key]) do |scp|
      scp.upload! local_path, remote_path
    end
  rescue SystemCallError, Timeout::Error => e
    # port 22 might not be available immediately after the instance finishes launching
    return if retries == 2
    retries += 1
    sleep 1
    retry
  rescue
    # Unknown upload error, retry
    return if retries == 2
    retries += 1
    sleep 1
    retry
  end
end


def send_command(host, command)
  retries = 0
  begin
    output = ''
    Net::SSH.start(host, 'ubuntu', :key_data => [@private_key]) do |ssh|
      response = ssh.exec!(command)
      output += response if !response.nil?
    end
    return output
  rescue Net::SSH::HostKeyMismatch => e
    e.remember_host!
    # key mismatch, retry
    return if retries == 2
    retries += 1
    sleep 1
    retry
  rescue Net::SSH::AuthenticationFailed
    error(-1, "Incorrect private key")
  rescue SystemCallError, Timeout::Error => e
    # port 22 might not be available immediately after the instance finishes launching
    return if retries == 2
    retries += 1
    sleep 1
    retry
  rescue Exception => e
    puts e.message
    puts e.backtrace.inspect
  end
end

def download_file(host, remote_path, local_path)
  retries = 0
  begin
    Net::SCP.start(host,'ubuntu', :key_data => [@private_key]) do |scp|
      scp.download! remote_path, local_path
    end
  rescue SystemCallError, Timeout::Error => e
    # port 22 might not be available immediately after the instance finishes launching
    return if retries == 2
    retries += 1
    sleep 1
    retry
  rescue
    return if retries == 2
    retries += 1
    sleep 1
    retry
  end
end

begin
  case ARGV[4]
    when 'describe_availability_zones'
      resp = @aws.client.describe_availability_zones
      puts resp.data.to_json
    when 'total_instances'
      resp = @aws.client.describe_instance_status
      puts ({:instances => resp.data[:instance_status_set].length}.to_json)
    when 'launch_server'
      if ARGV.length < 6
        error(-1, 'Invalid number of args')
      end

      @timestamp = Time.now.to_i
      @group = @aws.security_groups.create("sec-group-#{@timestamp}")
      @server_instance_type = @params['instance_type']
      @group.allow_ping() # allow ping
      @group.authorize_ingress(:tcp, 1..65535)# all traffic

      @key_pair = @aws.key_pairs.create("key-pair-#{@timestamp}")
      @private_key = @key_pair.private_key

      launch_server()

      puts ({:timestamp => @timestamp,
             :private_key => @private_key,
             :server => {
                 :id => @server.id,
                 :ip => @server.ip,
                 :dns => @server.dns,
                 :procs => @server.procs
             }}.to_json)
    when 'launch_workers'
      if ARGV.length < 6
        error(-1, 'Invalid number of args')
      end
      if @params['num'] < 1
        error(-1, 'Invalid number of worker nodes, must be greater than 0')
      end

      @workers = []
      @timestamp = @params['timestamp']
      @group = @aws.security_groups.filter('group-name', "sec-group-#{@timestamp}").first
      @key_pair = @aws.key_pairs.filter('key-name', "key-pair-#{@timestamp}").first
      @private_key = File.read(@params['private_key'])
      @worker_instance_type = @params['instance_type']
      @server = @aws.instances[@params['server_id']]
      error(-1, 'Server node does not exist') unless @server.exists?
      @server = create_struct(@server, @params['server_procs'])

      launch_workers(@params['num'], @server.ip)
      #@workers.push(create_struct(@aws.instances['i-xxxxxxxx'], -1))
      #processors = send_command(@workers[0].ip, 'nproc | tr -d "\n"')
      #@workers[0].procs = processors

      ips = "master|#{@server.ip}|#{@server.dns}|#{@server.procs}|ubuntu|ubuntu\n"
      @workers.each { |worker| ips << "worker|#{worker.ip}|#{worker.dns}|#{worker.procs}|ubuntu|ubuntu\n" }
      file = Tempfile.new('ip_addresses')
      file.write(ips)
      file.close
      upload_file(@server.ip, file.path, 'ip_addresses')
      file.unlink

      send_command(@server.ip, '~/setup-ssh-keys.expect; ~/setup-ssh-worker-nodes.sh ip_addresses')

      mongoid = File.read(File.expand_path(File.dirname(__FILE__))+'/mongoid.yml.template')
      mongoid.gsub!(/SERVER_IP/, @server.ip)
      file = Tempfile.new('mongoid.yml')
      file.write(mongoid)
      file.close
      upload_file(@server.ip, file.path, '/mnt/openstudio/rails-models/mongoid.yml')

      @workers.each { |worker| upload_file(worker.ip, file.path, '/mnt/openstudio/rails-models/mongoid.yml') }
      file.unlink

      # Does this command crash it?
      send_command(@server.ip, 'chmod 664 /mnt/openstudio/rails-models/mongoid.yml')
      @workers.each { |worker| send_command(worker.ip, 'chmod 664 /mnt/openstudio/rails-models/mongoid.yml') }

      worker_json = []
      @workers.each { |worker|
        worker_json.push({
                             :id => worker.id,
                             :ip => worker.ip,
                             :dns => worker.dns,
                             :procs => worker.procs
                         })
      }
      puts ({:workers => worker_json}.to_json)

    when 'terminate_session'
      if ARGV.length < 6
        error(-1, 'Invalid number of args')
      end
      server = @aws.instances[@params['server_id']]
      error(-1, "Server node #{server_id} does not exist") unless server.exists?
      server.terminate
      @params['worker_ids'].each { |worker_id|
        worker = @aws.instances[worker_id]
        error(-1, "Worker node #{worker_id} does not exist") unless worker.exists?
        worker.terminate
      }

      # When session is fully terminated, then delete key pair and security group
      #@aws.security_groups.filter('group-name', "sec-group-#{@params['timestamp']}").each do |group|
      #  group.delete
      #end
      #todo: delete key pair

    else
      error(-1, "Unknown command: #{ARGV[4]} (#{ARGV[3]})")
  end
    #puts \"Status: #{resp.http_response.status}\"
rescue Exception => e
  if e.message == 'getaddrinfo: No such host is known. '
    error(503, 'Offline')
  end
  #puts Hash.from_xml(e.http_response.body).to_json
  puts e
  #error(e.http_response.status, e.code)
end