#!/bin/sh

set -e -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NPROC=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
NUM_WORKERS=$((NPROC-1))

if [ "$TRAVIS" == "true" ]; then
    NUM_WORKERS=2
fi
MAKEOPTS="-j$NUM_WORKERS"

# Place to store wheels.

WHEELHOUSE=${1-$HOME/wheelhouse}
echo "Path to store wheels : $WHEELHOUSE"
mkdir -p $WHEELHOUSE

# tag on github and revision number. Make sure that they are there.
[ -f ./BRANCH ] || echo "master" > ./BRANCH
BRANCH=$(cat ./BRANCH)
VERSION="3.2dev$(date +%Y%m%d)"

# Create a test script and upload.
TESTFILE=/tmp/test.py
cat <<EOF >$TESTFILE
import moose
import moose.utils as mu
print( moose.__version__ )
moose.reinit()
moose.start( 1 )
EOF


echo "Building version $VERSION, from branch $BRANCH"

if [ ! -f /usr/local/lib/libgsl.a ]; then 
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

# GSL will be linked statically.
GSL_STATIC_LIBS="/usr/local/lib/libgsl.a;/usr/local/lib/libgslcblas.a"

PY2=/opt/python/cp27-cp27m/bin/python2.7
$PY2 -m pip install numpy==1.14 matplotlib==2.2.4

PY3=/opt/python/cp38-cp38/bin/python3.8
$PY3 -m pip install numpy matplotlib

# Build wheels here.
for PY in $PY3 $PY2; do
  (
  BUILDIR=$(basename $PY)
  mkdir -p $BUILDIR
  cd $BUILDIR
  echo "Building using in $PY"
  git pull || echo "Failed to pull $BRANCH"
  cmake -DPYTHON_EXECUTABLE=$PY  \
    -DGSL_STATIC_LIBRARIES=$GSL_STATIC_LIBS \
    -DVERSION_MOOSE=$VERSION ${MOOSE_SOURCE_DIR}
  make  $MAKEOPTS
  # Now build bdist_wheel
  cd python
  cp setup.cmake.py setup.py
  $PY -m pip wheel . -w $WHEELHOUSE 
  echo "Content of WHEELHOUSE"
  ls -lh $WHEELHOUSE/*.whl
  )
done

$PY3 -m pip install twine auditwheel

# List all wheels.
ls -lh $WHEELHOUSE/*.whl

# now check the wheels.
for whl in $WHEELHOUSE/pymoose*.whl; do
    auditwheel show "$whl"
    # Fix the tag and remove the old wheel.
    auditwheel repair "$whl" -w $WHEELHOUSE && rm -f "$whl"
done

echo "Installing before testing ... "
$PY2 -m pip install $WHEELHOUSE/pymoose-$VERSION-py2-none-any.whl
$PY3 -m pip install $WHEELHOUSE/pymoose-$VERSION-py3-none-any.whl

for PY in $PY3 $PY2; do
    $PY -c 'import moose; print(moose.__version__)'
done

# Now upload the source distribution.
cd $MOOSE_SOURCE_DIR 
rm -rf dist
$PY38 setup.py sdist 
$TWINE upload dist/pymoose*.tar.gz \
  --user bhallalab --password $PYMOOSE_PYPI_PASSWORD \
  --skip-existing || echo "Failed to upload source distribution."
