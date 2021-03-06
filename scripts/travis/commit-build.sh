#!/usr/bin/env bash
#
# - Compile in debug mode
# - Run unit and integration tests only
# - Measure code coverage
#
echo "*************************** Performing a COMMIT build"
set -e;

mkdir -p build;
pushd build;

if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    # build
    cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON -DENABLE_COVERAGE=ON -DCMAKE_INSTALL_PREFIX=/usr -DCHECK_QML_SYNTAX=ON ..;
    make -j2;

    # run tests
    make test;
fi

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    # build
    cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON -DCHECK_QML_SYNTAX=ON ..;
    make -j2;

    # run tests
    make test;
fi
