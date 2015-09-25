#!/usr/bin/env ruby

# nginx.confに以下のように追記して
#http {
#  log_format ltsv 'time:$time_iso8601\t'
#                  'remote_addr:$remote_addr\t'
#                  'request_method:$request_method\t'
#                  'request_length:$request_length\t'
#                  'request_uri:$request_uri\t'
#                  'uri:$uri\t'
#                  'query_string:$query_string\t'
#                  'status:$status\t'
#                  'bytes_sent:$bytes_sent\t'
#                  'body_bytes_sent:$body_bytes_sent\t'
#                  'referer:$http_referer\t'
#                  'useragent:$http_user_agent\t'
#                  'forwardedfor:$http_x_forwarded_for\t'
#                  'request_time:$request_time\t'
#                  'upstream_response_time:$upstream_response_time';
#
#  access_log /var/log/nginx/access.log ltsv;

#$ cat access.log | ruby parse_access_log.rb

require 'set'

records = []
indexs = Set.new

while gets
  record = Hash[$_.chomp.split("\t").map{|f| f.split(":", 2)}]
  record["request_method_uri"] = record["request_method"] + ":" + record["uri"]
  records.push(record)
  indexs.add(record["request_method_uri"])
end

summary = []

indexs.map do |index|
  targets = records.select do |record|
    record["request_method_uri"] == index
  end
  total_request = targets.length
  total_request_time = records.inject(0.0) do |memo, item|
    item["request_time"] = 0.0 if item["request_time"] == ""
    memo += item["request_time"].to_f
  end
  average_request_time = total_request_time / total_request
  max_request_time = records.inject(0.0) do |memo, item|
        item["request_time"] = 0.0 if item["request_time"] == ""
      memo = [memo, item["request_time"].to_f].max
  end
  summary.push({
    "uri" => index,
    "total_request" => total_request,
    "average_request_time" => average_request_time,
    "max_request_time" => max_request_time
  })
end

sortby_request = summary.sort_by { |item| -item["total_request"] }

printf("%8s\t%-35s\t%8s\t%8s\n", "total_request", "uri", "average_request_time", "max_request_time")
sortby_request.each do |item|
  printf("%8d\t%-35s\t%3.5f\t%3.5f\n", item["total_request"], item["uri"], item["average_request_time"], item["max_request_time"])
end
