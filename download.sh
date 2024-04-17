#!/bin/bash

# 数组包含所有 GitHub 仓库链接
github_links=(
    "https://github.com/fiber-miniapp/ccs-qcd"
	"https://github.com/fiber-miniapp/ffvc-mini"
	"https://github.com/fiber-miniapp/nicam-dc-mini"
	"https://github.com/fiber-miniapp/mVMC-mini"
	"https://github.com/fiber-miniapp/ngsa-mini"
	"https://github.com/fiber-miniapp/ntchem-mini"
	"https://github.com/fiber-miniapp/ffb-mini"
	"https://github.com/ECP-copa/ExaMiniMD"
	"https://github.com/LLNL/Quicksilver"
	"https://github.com/ECP-copa/ExaMPM"
	"https://github.com/lanl/SNAP"
	"https://github.com/ECP-copa/Cabana.git"
	"https://github.com/E3SM-Project/codesign-kernels.git"
	"https://github.com/jkwack/GAMESS_RI-MP2_MiniApp.git"
	"https://github.com/debog/hypar.git"
	"https://github.com/spiral-software/fftx.git"
	"https://github.com/AMReX-Codes/IAMR.git"
	"https://github.com/ORNL/RIOPA.jl.git"
	"https://github.com/LLNL/goulash.git"
	"https://github.com/flexflow/FlexFlow/"
	"https://github.com/SandiaMLMiniApps/miniGAN"
	"https://github.com/LLNL/CRADL"
	"https://github.com/mlcommons/training"
	"https://github.com/mlcommons/inference"
	"https://github.com/mlcommons/storage"
	"https://github.com/SciML/SciMLBenchmarks.jl"
	"https://github.com/hpcg-benchmark/hpcg.git"
)

# 循环遍历数组中的每个链接并执行 git clone 命令来下载仓库
for link in "${github_links[@]}"
do
	git submodule add "$link"
done

git submodule init 


