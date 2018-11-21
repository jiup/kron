#!/bin/sh
rm -rf kron_test
mkdir kron_test
cd kron_test
kron init
touch a b c
kron add a
kron commit -m 'add a'
echo "============================================"
kron add b
kron unstage a
kron status
echo "============================================"
kron commit -m 'add b remove a from tracking list'
kron branch add kron1
kron checkout kron1
kron heads
echo "============================================"
echo 'there are something in c to show cat method' > c
kron add c
kron commit -m 'add c in kron1 branch'
echo "============================================"
kron cat c
echo "============================================"
kron ls
echo "============================================"
kron checkout master
kron add a
kron commit -m 'add a in master'
kron ls
echo "============================================"
kron merge kron1
kron logs