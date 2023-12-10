process VCFTOOLS_FILTER_SITES{

    tag { "filter_sites_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    publishDir("${params.outdir}/vcftools/sites_filtering/", mode:"copy")

    input:
        tuple val(meta), file(f_vcf)

    output:
        tuple val(meta), path ("*filt_sites.vcf.gz"), emit: s_meta_vcf
        path("*.log"), emit: log
    
    script:
        def opt_arg = ""
        chrom = meta.id
        prefix = f_vcf.getSimpleName()
        if(params.maf >= 0){
            opt_arg = opt_arg + " --maf "+params.maf
        }
        if(params.min_meanDP >= 0){
            opt_arg = opt_arg + " --min-meanDP "+params.min_meanDP
        }
        if(params.max_meanDP >= 0){
            opt_arg = opt_arg + " --max-meanDP "+params.max_meanDP
        }
        if(params.hwe >= 0){
            opt_arg = opt_arg + " --hwe "+params.hwe
        }
        if(params.max_missing >= 0){
            opt_arg = opt_arg + " --max-missing "+params.max_missing
        }
        if(params.minQ >= 0){
            opt_arg = opt_arg + " --minQ "+params.minQ
        }
        if(params.rem_snps){
            opt_arg = opt_arg + " --exclude-positions "+params.rem_snps
        }

        """
        
        vcftools --gzvcf ${f_vcf} ${opt_arg} --recode --stdout |sed "s/\\s\\.:/\t.\\/.:/g"|gzip -c > ${prefix}_filt_sites.vcf.gz


        cp .command.log ${prefix}_filter_sites.log


        """ 
}