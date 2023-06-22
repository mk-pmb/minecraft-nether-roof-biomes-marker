#!/bin/sed -nurf
# -*- coding: UTF-8, tab-width: 2 -*-

s~confirm_we_done=~\n~
/\n/{
  s~^.*\n~dura:~
  s~(<[0-9]+) .*~\1~
  N
  s~(<[0-9]+)\nD: Confirmed after ([0-9]+) sec\.$~=\2\t\t\1~
  p
}
 