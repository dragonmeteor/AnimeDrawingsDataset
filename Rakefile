require 'rubygems'
require 'rake'
require 'mechanize'
require 'nokogiri'
require 'fileutils'
require File.dirname(__FILE__) + "/rake/lib.rb"

def save_image(agent, uri, filename)
	print "Saving #{uri} to #{filename} ... "
	begin		
		agent.get(uri).save!(filename)
		sleep(1)		
	rescue Mechanize::ResponseReadError => e
		puts e
		puts
	rescue Mechanize::ResponseCodeError => e
		puts e
		puts
	else 
		puts "FINISH!"
	end
end

class DownloadDataTasks < FileProcessingTasks
	def initialize(_name, _dir_name, _options={})
		super(_name, _dir_name, _options)
	end

	def gen_tasks
		images_raw_tasks
	end

	def fetch_image(id)
		agent = Mechanize.new
		url = "http://danbooru.donmai.us/posts/#{id}"
		page = agent.get(url)
		text = page.body
		doc = Nokogiri::HTML(text)
		doc.xpath("//meta").each do |meta|
			if !meta.key?("property") then next end
			if meta["property"] == "og:image"
				image_url = meta["content"]
				ext = File.extname(image_url)
				save_image(agent, image_url, "#{dir_name}/images_raw/#{id}#{ext}")
			end
		end
	end

	no_index_file_tasks(:images_raw, Proc.new {"#{dir_name}/images_raw/done.txt"}) do
		file images_raw_file_name => ["#{dir_name}/data.json"] do
			FileUtils.mkdir_p("#{dir_name}/images_raw")
			data = JSON.parse(File.read("#{dir_name}/data.json"))
			agent = Mechanize.new
			data.each do |item|
				id = File.basename(item["file_name"], ".*")				
				fetch_image(id)				
			end
			File.open(images_raw_file_name, "w") do |fout| end
		end
	end
end

DownloadDataTasks.new("data", "data")

task :default => []