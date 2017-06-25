require 'find'
require 'digest/md5'

root = ARGV[0]
unless root and File.directory?(root)
  puts "\nError: Path to directory is required!" \
       "\n  ruby changedFiles.rb <directory>"
  exit
end

file_output = "#{root}/file_list.txt"
old_file_output = "#{root}/file_list_old.txt"
exclude_files = [file_output, old_file_output]

old_file_hash = {}
if File.exists?(file_output)
  File.rename(file_output, old_file_output)
  File.open(old_file_output, 'rb') do |f|
    while (temp = f.gets)
      line = /(.+)\s{5,5}(\w{32,32})/.match(temp)
      puts "#{line[1]} ---> #{line[2]}" unless exclude_files.include?(line[1])
      old_file_hash[line[1]] = line[2]
    end
  end
end

new_file_hash = {}
Find.find(root) do |f|
  next if /^\./.match(f)
  next if !File.file?(f) || exclude_files.include?(f)
  begin
    new_file_hash[f] = Digest::MD5.hexdigest(File.read(f))
  rescue
   puts "Error: New hash code couldn't be counted for: #{f}"
  end
end

changed_files = File.new(file_output, 'wb')

new_file_hash.each do |f, md5|
  changed_files.puts "#{f}     #{md5}"
end

changed_files.close

new_file_hash.keys
  .select { |f| new_file_hash[f] == old_file_hash[f] }
  .each do |f|
    new_file_hash.delete(f)
    old_file_hash.delete(f)
  end

puts "\n\n"

new_file_hash.each do |f, md5|
  puts "#{old_file_hash[f] ? "Modified" : "Added"} file: #{f}"
  old_file_hash.delete(f)
end

old_file_hash.each do |f, md5|
  puts "Removed/moved file: #{f} #{md5}"
end
