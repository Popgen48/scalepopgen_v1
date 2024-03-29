import sys

if sys.version_info < (3, 8):
    raise RuntimeError("This package requres Python 3.7+")

import argparse
import re
import gzip
from pysam import VariantFile
from collections import OrderedDict
from util import prepare_sample_pop_dict


class VcfToTreemix:
    def __init__(self, vcf_file, sample_map, out_prefix, out_mode, contig):
        self.vcf_file = VariantFile(vcf_file)
        self.sample_map = sample_map
        self.out_prefix = out_prefix
        self.out_mode = out_mode
        self.contig = contig
        self.chrom_cord_dict = {}

    def process_sample_map(self):
        self.sample_pop_dict = prepare_sample_pop_dict(self.sample_map, 0)
        self.pop_list = prepare_sample_pop_dict(
            self.sample_map, 1
        )  ##check that the output order of the elements inside this list remains the same, very important!!!!

    # read header of the vcf and store chrom and its size in chrom_cord_dict
    # structure, {chrm1:[[1,158368000]]}

    def populate_whole_chrom_cord_dict(self):
        for rec in self.vcf_file.header.records:
            if (str(rec)).startswith("##contig"):
                pattern = re.compile(r"ID\=([^,]*),length=([0-9]+)")
                match = re.findall(pattern, str(rec))
                if len(match) > 0:
                    chrom = match[0][0]
                    if not self.contig:
                        if chrom != "":
                            self.chrom_cord_dict[chrom] = [[1, int(match[0][1])]]
                    elif chrom == self.contig:
                            self.chrom_cord_dict[chrom] = [[1, int(match[0][1])]]
                    else:pass
                else:
                    pattern = re.compile(r"ID\=([^,]*)>")
                    match = re.findall(pattern, str(rec))
                    chrom = match[0]
                    self.chrom_cord_dict[chrom] = [[1,1000000000]]


    def readVcfRecords(self):
        self.process_sample_map()
        self.populate_whole_chrom_cord_dict()
        if self.out_mode == "z":
            dest = gzip.open(self.out_prefix + "_treemixIn.gz", "wb")
            dest.write(" ".join(self.pop_list).encode())
        else:
            dest = open(self.out_prefix + "_treemixIn.txt", "w")
            dest.write(" ".join(self.pop_list))
        for chrom in self.chrom_cord_dict:
            chromRegions = self.chrom_cord_dict[chrom]
            for region in chromRegions:
                start = int(region[0])
                end = int(region[1])
                for rec in self.vcf_file.fetch(chrom, start, end):
                    dest.write("\n".encode()) if self.out_mode == "z" else dest.write(
                        "\n"
                    )
                    treemixDict = OrderedDict()
                    refAllele = 0
                    altAllele = 0
                    for pop in self.pop_list:
                        treemixDict[pop] = [0, 0]
                    for sample in self.sample_pop_dict:
                        gt = rec.samples[sample]["GT"]
                        treemixDict[self.sample_pop_dict[sample]][0] += gt.count(0)
                        treemixDict[self.sample_pop_dict[sample]][1] += gt.count(1)
                        refAllele += gt.count(0)
                        altAllele += gt.count(1)
                    for pop in treemixDict:
                        if refAllele >= altAllele:
                            writeRecord = (
                                str(treemixDict[pop][0])
                                + ","
                                + str(treemixDict[pop][1])
                            )
                        else:
                            writeRecord = (
                                str(treemixDict[pop][1])
                                + ","
                                + str(treemixDict[pop][0])
                            )
                        dest.write(
                            writeRecord.encode()
                        ) if self.out_mode == "z" else dest.write(writeRecord)
                        dest.write(
                            " ".encode()
                        ) if self.out_mode == "z" else dest.write(" ")
        dest.write("\n".encode()) if self.out_mode == "z" else dest.write("\n")
        dest.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="python script to convert vcf file to treemix format",
        epilog="author: Maulik Upadhyay (Upadhyay.maulik@gmail.com)",
    )
    requiredNamed = parser.add_argument_group("required name arguments")
    requiredNamed.add_argument(
        "-v", "--vcfF", metavar="File", help="vcf file", required=True
    )
    requiredNamed.add_argument(
        "-m", "--sample_map", metavar="File", help="sample map file", required=True
    )
    requiredNamed.add_argument(
        "-o", "--out_prefix", metavar="Str", help="prefix of output file", required=True
    )
    parser.add_argument(
        "-O",
        "--out_mode",
        metavar="Str",
        help="mode of output file (compressed:z, uncompressed:t)",
        default="t",
        required=True,
    )
    parser.add_argument(
        "-c",
        "--chrom",
        metavar="Str",
        help="chromosom id for which treemix input file is to be prepared",
        default=None,
        required=False,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        # sys.exit(1)
    else:
        VcfTreemix = VcfToTreemix(
            args.vcfF,
            args.sample_map,
            args.out_prefix,
            args.out_mode,
            args.chrom,
        )
        VcfTreemix.readVcfRecords()
