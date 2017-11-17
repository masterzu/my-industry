#!/bin/bash

# find building with specific resource/climat

# the geography - dont change in time
G=$(get-geography.sh)

test $# == 1 || { cat<<EOT;
Usage $(basename $0) <saison | ressource>

Saison:
$(echo "$G" |awk -F\| '{print $4'}|sort -u)

Ressource:
$(echo "$G" |awk -F\| '{print $5'}|sort -u)

EOT
	exit;
	}

search="$1"

# the buildings - change in time
B=$(get-buildings.sh|sort)

# spell the magic of GNU
join -j 1 -t \| -o 1.1,1.2,1.3,1.4,1.5,1.6,2.4,2.5 <(echo "$B") <(echo "$G" | egrep "$search"|sort )


