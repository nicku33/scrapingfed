seq 1996 1999 | parallel -j4 ./pull_year.sh {} federal.register
