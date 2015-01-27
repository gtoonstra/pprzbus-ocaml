#!/bin/bash
make clean
make
sudo ocamlfind remove pprzbus
sudo ocamlfind remove tkpprzbus
sudo ocamlfind remove glibpprzbus
sudo make install

