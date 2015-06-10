require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'mechanize'
require 'nokogiri'
require 'fileutils'
require File.dirname(__FILE__) + "/rake/lib.rb"

class DownloadDataTasks < FileProcessingTasks
	def initialize(_name, _dir_name, _options={})
		super(_name, _dir_name, _options)
	end

	def gen_tasks
		images_raw_tasks
		images_tasks
		images_thumb_tasks
	end

	def save_image(agent, uri, actual_filename, target_filename)
		print "Saving #{uri} to #{actual_filename} ... "
		begin
			if !File.exists?(actual_filename)
				agent.get(uri).save!(actual_filename)
				sleep(1)
				puts "FINISH!"
			else
				puts "EXISTS!"
			end
			if File.extname(actual_filename) != File.extname(target_filename)
				print "Converting #{actual_filename} to #{target_filename} ... "				
				run("convert #{actual_filename} #{target_filename}")
				FileUtils.rm_rf(actual_filename)
			end
		rescue Mechanize::ResponseReadError => e
			puts e
			puts
		rescue Mechanize::ResponseCodeError => e
			puts e
			puts		
		end
	end


	def fetch_raw_image(file_name)
		target_file = "data/images_raw/" + File.basename(file_name)			
		if File.exists?(target_file)
			puts "File #{target_file} already exists."
			return
		else
			puts target_file			
		end
		id = File.basename(target_file, ".*")
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
				save_image(agent, image_url, "#{dir_name}/images_raw/#{id}#{ext}", target_file)
			end
		end
	end

	no_index_file_tasks(:images_raw, Proc.new {"#{dir_name}/images_raw/done.txt"}) do
		file images_raw_file_name => ["#{dir_name}/data.json"] do
			FileUtils.mkdir_p("#{dir_name}/images_raw")
			data = JSON.parse(File.read("#{dir_name}/data.json"))			
			data.each do |item|				
				fetch_raw_image(item["file_name"])				
			end
			File.open(images_raw_file_name, "w") do |fout| end
		end
	end

	no_index_file_tasks(:images, Proc.new {"#{dir_name}/images/done.txt"}) do
		file images_file_name => [images_raw_file_name] do
			FileUtils.mkdir_p("#{dir_name}/images")
			data = JSON.parse(File.read("#{dir_name}/data.json"))
			data.each do |item|
				new_file_name = item["file_name"]
				old_file_name = "data/images_raw/" + File.basename(new_file_name)
				run("convert -resize 800x600\\> #{old_file_name} #{new_file_name}")
			end
			File.open(images_file_name, "w") do |fout| end
		end
	end

	no_index_file_tasks(:images_thumb, Proc.new {"#{dir_name}/images_thumb/done.txt"}) do
		file images_thumb_file_name => [images_file_name] do
			FileUtils.mkdir_p("#{dir_name}/images_thumb")
			data = JSON.parse(File.read("#{dir_name}/data.json"))
			data.each do |item|
				old_file_name = item["file_name"]
				new_file_name = "data/images_thumb/" + File.basename(old_file_name)
				run("convert -resize 100x100\\> #{old_file_name} #{new_file_name}")
			end
			File.open(images_thumb_file_name, "w") do |fout| end
		end
	end
end

class DataHtmlTasks < FileProcessingTasks
	def initialize(_name, _dir_name, _options={})
		_options = {
			:data_file => ""
		}.merge(_options)
		super(_name, _dir_name, _options)
	end

	def gen_tasks
		html_tasks
	end

	no_index_file_tasks(:html, Proc.new {"#{dir_name}/done.txt"}) do
		file html_file_name => [options[:data_file]] do
			data = JSON.parse(File.read(options[:data_file]))

			# Index HTML			
			create_file_with_erb("#{dir_name}/index.html", "erb/dataset_index.erb", 
				:dataset_name => options[:dataset_name],
				:data => data)
			
			# Examples HTMLs
			FileUtils.mkdir_p("#{dir_name}/examples")
			data.count.times do |i|
				item = data[i]		
				index_string = sprintf("%04d",i)
				prev_index_string = if i > 0 then sprintf("%04d",i-1) else nil end
				next_index_string = if i < data.count-1 then sprintf("%04d",i+1) else nil end
				create_file_with_erb("#{dir_name}/examples/#{sprintf("%04d", i)}.html",
					"erb/dataset_example.erb",
					:index_string => index_string,
					:prev_index_string => prev_index_string,
					:next_index_string => next_index_string,
					:item => item,
					:dataset_name => options[:dataset_name])
				puts "Generated #{dir_name}/examples/#{sprintf("%04d",i)}.html ..."
			end

			File.open(html_file_name, "w") do |fout| end
		end
	end
end

DownloadDataTasks.new("data", "data")
DataHtmlTasks.new("html_train", "html/train", 
	:data_file => "data/train.json",
	:dataset_name => "train")
DataHtmlTasks.new("html_val",   "html/val",   
	:data_file => "data/val.json",
	:dataset_name => "val")
DataHtmlTasks.new("html_test",  "html/test",  
	:data_file => "data/test.json",
	:dataset_name => "test")

task :default => []

task :build => [
	"data:images_raw",
	"data:images",
	"data:images_thumb",
	"html_train:html",
	"html_val:html",
	"html_test:html"
]

task :clean => [
	"data:images_raw_clean",
	"data:images_clean",
	"data:images_thumb_clean",
	"html_train:html_clean",
	"html_val:html_clean",
	"html_test:html_clean"
]