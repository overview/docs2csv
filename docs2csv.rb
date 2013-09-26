# Scan a directory for Document files (possibly recursively),
# Extract text, OCR if needed, 
# create a .CSV file for use with Overview
#
# Example usage:
#    ruby docs2csv.rb dir-full-of-PDFs output.csv
#
# Requires docsplit, http://documentcloud.github.com/docsplit/ 
 
require 'rubygems'
require 'Digest'
require 'ostruct'
require 'optparse'
require 'uri'
require 'csv'
require 'json'

# ------------------------------------------- Modules, functions ----------------------------------------
# text extraction, directory recursion, file matching
  
 # extract text from specified PDF
# We use pdftotext. On Windows, we expect it to be located where we are
def extractTextFromPDF(filename)
	if ENV['OS'] == "Windows_NT"
		pdftotextexec = File.expand_path(File.dirname(__FILE__)) + "/pdftotext.exe"
	else
		pdftotextexec = "pdftotext"
	end
	text = `"#{pdftotextexec}" "#{filename}" -`
end

# extract text from specified file
# Format dependent
def extractTextFromFile(filename)
	format = File.extname(filename)
	if format == ".pdf"
		extractTextFromPDF(filename)
	elsif format == ".txt"
		File.open(filename).read
	end
end

# Recursively scan a directory structure for matching files, process each one
# Execute callfn for each file in direname where matchfn returns true, recurse into dirs if recurse is true
def scanDir(dirname, matchfn, callfn, recurse)
	Dir.foreach(dirname) do |filename|
		fullfilename = dirname + "/" + filename;
		if File.directory?(fullfilename)
			if recurse && filename != "." && filename != ".."		# don't infinite loop kthx
				scanDir(fullfilename, matchfn, callfn, recurse)
			end
		elsif matchfn.call(filename)
			callfn.call(fullfilename)
		end
	end
end


# Based on file extension, is this a document file?
def matchFn(filename)
	return [".txt", ".pdf"].include? File.extname(filename)
end


# upload/extract text from a single file
# precondition: File.exists?(filename)
def processFile(filename, options)
	puts "Processing #{filename}"

	# We generate four fields for each document:
	# - uid, a hash of the filename (including relative path)
	# - text, the extracted text
	# - title, the filename (relative)  
	# - url, a file:// URL pointing to the doc on disk (absolute)
	if options.process
		text = extractTextFromFile(filename)
		title = filename
		url = "file://" + File.expand_path(filename)
		uid = Digest::MD5.hexdigest(filename)
		
		options.csv << [uid, text, title, url]
	end
end

# ------------------------------------------- Process command-line args ----------------------------------------

options = OpenStruct.new
options.process = true
options.recurse = false

OptionParser.new do |opts|
  	opts.banner = "Usage: docs2csv.rb [-r] [-l] directory outputfile"

	opts.on("-l", "--list", "Only list files, do not process") do |v|
		options.process = false
	end	  

	opts.on("-r", "--recurse", "Scan directory recursively") do |v|
		options.recurse = true
	end	  
end.parse!

#puts options
#puts ARGV

unless dirname = ARGV[0]
	puts "ERROR: no directory name specified"
	exit
end

unless options.outputfile = ARGV[1]
	puts "ERROR: no output file specified"
	exit
end
	
# ------------------------------------------- Do it! ----------------------------------------

# Open output CSV filename and write header
if options.process
	options.csv = CSV.open(options.outputfile,"w")
	options.csv << ["uid", "text", "title", "url"]
end

# And we're ready. Iterate, possibly recursively, through directory in question
scanDir(dirname, method(:matchFn), proc { |filename| processFile(filename, options) }, options.recurse )
