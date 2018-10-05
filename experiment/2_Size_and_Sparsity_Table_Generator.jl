# include generator file
using DataFrames, CSV

function getInstanceNameForTex(problem::Symbol, params_arr::Any)::String
    INSTANCE_NAME = String(problem)
    for p in 1:numParams[problem]
        INSTANCE_NAME *= "\\_$(params_arr[p])"
    end
    return INSTANCE_NAME
end

mkdir("$(dirname(@__FILE__))/tables")
mkdir("$(dirname(@__FILE__))/tables/csv")
mkdir("$(dirname(@__FILE__))/tables/tex")

param_set = arrayParams()
tex_size = open("$(dirname(@__FILE__))/tables/tex/size_information.tex","w")
tex_sparsity = open("$(dirname(@__FILE__))/tables/tex/sparsity_information.tex","w")

for prob in problem
    df_size = DataFrame(instance=Any[], cont1=Any[], bin1=Any[], int1=Any[], cont2=Any[], bin2=Any[], int2=Any[], cont=Any[], bin=Any[], int=Any[], rows=Any[], cols=Any[])
    df_sparsity = DataFrame(instance=Any[], sparsity_A=Any[], sparsity_W=Any[], sparsity_T=Any[], sparsity_total=Any[])
    instance_name_for_tex = Any[]
    for params_arr in param_set[prob]
        println("Analyzing instance: $(getInstanceName(prob,params_arr))")
        push!(instance_name_for_tex, getInstanceNameForTex(prob,params_arr))
        model = getModel(prob, params_arr)
        sz = getSize(model)
        sp = getSparsity(model)
        tempv_size = Any[]
        tempv_sparsity = Any[]
        push!(tempv_size, getInstanceName(prob, params_arr))
        push!(tempv_size, sz.nCont1)
        push!(tempv_size, sz.nBin1)
        push!(tempv_size, sz.nInt1)
        push!(tempv_size, sz.nCont2)
        push!(tempv_size, sz.nBin2)
        push!(tempv_size, sz.nInt2)
        push!(tempv_size, sz.nCont)
        push!(tempv_size, sz.nBin)
        push!(tempv_size, sz.nInt)
        push!(tempv_size, sz.nRow)
        push!(tempv_size, sz.nCol)

        push!(tempv_sparsity, getInstanceName(prob, params_arr))
        push!(tempv_sparsity, round(sp.sparsity_A*100, 2))
        push!(tempv_sparsity, round(sp.sparsity_W*100, 2))
        push!(tempv_sparsity, round(sp.sparsity_T*100, 2))
        push!(tempv_sparsity, round(sp.sparsity*100, 2))

        push!(df_size,tempv_size)
        push!(df_sparsity,tempv_sparsity)
    end
    # store .csv files
    CSV.write("$(dirname(@__FILE__))/tables/csv/size_information_$(String(prob)).csv" , df_size)
    CSV.write("$(dirname(@__FILE__))/tables/csv/sparsity_information_$(String(prob)).csv" , df_sparsity)

    # write and store size_information.tex files
    println(tex_size, "\\begin{table}[H] ")
    println(tex_size, "  \\centering ")
    lc = lowercase(String(prob))
    println(tex_size, "  \\caption{\\$lc: Instance size} ")
    println(tex_size, "  \\label{table:instance_size_info_$lc} ")
    println(tex_size, "  \\Rotatebox{90}{\% """)
    println(tex_size, "    	\\begin{tabular}{|c|ccc|ccc|ccccc|} ")
    println(tex_size, "        	\\hline ")
    println(tex_size, "          & \\multicolumn{3}{c|}{1st stage} & \\multicolumn{3}{c|}{2nd stage (single scenario)} & \\multicolumn{5}{c|}{Total}      \\\\ \\cline{2-12} ")
    println(tex_size, " 			Instance      & cont      & bin      & int     & cont            & bin            & int           & cont & bin & int  & rows & cols \\\\ \\hline ")
    for ln in 1:size(df_size)[1]
        println(tex_size, "            $(instance_name_for_tex[ln]) & $(df_size[ln,2]) & $(df_size[ln,3]) & $(df_size[ln,4]) & $(df_size[ln,5]) & $(df_size[ln,6]) & $(df_size[ln,7]) & $(df_size[ln,8]) & $(df_size[ln,9]) & $(df_size[ln,10]) & $(df_size[ln,11]) & $(df_size[ln,12]) \\\\ ")
    end
    println(tex_size, "           \\hline ")
    println(tex_size, "        \\end{tabular} ")
    println(tex_size, "  } ")
    println(tex_size, "\\end{table} ")
    println(tex_size, "\\pagebreak  ")
    println(tex_size, "")

    # write and store sparsity_information.tex files
    println(tex_sparsity, "\\begin{table}[H]")
	println(tex_sparsity, "	\\centering")
	lc = lowercase(String(prob))
	println(tex_sparsity, " \\caption{\\$lc: Instance sparsity} ")
	println(tex_sparsity, "  \\label{table:instance_sparsity_info_$lc} ")
	println(tex_sparsity, "	 \\begin{tabular}{|c|cccc|}")
	println(tex_sparsity, "  \\hline ")
	println(tex_sparsity, "  & \\multicolumn{4}{c|}{Sparsity (\\%)}  \\\\ \\cline{2-5}")
	println(tex_sparsity, "	 Instance      & block A & block W & block T & Total \\\\ \\hline")
	for ln in 1:size(df_sparsity)[1]
		println(tex_sparsity, "            $(instance_name_for_tex[ln]) & $(df_sparsity[ln,2]) & $(df_sparsity[ln,3]) & $(df_sparsity[ln,4]) & $(df_sparsity[ln,5]) \\\\ ")
	end
	println(tex_sparsity, "           \\hline ")
    println(tex_sparsity, "        \\end{tabular} ")
    println(tex_sparsity, "  } ")
    println(tex_sparsity, "\\end{table} ")
    println(tex_sparsity, "")
end
close(tex_size)
close(tex_sparsity)
