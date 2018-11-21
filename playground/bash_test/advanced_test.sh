#!/bin/sh
if [ -d 'kron_test' ]; then
    rm -rf kron_advanced_test
    mkdir kron_advanced_test
    cd kron_advanced_test
    kron clone ../kron_test
    kron branch
    kron branch add kron2
    kron checkout kron2
    touch d
    kron add d
    kron commit -m'add d in kron_advanced_test in branch kron2'
    cd  ../kron_test
    kron checkout kron1
    touch f
    kron add f
    kron commit -m 'add f in kron_test in branch kron1'
    cd ../kron_advanced_test
    kron pull ../kron_test kron1
    kron branch
    kron logs
else
   echo 'please run basic_test.sh first'
fi