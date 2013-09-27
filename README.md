docs2csv
========

Scan a folder of document files of all types and extract the text into a CSV suitable for import into Overview. Currently supports PDF, JPG, HTML, and Microsoft Word, PowerPoint and Excel. 

PDFs will be OCRd if -o set and they contain no text, or always if -f set. 
JPGs will allways be OCRd.

First you will need to install:
  - Poppler, for pdfimages (and pdftotext on some systems)
    On Linux, use aptitude, apt-get or yum:

    ```aptitude install poppler-utils poppler-data```

    On the Mac, you can install from source or use MacPorts:

    ```sudo port install poppler | brew install poppler```

  - Tesseract, for OCR

    ```[aptitude | port | brew] install [tesseract | tesseract-ocr]```

    Without Tesseract installed, you'll still be able to extract text from documents, but you won't be able to automatically OCR them.

Typical usage: 

    ruby docs2csv.rb -r -o directory-to-scan output.csv
    
This scans the directory recursively, and OCRs any PDFs which may need it. Other options:

    -l, --list                       Only list files, do not process
    -r, --recurse                    Scan directory recursively
    -o, --ocr                        OCR pdfs that do not contain text
    -f, --force-ocr                  Force OCR on all pdfs

The output file will contain the extracted text from each file, plus URL links to the original file, of the form http://localhost:8000/[filename]

The extracted text will be shown in Overview. To serve the original files so that the "source file" links work in Oveview, run

    python -m SimpleHTTPServer

from the same directory where you ran docs2csv from (file URLs are relative)


