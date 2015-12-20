require 'yaml'
require 'cloudflare'
require 'net/http'

def update_record(cf, record, public_ip)
  begin
      cf.rec_edit(
        record['zone_name'],
        record['type'],
        record['rec_id'],
        record['name'],
        public_ip,
        record['ttl'],
        record['service_mode'] == "1" ? true : false)
  rescue => e
      puts e.message
  else
    puts "Successfuly updated DNS record #{record['name']} with the IP #{public_ip}"
  end
end

def create_record(cf, public_ip)
  begin
    cf.rec_new(
      config['domain_name'],
      'A',
      config['domain_name'],
      public_ip,
      1)
  rescue => e
    puts e.message
  else
    puts "Record A created ! with the IP #{public_ip}"
  end
end

def create_or_update_record(cf, records, public_ip)
  if records.empty?
    puts 'No A record, creating one'
    create_record(cf, public_ip)
  else
    records.each do |record|
      update_record(cf, record, public_ip)
    end
  end
end

begin
  config = YAML.load_file('config.yml')
rescue
  puts 'Error: Please create a valid config file called config.yml in . (see config.sample.yml)'
  exit
end

cf = CloudFlare::connection(config['apikey'], config['email'])
rec = cf.rec_load_all(config['domain_name'])
a_records = rec['response']["recs"]["objs"].select { |z| z['type'] == 'A' }
public_ip = Net::HTTP.get URI 'https://api.ipify.org'

create_or_update_record(cf, a_records, public_ip)
