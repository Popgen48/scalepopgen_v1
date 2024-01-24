process GAWK_PREPARE_RECOMB_MAP_SELSCAN{

    tag { "${chrom}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/selection/selscan/input_files", mode:"copy")

    input:
        tuple val( meta ), path( vcf )

    output:
        tuple val( meta ), path ( "${prefix}.map" ), emit: meta_selscanmap

    script:

        def cm_to_bp = 1000000
        prefix = vcf.baseName
        
        """
                        

         zcat ${vcf}|awk '\$0!~/#/{sum++;print \$1,"locus"sum,\$2/${cm_to_bp},\$2}' > ${prefix}.map


        """ 
}