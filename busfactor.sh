#!/bin/bash

echo "There are $(ls $1/debug-*.avi -1 | wc -l) files to triage"

function tweet {
  FILE=$1
  TYPE=$2
  DATE=$(basename $I | cut -d '_' -f 1,2)
  ffmpeg -i ~/busfactor/links/true/to-report/"$TYPE"/$(basename $FILE) -t 2 -ss 00:4 ~/busfactor/gifs/$(basename ${FILE/.avi/})" - $TYPE".gif

  echo "Updating twitter"
  t update -f ~/busfactor/gifs/$(basename ${FILE/.avi/})" - $TYPE".gif "$DATE - $TYPE"
}

for DEBUG in $1/debug-*.avi; do
  while true; do
    replay=0
    I="$(dirname $DEBUG)/$(basename $DEBUG | sed 's/^debug-//' | sed 's/_0\.[0-9]*\.avi/\.avi/')"
    echo $I;
    mpv $DEBUG
    while true; do
#      echo "r) replay, f) false, t) true, d) delete, s) skip, R) report"
      echo "r) replay, f) false, t) true, d) delete, s) sort later, 1) dangerous, 2) entering, 3) inside, 4) exiting"
      read -n 1 c
      case $c in
#	R) while true; do
#	  echo "r) replay, s) sort later, 1) dangerous, 2) entering, 3) inside, 4) exiting"
#	  read -n 1 c
#	  case $c in
	1) export TYPE="Dangerous behaviours with high risk of injury";
	  mv $I ~/busfactor/links/true/to-report/"$TYPE"/; tweet $I "$TYPE" & ;;
	2) export TYPE="Entering intersection on red light";
	  mv $I ~/busfactor/links/true/to-report/"$TYPE"/; tweet $I "$TYPE" & ;;
	3) export TYPE="Inside intersection on red light";
	  mv $I ~/busfactor/links/true/to-report/"$TYPE"/; tweet $I "$TYPE" & ;;
	4) export TYPE="Exit intersection on red light";
	  mv $I ~/busfactor/links/true/to-report/"$TYPE"/; tweet $I "$TYPE" & ;;
#	    r) replay=1; break;;
	s) mv $I ~/busfactor/links/true/to-report/;;
#	    *) continue;;
#	  esac
#	  break
#	done;;
	r) replay=1; break;;
	f) mv $I ~/busfactor/links/false/;;
	t) mv $I ~/busfactor/links/true/;;
	d) rm $I;;
#	s) break;;
	*) continue;;
      esac
      break
    done
    [ $replay -eq 1 ] && continue
    rm $DEBUG
    break
  done
done
