from file_stream.source import Dir, CsvReader
from file_stream.writer import CsvWriter

fdir = '' # Dictionary
out_path = '' # Output
p = Dir(fdir, ['csv', 'CSV']) | CsvReader() | CsvWriter(out_path, p.fieldnames)
p.output()

