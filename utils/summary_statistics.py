import glob
import argparse
from argparse import RawTextHelpFormatter
from os.path import basename

#for help see message displayed
desc = ('Generates a summary table from RSEM alignment statistics. Use nix style'
        'paths that can be globbed and point towards the from .cnt files as '
        'input.')

parser = argparse.ArgumentParser(description=desc,formatter_class=RawTextHelpFormatter)
parser.add_argument('-i', '--input', dest = 'input', metavar = 'i', type = str,\
                    help = 'name of the input path, supports globbing. \
                    Requires quotes around the value)', \
                    required = True)

parser.add_argument('-o', '--output', dest = 'output', metavar = 'o', \
                    type = str, help = 'name of the output file', \
                    required = True)

args = parser.parse_args()
inputPath = args.input
outputFile = args.output

print("Input path: " + str(inputPath))
print("Output file: " + str(outputFile))

def getFileNames(directory):
    """Function that returns the full paths of files that match a globbing
    pattern.
    """
    filenames = glob.glob(directory)
    return filenames

def readFile(f):
    """Function that all lines in the supplied file.
    """
    print("Parsing file: " + str(f))
    fin = open(f,'r')
    lines = fin.readlines()
    fin.close()
    return lines

def getStatsFromCntFile(lines):
    """Function processes the lines from a RSEM cnt file and returns
    #total reads, #aligned reads, #unique matching reads & #multi mapping reads
    """
    # wanted stats:
    #first two lines contain the wanted
    # total reads (Ntot) (0,3)
    # aligned reads (N1) (0,1)
    # unique matching reads (nUnique) (1,0)
    # multi mapping reads (n) (1,1)

    mat = [l.strip('\n').split(' ') for l in lines[:2]]
    n_tot = mat[0][3]
    n_1 = mat[0][1]
    n_uni =  mat[1][0]
    n_multi = mat[1][1]

    stats = [n_tot,n_1,n_uni,n_multi]
    return '\t'.join(stats)

def getSampleId(f):
    """Returns the sample name of .cnt file
    """
    return basename(f).split('.cnt')[0]

def processCntFile(f,d):
    """Function that reads and processes the  the lines from a RSEM cnt file and
    returns #total reads, #aligned reads, #unique matching reads and #multi
    mapping reads
    """
    sample_id = getSampleId(f)
    lines = readFile(f)
    stats = getStatsFromCntFile(lines)
    if sample_id in d:
        print "Warning: " + sample_id + " occours more than once!"
    d[sample_id]=stats
    return d

def writeToFile(f,d):
    """Function that writes count statistics to a file.
    """
    fout = open(f,'w')
    h="sample\ttotal_reads\taligned_reads\tunique_mapping\tmulti_mapping\n"
    fout.write(h)
    for key in sorted(d):
        v = d[key]
        line = key +'\t'+ v + '\n'
        fout.write(line)
    fout.close()

d = dict()
files = getFileNames(inputPath)
for f in files:
    d = processCntFile(f, d)

writeToFile(outputFile, d)
