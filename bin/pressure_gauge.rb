require 'nokogiri'
require 'pp'
require 'json'
require 'colorize'

# host:
#  slots
#  cores
#  jobs:
#    owner: slots


def generate_load_bar(slots_by_owner, total_slots, overload_threshold)
  remaining_slots = total_slots

  load_bar = ''
  slots_by_owner.each do |owner, slots|
    load_bar += "#{owner[0] * slots}"
    remaining_slots -= slots
  end
  load_bar += '-' * remaining_slots

  load_bar[overload_threshold..total_slots] = load_bar[overload_threshold..total_slots].colorize(:color => :red)
  load_bar.insert(overload_threshold, '|') if overload_threshold < total_slots
  load_bar
end

info = Hash.new
# we only need qhost -cb here
qhost_xml = File.open('test/qhost_cb_j.xml')
Nokogiri.XML(qhost_xml).xpath("//host[@name != 'global']").each do |host|
  hostname = host.xpath("@name").to_s

  cores = host.xpath("hostvalue[@name = 'm_core']/text()").text.to_i
  slots = host.xpath("hostvalue[@name = 'num_proc']/text()").text.to_i

  # skip hosts that are down
  next if cores == 0 or slots == 0

  # set up data structure for host
  info[hostname] = Hash.new
  info[hostname][:jobs] = Hash.new

  info[hostname][:cores] = cores
  info[hostname][:slots] = slots
end

# get the juicy job details
qstat_xml = File.open('test/qstat_gt_sr.xml')
Nokogiri.XML(qstat_xml).xpath("//job_list").each do |job|
  hostname = job.xpath("queue_name/text()").to_s.split('@').last
  owner = job.xpath("JB_owner/text()").text
  slots = job.xpath("slots/text()").text.to_i

  info[hostname][:jobs][owner] = 0 if info[hostname][:jobs][owner].nil?

  info[hostname][:jobs][owner] += slots
end


info.each do |hostname, data|

  shortname = hostname.split('.').first.gsub(/compute/, 'c')

  load_bar = generate_load_bar(data[:jobs], data[:slots], data[:cores])
  puts sprintf("%-6.6s: [%s]", shortname, load_bar)

end
