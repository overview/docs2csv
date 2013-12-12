docs2csv
========

Scan a folder of document files of all types and extract the text into a CSV suitable for import into Overview. Currently supports PDF, JPG, HTML, and Microsoft Word, PowerPoint and Excel. 

PDFs will be OCRd if -o set and they contain no text, or always if -f set. 
JPGs will allways be OCRd.

**First you will need to install**
  - Poppler, for pdfimages (and pdftotext on some systems)
    On Linux, use aptitude, apt-get or yum:

    ```aptitude install poppler-utils poppler-data```

    On the Mac, you can install from source or use MacPorts:

    ```sudo port install poppler | brew install poppler```

  - Tesseract, for OCR

    ```[aptitude | port | brew] install [tesseract | tesseract-ocr]```

    Without Tesseract installed, you'll still be able to extract text from documents, but you won't be able to automatically OCR them.

  - Ruby 1.9.x

    Ubuntu comes with ruby 1.8. You can install ruby 1.9.1 like this:

    ```sudo apt-get install ruby1.9.1```
    ```sudo update-alternatives --set ruby /usr/bin/ruby1.9.1```

**Typical usage** 

    ruby docs2csv.rb -r -o directory-to-scan output.csv
    
This scans the directory recursively, and OCRs any PDFs which may need it. Other options:

    -l, --list                       Only list files, do not process
    -r, --recurse                    Scan directory recursively
    -o, --ocr                        OCR pdfs that do not contain text
    -f, --force-ocr                  Force OCR on all pdfs


**Viewing the original files from Overview**

The extracted text will be shown in the Overview document viewer, but not the original document pages. You can view the original files in your browser via Overview's "source file" links, if you start up a simple web server like this:

    python -m SimpleHTTPServer

The "source file" links use the URL column that docs2csv writes, which has addresses of the form  http://localhost:8000/[filename]. You need to run this server from the same directory where you originally ran docs2csv, as these file URLs are relative.

