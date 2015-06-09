require 'nokogiri'
require 'colorize'

blacklist = [ 'lorca', 'rivera', 'piwi' ]

def generate_load_bar(slots_by_owner, owner_to_short, total_slots, overload_threshold)
  load_bar = ''
  remaining_slots = total_slots
  slots_by_owner.each do |owner, slots|
    load_bar += "#{owner_to_short[owner] * slots}"
    remaining_slots -= slots
  end
  load_bar += '-' * remaining_slots if remaining_slots >= 0

  load_bar[overload_threshold..total_slots] = load_bar[overload_threshold..total_slots].red
  load_bar.insert(overload_threshold, '|') if overload_threshold < total_slots
  load_bar
end

def get_mem_in_gb(mem_string)
  case mem_string[-1]
    when 'M'
      (mem_string.split('M').first.to_f / 1024).floor
    when 'G'
      (mem_string.split('M').first.to_f).floor
    when 'T'
      (mem_string.split('M').first.to_f * 1024).floor
  end
end

def get_formatted_load_avg(slots_by_owner, load_avg, overload_threshold)
  used_slots = 0
  slots_by_owner.each do |owner, slots|
    used_slots += slots
  end

  if load_avg > overload_threshold + 2 or load_avg > used_slots + 2 then
    load_avg.to_s.red
  else
    load_avg.to_s.green
  end

end


def get_short_for_owner(owner_to_short, owner)
  possibilities = [ owner[0], owner[0].capitalize, '$', '#', '%', '&', '*' ]
  possibilities.each do |short|
    if not owner_to_short.values.include?(short) then
      return short
    end
  end
  exit -1
end

info = Hash.new
owner_to_short = Hash.new

qhost_xml = %x{qhost -cb -xml}
qstat_xml = %x{qstat -g t -s r -u '*' -xml}

Nokogiri.XML(qhost_xml).xpath("//host[@name != 'global']").each do |host|
  hostname = host.xpath("@name").to_s

  next if blacklist.include?(hostname.split('.').first)

  cores = host.xpath("hostvalue[@name = 'm_core']/text()").text.to_i
  slots = host.xpath("hostvalue[@name = 'num_proc']/text()").text.to_i
  load_avg = host.xpath("hostvalue[@name = 'load_avg']/text()").text.to_f
  mem_total = host.xpath("hostvalue[@name = 'mem_total']/text()").text
  mem_used = host.xpath("hostvalue[@name = 'mem_used']/text()").text

  # skip hosts that are down
  next if cores == 0 or slots == 0

  # set up data structure for host
  info[hostname] = Hash.new
  info[hostname][:jobs] = Hash.new(0)

  info[hostname][:cores] = cores
  info[hostname][:slots] = slots
  info[hostname][:load_avg] = load_avg
  info[hostname][:mem_total] = get_mem_in_gb(mem_total)
  info[hostname][:mem_used] = get_mem_in_gb(mem_used)
end

# get the juicy job details
Nokogiri.XML(qstat_xml).xpath("//job_list").each do |job|
  hostname = job.xpath("queue_name/text()").to_s.split('@').last
  owner = job.xpath("JB_owner/text()").text
  slots = job.xpath("slots/text()").text.to_i

  info[hostname][:jobs][owner] += slots unless info[hostname].nil?
  owner_to_short[owner] = get_short_for_owner(owner_to_short, owner) if owner_to_short[owner].nil? 
end

# natural sort by: http://stackoverflow.com/questions/4078906/is-there-a-natural-sort-by-method-for-ruby
out = ""
info.
    select { |key| key.to_s.match(/compute-.*/) }.
    sort_by {|e| e.first.split(/(\d+)/).map {|a| a =~ /\d+/ ? a.to_i : a }}.
    each.with_index(1) do | (hostname, data), index|
  shortname = hostname.split('.').first #.gsub(/compute/, 'c')
  
  load_bar = generate_load_bar(data[:jobs], owner_to_short, data[:slots], data[:cores])
  out += sprintf("%-12s: [%s] %20s  %2.0f/%2.0f\t", shortname, load_bar, get_formatted_load_avg(data[:jobs], data[:load_avg], data[:cores]), data[:mem_used], data[:mem_total])
  if index % 1 == 0 then
    puts out
    out = ""
  end
end
puts out

puts "Users:"
owner_to_short.each do |user, short|
  puts "#{user}: #{short}"
end
