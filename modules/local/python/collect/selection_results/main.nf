process PYTHON_COLLECT_SELECTION_RESULTS{

    tag { "${pop}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/prepare_manhattan_input:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/selection/genomewide_results/${method}/${pop_u}", mode:"copy")

    input:
        tuple val(pop), path(results), path(chrom_length_map)
        val(method)

    output:
        tuple val(meta), path("${pop_u}_${method}.out"), emit: txt
        tuple val(meta), path("${pop_u}_${method}.cutoff"), emit: cutoff
        
    
    script:
        pop_u = (method == "sweepfinder2" || method == "ihs") ? pop.id: pop
        window_size = params.window_size
        perc_threshold = params.perc_threshold
        outfile = pop_u+"_"+method
        meta = [:]
        meta.id = pop_u
        l_chrom_map = "none"
        if(chrom_length_map){
                l_chrom_map = chrom_length_map
        }

        """
        
        python3 ${baseDir}/bin/create_manhattanplot_input.py ${window_size} ${perc_threshold} ${method} ${pop_u} ${l_chrom_map} ${outfile} ${results}
        
        
        """ 

}
