#!/bin/bash
set -e   # exit on any error
# set -x   # echo to terminal as you execute

YEAR=$1
TABLE=$2   # dataset.table 
PERPAGE=1000
PAGE=1
TOTAL_PAGES=$(curl -s "https://www.federalregister.gov/api/v1/documents.json?per_page=$PERPAGE&page=$PAGE&order=executive_order_number&conditions%5Bpublication_date%5D%5Byear%5D=$YEAR" | jq ".total_pages")
# this can fail tho

if ( "$TOTAL_PAGES" == "50")
then
    echo "More than 50,000 records, exiting"
    exit 1
fi

OUTPUT=$YEAR.json
rm -f $OUTPUT # -f to avoid error if not there

# debug
# TOTAL_PAGES=2
# PERPAGE=10

for PAGE in $(seq 1 $TOTAL_PAGES)
do
    echo "$(date) Loading page $PAGE of $TOTAL_PAGES for year $YEAR"
    curl -s "https://www.federalregister.gov/api/v1/documents.json?per_page=$PERPAGE&page=$PAGE&order=executive_order_number&conditions%5Bpublication_date%5D%5Byear%5D=$YEAR" | jq --compact-output '.results[]'  >> $OUTPUT 
done

gzip $OUTPUT

bq load --ignore_unknown_values --source_format=NEWLINE_DELIMITED_JSON $TABLE $OUTPUT.gz schema.json

rm -f $OUTPUT.gz
