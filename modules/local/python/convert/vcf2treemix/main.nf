process PYTHON_CONVERT_VCF2TREEMIX{

    tag { "convert_vcf_to_treemix_input_${meta.id}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py310h41dec4a_0':
        'quay.io/biocontainers/pysam:0.22.0--py310h41dec4a_0' }"
    publishDir("${params.outdir}/treemix/input_files/", mode:"copy")

    input:
        tuple val(meta), file(vcf), file(idx), file(map_file)
        val(is_vcf)

    output:
        path("*treemixIn*"), emit: treemix_in

    when:
        task.ext.when == null || task.ext.when

    script:
        args = is_vcf == true ? "-o "+meta.id+" -O t ":" -o "+meta.id+" -O z"
        //args = is_vcf == true ? "-o "+meta.id+" -c "+meta.id+" -O t ":" -o "+meta.id+" -O z"

        """

	python3 ${baseDir}/bin/vcf_to_treemix.py -v ${vcf} -m ${map_file} ${args}


        """ 

}
