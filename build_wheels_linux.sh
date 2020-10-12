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

    # GSL will be linked statically.
    GSL_STATIC_LIBS="/usr/local/lib/libgsl.a;/usr/local/lib/libgslcblas.a"

    cd ..
fi 

MOOSE_SOURCE_DIR=$SCRIPT_DIR/moose-core

if [ ! -d $MOOSE_SOURCE_DIR ]; then
    git clone https://github.com/dilawar/moose-core --depth 10 --branch $BRANCH
fi

# Try to link statically.
GSL_STATIC_LIBS="/usr/local/lib/libgsl.a;/usr/local/lib/libgslcblas.a"

# Build wheels here.
PY36=$(ls /opt/python/cp36-cp36m/bin/python?.?)
PY37=$(ls /opt/python/cp37-cp37m/bin/python?.?)
PY38=$(ls /opt/python/cp38-cp38/bin/python?.?)

# install latest cmake using pip and its location to PATH
$PY38 -m pip install cmake --user
export PATH=/opt/python/cp38-cp38/bin:$PATH

for PYTHON in $PY38 $PY37 $PY36; do
  echo "========= Building using $PYTHON ..."
  $PYTHON -m pip install pip setuptools --upgrade
  $PYTHON -m pip install numpy twine
  $PYTHON -m pip install matplotlib
  $PYTHON -m pip install twine
  # Removing existing pymoose if any.
  $PYTHON -m pip uninstall pymoose -y || echo "No pymoose"

  cd $MOOSE_SOURCE_DIR
  export GSL_USE_STATIC_LIBRARIES=1
  $PYTHON setup.py build_ext 
  $PYTHON setup.py bdist_wheel --skip-build 
  ( 
      echo "Install and test this wheel"
      # NOTE: Not sure why I have to do this. But cant install wheel from build
      # directory.
      cd /tmp
      $PYTHON -m pip install $MOOSE_SOURCE_DIR/dist/*.whl 
      $PYTHON $TESTFILE
      mv $MOOSE_SOURCE_DIR/dist/*.whl $WHEELHOUSE
      rm -rf $MOOSE_SOURCE_DIR/dist/*.whl
  )
done

$PY38 -m pip install twine auditwheel

# List all wheels.
ls -lh $WHEELHOUSE/*.whl
$PY38 -m twine upload $WHEELHOUSE/*.whl \
    --user dilawar --password $PYMOOSE_PYPI_PASSWORD \
    --skip-existing 

# now check the wheels.
for whl in $WHEELHOUSE/pymoose*.whl; do
    auditwheel show "$whl"
    # Fix the tag and remove the old wheel.
    auditwheel repair "$whl" -w $WHEELHOUSE && rm -f "$whl"
done

echo "Installing before testing ... "
$PY38 -m pip install $WHEELHOUSE/pymoose-$VERSION-py3-none-any.whl
$PY38 -c 'import moose; print(moose.__version__)'

# Now upload the source distribution.
set -e
cd $MOOSE_SOURCE_DIR 
rm -rf dist && \
    $PY38 setup.py sdist && \
    $PY38 -m twine upload dist/pymoose*.tar.gz \
        --user dilawar --password $PYMOOSE_PYPI_PASSWORD \
        --skip-existing || echo "Failed to upload source distribution."
set +e
