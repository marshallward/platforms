#!/bin/bash -x                                     
#machine_name="gaea" 
#platform="intel18"
#machine_name="tiger" 
#platform="intel18"
machine_name="googcp" 
platform="intel19"
#machine_name = "ubuntu"
#platform     = "pgi18"                                             
#machine_name="ubuntu" 
#platform="gnu7"
#machine_name = "gfdl-ws" 
#platform     = "intel15"
#machine_name = "gfdl-ws"
#platform     = "gnu6" 
#machine_name = "theta"   
#platform     = "intel16"
machine_name="lscsky50"
platform="intel19up2" #"intel18_avx1" # "intel18up2_avx1" 

target="prod_avx512sky" #"debug-openmp"       

usage()
{
    echo "usage: linux-build-mom6solo.bash -m googcp -p intel19 -t prod"
}

# parse command-line arguments
while getopts "m:p:t:h" Option
do
   case "$Option" in
      m) machine_name=${OPTARG};;
      p) platform=${OPTARG} ;;
      t) target=${OPTARG} ;;
      h) usage ; exit ;;
   esac
done

rootdir=`dirname $0`
abs_rootdir=`cd $rootdir && pwd`


#load modules              
source $MODULESHOME/init/bash
source $rootdir/$machine_name/$platform.env
. $rootdir/$machine_name/$platform.env

makeflags="NETCDF=3"

if [[ "$target" =~ "openmp" ]] ; then 
   makeflags="$makeflags OPENMP=1" 
fi

if [[ $target =~ "repro" ]] ; then
   makeflags="$makeflags REPRO=1"
fi

if [[ $target =~ "prod" ]] ; then
   makeflags="$makeflags PROD=1"
fi

if [[ $target =~ "debug" ]] ; then
   makeflags="$makeflags DEBUG=1"
fi

if [[ $target =~ "sky" ]] ; then
   makeflags="$makeflags AVX=sky"
fi
srcdir=$abs_rootdir/../src

mkdir -p build/$machine_name-$platform/shared/$target
pushd build/$machine_name-$platform/shared/$target   
rm -f path_names                       
$srcdir/mkmf/bin/list_paths $srcdir/FMS
$srcdir/mkmf/bin/mkmf -t $abs_rootdir/$machine_name/$platform.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF -DSPMD" path_names

make $makeflags libfms.a         

if [ $? -ne 0 ]; then
   echo "Could not build the FMS library!"
   exit 1
fi

popd

mkdir -p build/$machine_name-$platform/ocean_only/$target
pushd build/$machine_name-$platform/ocean_only/$target
rm -f path_names
$srcdir/mkmf/bin/list_paths $srcdir/MOM6/{config_src/dynamic,config_src/solo_driver,src/{*,*/*}}/
$srcdir/mkmf/bin/mkmf -t $abs_rootdir/$machine_name/$platform.mk -o "-I../../shared/$target" -p MOM6 -l "-L../../shared/$target -lfms" -c '-Duse_libMPI -Duse_netCDF -DSPMD' path_names

make $makeflags MOM6
