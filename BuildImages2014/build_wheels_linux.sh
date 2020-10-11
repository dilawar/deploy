#!/usr/bin/env bash

set -e -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NPROC=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
NUM_WORKERS=$((NPROC+1))

if [ "$TRAVIS" == "true" ]; then
    NUM_WORKERS=3
fi
MAKEOPTS="-j$NUM_WORKERS"

# Place to store wheels.
WHEELHOUSE=${1-$HOME/wheelhouse}
echo "Path to store wheels : $WHEELHOUSE"
mkdir -p $WHEELHOUSE

# tag on github and revision number. Make sure that they are there.
[ -f ./BRANCH ] || echo "master" >> ./BRANCH
BRANCH=$(cat ./BRANCH)
VERSION="3.2.0.dev$(date +%Y%m%d)"

echo "Building version $REVISION, from branch $BRANCH"

GSL_STATIC_LIBS="/usr/local/lib/libgsl.a;/usr/local/lib/libgslcblas.a"

if [ ! -f /usr/local/lib/libgsl.a ]; then 
    #wget --no-check-certificate ftp://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz 
    curl -O https://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz
    tar xvf gsl-2.4.tar.gz 
    cd gsl-2.4 
    CFLAGS=-fPIC ./configure --enable-static && make $MAKEOPTS
    make install 
    cd ..
fi 

MOOSE_SOURCE_DIR=$SCRIPT_DIR/moose-core

if [ ! -d $MOOSE_SOURCE_DIR ]; then
    git clone https://github.com/dilawar/moose-core --depth 10 --branch $BRANCH
fi

# Try to link statically.
CMAKE=/usr/bin/cmake3

# Build wheels here.
for PYV in 38 37m 36m; do
    PYDIR=/opt/python/cp${PYV}-cp${PYV}
    PYVER=$(basename $PYDIR)
    mkdir -p $PYVER
    (
        cd $PYVER
        echo "Building using $PYDIR in $PYVER"
        PYTHON=$(ls $PYDIR/bin/python?.?)
        $PYTHON -m pip install numpy twine
        $PYTHON -m pip install matplotlib
        $PYTHON -m pip install twine
        $PYTHON -m pip uninstall pymoose -y || echo "No pymoose"
	git pull || echo "Failed to pull $BRANCH"
        $CMAKE -DPYTHON_EXECUTABLE=$PYTHON  \
            -DGSL_STATIC_LIBRARIES=$GSL_STATIC_LIBS \
            -DVERSION_MOOSE=$VERSION \
            ${MOOSE_SOURCE_DIR}
        make  $MAKEOPTS
        
        # Now build bdist_wheel
        cd python
        cp setup.cmake.py setup.py
        $PYTHON -m pip wheel . -w $WHEELHOUSE 
        echo "Content of WHEELHOUSE"
        ls -lh $WHEELHOUSE/*.whl
    )
done

# List all wheels.
ls -lh $WHEELHOUSE/*.whl

# now check the wheels.
for whl in $WHEELHOUSE/pymoose*.whl; do
    auditwheel show "$whl"
done

echo "Installing before testing ... "

/opt/python/cp36-cp36/bin/pip install $WHEELHOUSE/pymoose-$VERSION-py3-none-any.whl
/opt/python/cp38-cp38/bin/pip install $WHEELHOUSE/pymoose-$VERSION-py3-none-any.whl
for PYV in 38 36; do
    /opt/python/cp${PYV}-cp${PYV}/bin/pip install $WHEELHOUSE/pymoose-$VERSION-py3-none-any.whl
    PYDIR=/opt/python/cp${PYV}-cp${PYV}
    PYTHON=$(ls $PYDIR/bin/python?.?)
    $PYTHON -c 'import moose; print(moose.__version__)'
done
