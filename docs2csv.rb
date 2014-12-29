#!/usr/bin/env ruby
# Scan a directory for Document files (possibly recursively),
# Extract text, OCR if needed,
# create a .CSV file for use with Overview
#
# Example usage:
#    ruby docs2csv.rb dir-full-of-PDFs output.csv
#
# Requires tesseract and poppler for OCR functionality

require 'rubygems'
require 'digest'
require 'tmpdir'
require 'ostruct'
require 'optparse'
require 'uri'
require 'csv'

# ------------------------------------------- Modules, functions ----------------------------------------
# text extraction, directory recursion, file matching

# is there actually any content to this text? Used to trigger OCR
# currently, just check for at least one letter. Scans saved to PDF
# often extract as just a series of form feed (\f) characters
def emptyText(text)
  (text =~ /[azAZ]/) == nil
end

# extract text from specified PDF
# We use pdftotext. On Windows, we expect it to be located where we are
def extractTextFromPDF(filename, options)
  if ENV['OS'] == "Windows_NT"
    pdftotextexec = File.expand_path(File.dirname(__FILE__)) + "/pdftotext.exe"
  else
    pdftotextexec = "/usr/local/bin/pdftotext"
  end

  text = `"#{pdftotextexec}" "#{filename}" -`
  if options.force_ocr or (emptyText(text) and options.ocr)
    text += ocrPDF(filename)
  end
  text
end

# OCR a specific file.
# Requires a tmp path to where the output file will be written (won't be deleted after use)
# More or less just a tesseract call, but we turn on orientation detection.
# This requires the orientation "langauge", not installed by default.
# So we include in our repo, and export environment variables to point to it
def ocrFile(filename, tmpdir)
  ENV['TESSDATA_PREFIX'] = File.expand_path(File.dirname(__FILE__))
  system("tesseract -psm 1 -l eng \"#{filename}\" \"#{tmpdir}/output\"")
  File.open("#{tmpdir}/output.txt").read
end

# render and OCR a PDF. Requires splitting it into pages and concatenating
def ocrPDF(filename)
  text = ""
  #  extract all images in the PDF to a temp directory, then OCR from there
  Dir.mktmpdir {|dir|
      `pdfimages "#{filename}" "#{dir}/img"`
      Dir.foreach(dir) do |imgfile|
        if imgfile != "." && imgfile != ".."
          STDERR.write "OCRing file #{imgfile}\n"
          begin
            text += ocrFile("#{dir}/#{imgfile}",dir) + '\n'
          rescue => error
            STDERR.write "OCR Error, skipping page.\n"
            STDERR.write error.message
            STDERR.write error.backtrace
          end
        end
      end
  }
  text
end

# ocr a single image file
# return empty text if OCR option is not set
def ocrImage(filename, options)
  text = ""
  if options.ocr
    Dir.mktmpdir {|dir|
        STDERR.write "OCRing file #{filename}\n"
        text = ocrFile(filename, dir)
    }
  end
  text
end


# Extract text using Apache Tika. Handles many file formats, including MS Office, HTML
def extractTextTika(filename)
  execDir = File.expand_path(File.dirname(__FILE__))
  `java -jar #{execDir}/tika-app-1.4.jar -t "#{filename}"`
end

# extract text from specified file
# Format dependent
def extractTextFromFile(filename, options)
  format = File.extname(filename)
  if format == ".pdf"
    extractTextFromPDF(filename, options)
  elsif format == ".jpg"
    ocrImage(filename, options)
  elsif format == ".txt"
    File.open(filename).read
  else
    extractTextTika(filename)
  end
end

# Recursively scan a directory structure for matching files, process each one
# Execute callfn for each file in direname where matchfn returns true, recurse into dirs if recurse is true
def scanDir(dirname, matchfn, callfn, recurse)
  Dir.foreach(dirname) do |filename|
    fullfilename = dirname + '/' + filename;
    if File.directory?(fullfilename)
      if recurse && filename != "." && filename != ".."   # don't infinite loop kthx
        scanDir(fullfilename, matchfn, callfn, recurse)
      end
    elsif matchfn.call(filename)
      callfn.call(fullfilename)
    end
  end
end


# Based on file extension, is this a document file?
def matchFn(filename)
  formats = [".txt", ".pdf", ".html", ".htm", ".mhtml", ".mht", ".doc", ".docx", ".ppt", ".pptx", ".xls", ".xlsx", ".jpg", ".rtf"]
  return formats.include? File.extname(filename)
end

# strip characters to make sure the CSV is valid
def cleanText(text)
  # force clean UTF-8 encoding, if the version of Ruby we're on supports it
  # Actually we assume UTF-8 here, may not be correct
  if RUBY_VERSION >= "1.9"

    # First, force to UTF-8 encoding
    if text.encoding.name != "UTF-8"
      text = text.force_encoding('UTF-8')
    end

    # If we still don't have a valid string, re-encode
    if !text.valid_encoding?
      text = text.encode('UTF-16', invalid: :replace, undef: :replace).encode('UTF-8')
    end

  end
  text.gsub!("\f", "\n") # turn \f into \n
  text.gsub("\x00", "")  # remove null bytes (See https://www.pivotaltracker.com/story/show/61360820)
end

# upload/extract text from a single file
# precondition: File.exists?(filename)
def processFile(filename, options)
  STDERR.write "Processing #{filename}\n"
  begin
    # We generate four fields for each document:
    # - uid, a hash of the filename (including relative path)
    # - text, the extracted text
    # - title, the filename (relative)
    # - url, an http://localhost:8000 URL to the relative path
    if options.process
      text = cleanText(extractTextFromFile(filename, options))
      title = filename
      url = "http://localhost:8000/" + filename
      uid = Digest::MD5.hexdigest(filename)

      options.csv << [uid, text, title, url]
    end
  rescue => error
    STDERR.write "Error processing #{filename}, skipping.\n"
    STDERR.write error.message
      STDERR.write error.backtrace
  end
end

# ------------------------------------------- Process command-line args ----------------------------------------

options = OpenStruct.new
options.process = true
options.recurse = false
options.ocr = false
options.force_ocr = false

OptionParser.new do |opts|
    opts.banner = "Usage: docs2csv.rb [options] directory outputfile"

  opts.on("-l", "--list", "Only list files, do not process") do |v|
    options.process = false
  end

  opts.on("-o", "--ocr", "OCR image files and pdfs that do not contain text") do |v|
    options.ocr = true
  end

  opts.on("-f", "--force-ocr", "Force OCR on all pdfs") do |v|
    options.force_ocr = true
  end

  opts.on("-r", "--recurse", "Scan directory recursively") do |v|
    options.recurse = true
  end
end.parse!

#STDERR.write options
#STDERR.write ARGV

unless dirname = ARGV[0]
  STDERR.write "ERROR: no directory name specified\n"
  exit
end

if ARGV[1]
    options.outputfile = File.open(ARGV[1], "w")
else
    options.outputfile = STDOUT
end

# ------------------------------------------- Do it! ----------------------------------------

# Open output CSV filename and write header
if options.process
  options.csv = CSV.new(options.outputfile)
  options.csv << ["id", "text", "title", "url"]
end

# And we're ready. Iterate, possibly recursively, through directory in question
scanDir(dirname, method(:matchFn), proc { |filename| processFile(filename, options) }, options.recurse )
