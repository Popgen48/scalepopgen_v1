process PYTHON_PLOT_SAMPLE_STATS{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_admixture:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/summary_stats/python/plot/sample_stats/", mode:"copy")

    input:
	path(sample_summary)

    output:
    	path("*_snp_counts_mqc.html"), emit: sample_stats_html

    when:
     	task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix
        
        
        
        """

	python3 ${baseDir}/bin/plot_sample_snp_statistics.py ${sample_summary} ${baseDir}/extra/plots/sample_summary_stats.yml ${outprefix}

        cat ${baseDir}/assets/summary_statistics_comments.txt ${outprefix}.html > ${outprefix}_samplewise_snp_counts_mqc.html

	""" 
        

}
