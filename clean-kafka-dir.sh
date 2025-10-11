#!/bin/bash

find ./.docker/volumes/kafka/data -mindepth 1 ! -name '.gitignore' -exec rm -rf {} +
find ./.docker/volumes/kafka/logs -mindepth 1 ! -name '.gitignore' -exec rm -rf {} +
