#!/bin/bash

hugo

aws s3 sync public/ s3://fattybeagle.com --delete --acl public-read --profile fattybeagle

