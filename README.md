docs2csv
========

Scan a folder of document files of all types and extract the text into a CSV suitable for import into Overview.

First you will need to install:
  - Poppler, for pdfimages 
    On Linux, use aptitude, apt-get or yum:

    ```aptitude install poppler-utils poppler-data```

    On the Mac, you can install from source or use MacPorts:

    ```sudo port install poppler | brew install poppler```

  - Tesseract, for OCR

    [aptitude | port | brew] install [tesseract | tesseract-ocr] 

    Without Tesseract installed, you'll still be able to extract text from documents, but you won't be able to automatically OCR them.

Usage: 
    ruby docs2csv.rb [-l] [-r] [-o] [-f] dir-full-of-PDFs output.csv

    -l, --list                       Only list files, do not process
    -r, --recurse                    Scan directory recursively
    -o, --ocr                        OCR pdfs that do not contain text
    -f, --force-ocr                  Force OCR on all pdfs

The output file will contain the extracted text from each file, plus URL links to the original file, of the form http://localhost:8000/[filename]

To serve these files so that the "source file" links work in Oveview, run

    ```python -m SimpleHTTPServer```

from the same directory where you ran docs2csv from (file URLs are relative)


