sed -i '' 's/\r//g' request.log
cp request.log cold-start-analysis/raw/requests-node-arguments-on.log
