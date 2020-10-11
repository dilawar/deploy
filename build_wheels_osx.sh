#!/bin/bash
set -e 
set -x

BRANCH=$(cat ./BRANCH)

# Just to be sure on homebrew.
export PATH=/usr/local/bin:$PATH

brew update || echo "Failed to update brew"
brew install gsl  || brew upgrade gsl 
brew install python@3 || echo "Failed to install python3"

# Following are to remove numpy; It is breaking the build on Xcode9.4.
# brew uninstall gdal postgis || echo "Failed to uninstall gdal/postgis"
# brew uninstall numpy || echo "Failed to uninstall numpy"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MOOSE_SOURCE_DIR=`pwd`/moose-core

if [ ! -d $MOOSE_SOURCE_DIR ]; then
    git clone https://github.com/BhallaLab/moose-core -b $BRANCH --depth 10
fi
cd moose-core && git pull

WHEELHOUSE=$HOME/wheelhouse
rm -rf $WHEELHOUSE && mkdir -p $WHEELHOUSE

# Current version 0.7.4 seems to be broken with python3.7 .
# See https://travis-ci.org/BhallaLab/deploy/jobs/435219820
/usr/local/bin/python3 -m pip install delocate 
DELOCATE_WHEEL=/usr/local/bin/delocate-wheel

# Always prefer brew version.
PYTHON=/usr/local/bin/python3

if [ ! -f $PYTHON ]; then
    echo "Not found $PYTHON"
    continue
fi


$PYTHON -m pip install setuptools --upgrade --user
$PYTHON -m pip install wheel --upgrade --user
$PYTHON -m pip install numpy --upgrade --user
$PYTHON -m pip install twine  --upgrade  --user

PLATFORM=$($PYTHON -c "import distutils.util; print(distutils.util.get_platform())")
( 
    cd $MOOSE_SOURCE_DIR
    $PYTHON setup.py build_ext 
    export GSL_USE_STATIC_LIBRARIES=1
    $PYTHON setup.py bdist_wheel --skip-build 
    $DELOCATE_WHEEL -v dist/*.whl -w $WHEELHOUSE
    rm -rf dist/*.whl
)

if [ ! -z "$PYMOOSE_PYPI_PASSWORD" ]; then
    echo "Did you test the wheels? I am uploading anyway ..."
    $PYTHON -m twine upload -u bhallalab -p $PYMOOSE_PYPI_PASSWORD \
        $WHEELHOUSE/pymoose*.whl || echo "Failed to upload to PyPi"
fi
