require 'rubygems'
require 'rake/dsl_definition'
require 'ostruct'
require 'rbconfig'

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

def run(command)
  puts command
  system command
  puts
end

def run_and_get_output(command)
  puts command
  output = `#{command}`  
  puts
  return output
end

def platform
  os = RbConfig::CONFIG['host_os']
  case
    when os.downcase.include?('linux')
      :linux
    when os.downcase.include?('darwin')
      :mac
    else
      :windows
    end
end

def str_with_leading_zero(n, k)
  sprintf("%0#{k}d", n)
    #s = n.to_s
    #while s.length < k do
    #  s = "0" + s
    #end
    #s    
end

def xrange(start, stop, increment=1)
  i = start
  while i < stop
    yield i
    i += increment
  end
end

def xrangelist(start, stop, increment=1)
  result = []
  xrange(start, stop, increment) do |x|
    result << x
  end
  result
end

def create_file_with_erb(filename, erb_filename, parameters)
  template_content = File.open(erb_filename, "rt") {|f| f.read }
  template = ERB.new(template_content)
  params = OpenStruct.new(parameters).instance_eval { binding }  
  file_content = template.result(params)  
  File.open(filename, "wt") { |f| f.write(file_content) }  
end

class FileProcessingTasks
  include Rake::DSL

  attr_reader :name
  attr_reader :dir_name
  attr_reader :options

  def one_index_list(index_count)
    result = []
    index_count.times do |index|
      value = yield(index)
      result << value
    end
    result
  end  

  def two_indices_list(first_index_count, second_index_count)
    result = []
    first_index_count.times do |first_index|
      second_index_count.times do |second_index|
        value = yield(first_index, second_index)
        result << value
      end
    end
    result
  end

  def two_indices_loop(first_index_count, second_index_count)
    first_index_count.times do |first_index|
      second_index_count.times do |second_index|
        yield(first_index, second_index)
      end
    end
  end

  def three_indices_list(first_index_count, second_index_count, third_index_count)
    result = []
    first_index_count.times do |first_index|
      second_index_count.times do |second_index|
        third_index_count.times do |third_index|
          value = yield(first_index, second_index, third_index)
          result << value
        end
      end
    end
    result
  end

  def three_indices_loop(first_index_count, second_index_count, third_index_count)
    first_index_count.times do |first_index|
      second_index_count.times do |second_index|
        third_index_count.times do |third_index|
          yield(first_index, second_index, third_index)          
        end
      end
    end
  end

  class << self
    def def_index(name, &block)     
      define_method((name.to_s + "_count").to_sym, &block)
    end

    def no_index_file_tasks(file_task_name, file_name_func, &block)
      define_method((file_task_name.to_s + "_file_name").to_sym, file_name_func)

      index_name = index_name.to_s

      define_method((file_task_name.to_s + "_file_task").to_sym, &block)

      define_method((file_task_name.to_s + "_tasks").to_sym) do
        eval(<<-CODE          
          #{file_task_name}_file_task()          

          namespace name do
            desc "Create #{file_task_name} file for the \#{name} task"
            task :#{file_task_name} => [#{file_task_name}_file_name]

            desc "Clean #{file_task_name} files for the \#{name} task"
            task :#{file_task_name}_clean do
              f = #{file_task_name}_file_name
              puts "Removing \#{f} ..."
              FileUtils.rm_rf(f)
            end
          end
        CODE
        )
      end
    end

    def one_index_file_tasks(file_task_name, index_name, file_name_func, &block)
      define_method((file_task_name.to_s + "_file_name").to_sym, file_name_func)

      index_name = index_name.to_s

      define_method((file_task_name.to_s + "_file_list").to_sym) do       
        eval(<<-CODE        
          one_index_list(#{index_name}_count) do |#{index_name}_index|
            #{file_task_name}_file_name(#{index_name}_index)
          end       
        CODE
        )
      end

      define_method((file_task_name.to_s + "_file_task").to_sym, &block)

      define_method((file_task_name.to_s + "_tasks").to_sym) do
        eval(<<-CODE
          #{index_name}_count.times do |#{index_name}_index|
            #{file_task_name}_file_task(#{index_name}_index)
          end

          namespace name do
            desc "Create #{file_task_name} files for the \#{name} task"
            task :#{file_task_name} => #{file_task_name}_file_list

            desc "Clean #{file_task_name} files for the \#{name} task"
            task :#{file_task_name}_clean do
              #{file_task_name}_file_list.each do |f|
                puts "Removing \#{f} ..."
                FileUtils.rm_rf(f)
              end
            end
          end
        CODE
        )
      end
    end

    def two_indices_file_tasks(file_task_name, 
        first_index_name,
        second_index_name, 
        file_name_func, 
        &block)
      
      define_method((file_task_name.to_s + "_file_name").to_sym, file_name_func)

      first_index_name = first_index_name.to_s
      second_index_name = second_index_name.to_s

      define_method((file_task_name.to_s + "_file_list").to_sym) do       
        eval(<<-CODE        
          two_indices_list(#{first_index_name}_count, #{second_index_name}_count) do |#{first_index_name}_index, #{second_index_name}_index|
            #{file_task_name}_file_name(#{first_index_name}_index, #{second_index_name}_index)
          end       
        CODE
        )
      end

      define_method((file_task_name.to_s + "_file_task").to_sym, &block)

      define_method((file_task_name.to_s + "_tasks").to_sym) do
        eval(<<-CODE
          two_indices_loop(#{first_index_name}_count, #{second_index_name}_count) do |#{first_index_name}_index, #{second_index_name}_index|
            #{file_task_name}_file_task(#{first_index_name}_index, #{second_index_name}_index)
          end       

          namespace name do
            desc "Create #{file_task_name} files for the \#{name} task"
            task :#{file_task_name} => #{file_task_name}_file_list

            desc "Clean #{file_task_name} files for the \#{name} task"
            task :#{file_task_name}_clean do
              #{file_task_name}_file_list.each do |f|
                puts "Removing \#{f} ..."
                FileUtils.rm_rf(f)
              end
            end

            desc "Create a specific #{file_task_name} file for the \#{name} task"
            task :#{file_task_name}_gen, [:#{first_index_name}_index, :#{second_index_name}_index] do |t, args|
              Rake::Task[#{file_task_name}_file_name(args.#{first_index_name}_index, args.#{second_index_name}_index)].invoke
            end
          end
        CODE
        )
      end      
    end

    def three_indices_file_tasks(file_task_name, 
        first_index_name,
        second_index_name, 
        third_index_name,
        file_name_func, 
        &block)
        
      define_method((file_task_name.to_s + "_file_name").to_sym, file_name_func)

      first_index_name = first_index_name.to_s
      second_index_name = second_index_name.to_s
      third_index_name = third_index_name.to_s

      define_method((file_task_name.to_s + "_file_list").to_sym) do       
        eval(<<-CODE        
          three_indices_list(#{first_index_name}_count, #{second_index_name}_count, #{third_index_name}_count) do |#{first_index_name}_index, #{second_index_name}_index, #{third_index_name}_index|
            #{file_task_name}_file_name(#{first_index_name}_index, #{second_index_name}_index, #{third_index_name}_index)
          end       
        CODE
        )
      end

      define_method((file_task_name.to_s + "_file_task").to_sym, &block)

      define_method((file_task_name.to_s + "_tasks").to_sym) do
        eval(<<-CODE
          three_indices_loop(#{first_index_name}_count, #{second_index_name}_count, #{third_index_name}_count) do |#{first_index_name}_index, #{second_index_name}_index, #{third_index_name}_index|
            #{file_task_name}_file_task(#{first_index_name}_index, #{second_index_name}_index, #{third_index_name}_index)
          end       

          namespace name do
            desc "Create #{file_task_name} files for the \#{name} task"
            task :#{file_task_name} => #{file_task_name}_file_list

            desc "Clean #{file_task_name} files for the \#{name} task"
            task :#{file_task_name}_clean do
              #{file_task_name}_file_list.each do |f|
                puts "Removing \#{f} ..."
                FileUtils.rm_rf(f)
              end
            end

            desc "Create a specific #{file_task_name} file for the \#{name} task"
            task :#{file_task_name}_gen, [:#{first_index_name}_index, :#{second_index_name}_index] do |t, args|
              Rake::Task[#{file_task_name}_file_name(args.#{first_index_name}_index, args.#{second_index_name}_index)].invoke
            end
          end
        CODE
        )
      end      
    end
  end  

  def initialize(name, dir_name, options={})
    @name = name
    @dir_name = dir_name
    @options = options

    FileUtils.mkdir_p(dir_name)    

    gen_tasks
  end

  def gen_tasks
  end
end

def task_from_tasks(name, task_list, task_names)
  namespace name do
    task_names.each do |task_name|
      dependencies = task_list.map {|x| x + ":#{task_name}"}.select {|x| Rake::Task.task_defined?(x)}
      task task_name => dependencies
    end
  end
end 