process GAWK_GENERATE_COLORS{

    tag { "generating colors for plotting" }
    label "process_single"
    conda "conda-forge::gawk==5.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/", mode:"copy")

    input:
        path(sample_map)
        path(f_pop_color)

    output:
        path ("pop_sc_color.map"), emit: color
        path "versions.yml", emit: versions
   
    script:
        
        //f_pop_color = params.color_map

        if( f_pop_color == [] ){


        """

    awk '{if(NF==6){pop_count[\$1]++;next}else;pop_count[\$2]++;next}END{for(pop in pop_count){print pop,pop_count[pop]}}' ${sample_map} > f_pop_count.map

    awk 'NR==FNR{color[NR]=\$1;next}{print \$1,\$2,color[FNR]}' ${baseDir}/extra/hexcolorcodes.txt f_pop_count.map > pop_sc_color.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS
        

        """ 
        }

        else{
        

        """

        awk '{if(NF==6){pop_count[\$1]++;next}else;pop_count[\$2]++;next}END{for(pop in pop_count){print pop,pop_count[pop]}}' ${sample_map} > f_pop_count.map

        awk 'NR==FNR{color[\$1]=\$2;next}\$1 in color{print \$1,\$2,color[\$1]}' ${f_pop_color} f_pop_count.map > pop_sc_color.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """

        }
}
