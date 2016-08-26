# script that can concatenate the values from a specific colum in different
# files to one master file. The script will make sure only the same rows are
# paired. Supply files names as globbing pattern.
import glob
import os
import argparse
from collections import defaultdict
from collections import Set
from argparse import RawTextHelpFormatter


#for help see message displayed
desc = 'Concatenate a couple of tab delimted files based on the colum index \
(0 based) to one master table file.\nUse c 1 for htseq-count, c 4 for \
kallisto and c 5 RSEM TPM. See the respective files if you want to \
concatenate other data. The file input name needs do be sourrounded by ""\
quotation marks.'

parser = argparse.ArgumentParser(description=desc,formatter_class=RawTextHelpFormatter)
parser.add_argument('-s', '--sort', default = True, \
                    help = 'sort the output file', action = 'store_true')
parser.add_argument('-n', '--no-sort', default = False, dest = 'sort', \
                    help = 'sort the output file', action = 'store_false') \
                    #TODO: implement conditional sorting
parser.add_argument('-c', '--columns', dest = 'columns', metavar = 'c', \
                    type = int, help = 'Index of colum to be parsed (0 based)',\
                    required = True)
parser.add_argument('-i', '--input', dest = 'input', metavar = 'i', type = str,\
                    help = 'name of the input file, supports globbing. \
                    Requires quotes around the value)', \
                    required = True)
parser.add_argument('-o', '--output', dest = 'output', metavar = 'o', \
                    type = str, help = 'name of the output file', \
                    required = True)
args = parser.parse_args()

d = defaultdict(list)

def processFiles(d, directory):
    """Function that processes RNA-seq quantification files and returns a
    dictionary with <sample_name>, <data> as key value pair.
    """
    header=[]
    header.append('id')
    filenames = getFileNames(directory)

    for name in filenames:
        print("Processing: " + name)
        if isFileEmpty(name):
            print('Warning file is empty: ' + name)
            continue
        sampleName = generateColHeader(name)
        d = processFile(name, d)
        header.append(sampleName)
    return header, d

def isFileEmpty(file):
    """Function that checks a file contains data.
    """
    return (os.stat(file).st_size == 0)

def getFileNames(directory):
    """Function that returns the full paths of files that match a globbing
    pattern.
    """
    filenames = glob.glob(directory)
    return filenames

def generateColHeader(filename):
    """Function that processes kallisto, htseq count and rsem files and returns
    the sample name.
    """
    kallisto_str = '_abundance.tsv'
    htseq_count = '.htseq-count'
    rsem_str = '.genes.results'
    f = filename.split('/')[-1]

    if kallisto_str in f:
        name = file[:-len(kallisto_str)]
    elif htseq_count in f:
        name = file[:-len(htseq_count)]
    elif rsem_str in f:
        name = file[:-len(rsem_str)]
    else:
        name = file.split('.')[0]
    return name

def processFile(filename, d):
    """Function that processes a file and returns a dictionary containing
    <sample_name>, <data> as key, value pair.
    """
    fin = open(filename,'r')
    entrys =[]
    for line in fin:
        cols = processLine(line)
        entrys.append(cols)
    fin.close()
    d = addToDict(entrys, d)
    return d

def processLine(line):
    """Function that processes a line of tab seperated text and returns a tuple
    of strings. The function takes the column number specified in the command
    line arguments, returns its value and the value of the 1st column (gene name).
    """
    line = line.strip('\n')
    cols = line.split('\t')

    id_col = 0
    indices = [id_col, value_col]
    values = [cols[i] for i in indices]
    #__ denotes not genes but meta info from the mapping in htseq count
    #(ambigious, unmapped etc). if a line contains this delimter add a xx in
    #front, so that when the file gets sorted it comes out last.
    if '__' in values[id_col]:
        values[id_col] = 'xx' + values[id_col]
    return tuple(values)

def addToDict(entries,d):
    for k, v in entries:
        d[k].append(v)
    return d

def writeToFile(filename, header, d):
    """Function that writes supplied data to a file, including the supplied
    header.
    """
    fout = open(filename,'w')
    h = '\t'.join(header) + '\n'
    fout.write(h)

    for key in sorted(d):
        values = d[key]
        line = key +'\t'+ '\t'.join(values) + '\n'
        fout.write(line)
    fout.close()

global sort
global value_col

value_col = args.columns
sort = args.sort
inputPattern = args.input
outputFile = args.output

header, d = processFiles(d, inputPattern)
writeToFile(outputFile,header,d)
