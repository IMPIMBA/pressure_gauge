require 'nokogiri'
require 'pp'

# host:
#  slots
#  cores
#  jobs:
#    owner: slots

# we only need qhost -cb here
qhost_xml = File.open('test/qhost_cb_j.xml')
Nokogiri.XML(qhost_xml).xpath("//host[@name != 'global']").each do |host|
  name_full = host.xpath("@name").to_s
  name_short = name_full.split('.').first
  cores = host.xpath("hostvalue[@name = 'm_core']/text()")
  slots = host.xpath("hostvalue[@name = 'num_proc']/text()")
  job_num = host.xpath("job").count

  puts "Host #{name_short}: #{slots}/#{cores} runs #{job_num} Jobs"

  # host.xpath("job").each{ |job|
  #   job.xpath("")
  # }
end

job_stats = Hash.new
# get the juicy job details
qstat_xml = File.open('test/qstat_gt_sr.xml')
Nokogiri.XML(qstat_xml).xpath("//job_list").each do |job|
  hostname = job.xpath("queue_name/text()").to_s.split('@').last
  owner = job.xpath("JB_owner/text()").text
  slots = job.xpath("slots/text()").text

  if job_stats[hostname].nil? then job_stats[hostname] = Hash.new end
  if job_stats[hostname][owner].nil? then job_stats[hostname][owner] = 0 end

  job_stats[hostname][owner] += 1
end

pp job_stats
pp job_stats["compute-6-20.imp.univie.ac.at"].sort