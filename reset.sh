#!/bin/bash
for i in $(ls ./done-*); do mv $i $(echo $i | sed 's/done-//'); done
