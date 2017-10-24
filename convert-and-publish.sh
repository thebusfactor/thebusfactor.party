#!/bin/bash
FFMPEG=$(which ffmpeg 2>/dev/null)
if [ -z ${FFMPEG} ]; then
	FFMPEG=$(which avconv 2>/dev/null)
	if [ -z ${FFMPEG} ]; then
		echo "Could not find ffmpeg or avconv, quitting" >&2
		exit
	fi
fi

YOUTUBE=$(which youtube-upload 2>/dev/null)
if [ -z ${YOUTUBE} ]; then
	echo "Couldn't find youtube-upload, clone from https://github.com/tokland/youtube-upload/ and setup auth"
	exit
fi

PYTHON=$(which python 2>/dev/null)
if [ -z ${PYTHON} ]; then
	echo "Couln't find python, install it"
	exit
fi

if ! ${PYTHON} -c 'import inflect' >/dev/null 2>/dev/null; then
	echo "Couldn't find python inflect library, install it with pip"
	echo "pip install --user inflect"
	exit
fi

if [ -z ${1} ] || [ -z ${2} ]; then
	echo "Usage: $0 filename description"
	echo "Example:"
	echo "$0 \"2017-10-13 17-00-06.mkv\" \"Description goes here, patreon shit gets appended automatically\""
	exit
fi

FILENAME=${1}
YEAR=$(basename ${FILENAME} | cut -c1-4)
DATE=$(basename ${FILENAME} | cut -c1-10)
if [ "$(date +'%Y' -d "${YEAR}")" != "${YEAR}" || "$(date +'%Y-%m-%d' -d "${DATE}")" != "${DATE}" ]; then
	echo "Invalid filename, should have the date at the start, like 2017-10-03"
	exit
fi

EPNUMBER=$(ls -1 downloads.thebusfactor.party/*/*-TBF-*.mp4 | tail -1 | rev | cut -d '-' -f 1 | rev | cut -d '.' -f 1)
let EPNUMBER++
# Detect silence somehow, hard code for now. If you want to cut the end as well, do soemthing like the following (not tested, but should do it)
# SILENCE="00:11 -t 1:00:00"
SILENCE=00:11
SOURCE=${FILENAME}
DEST=$(dirname ${0})/downloads.thebusfactor.party/${YEAR}/${DATE}-TBF-${EPNUMBER}
${FFMPEG} -i "${SOURCE}" -ss ${SILENCE} -c copy ${DEST}.mp4
VIDEOSIZE=$(du -b ${DEST}.mp4 | cut -f 1)
${FFMPEG} -i "${SOURCE}" -ss ${SILENCE} -vn ${DEST}.mp3
AUDIOSIZE=$(du -b ${DEST}.mp3 | cut -f 1)
aws s3 sync $(dirname ${0})/downloads.thebusfactor.party s3://downloads.thebusfactor.party/ --acl public-read
DESCRIPTION="${2}"
YOUTUBEID=$(${YOUTUBE} --title="The Bus Factor! Episode ${EPNUMBER}" --tags "bus,infosec,technology" --description "${DESCRIPTION}\n\nFind us on https://thebusfactor.party, and consider joining our patreon at https://patreon.com/thebusfactor" ${DEST}.mp4)
cd $(dirname ${0})/thebusfactor.party
POSTFILE=_posts/${DATE}-episode-${EPNUMBER}.markdown
cp _templates/podcast.markdown $POSTFILE
sed -i -e "s/__DATE_YYYY-MM-DD__/${DATE}/g" $POSTFILE
sed -i -e "s/__DATE_YYYY__/${YEAR}/g" $POSTFILE
sed -i -e "s/__YOUTUBEID__/${YOUTUBEID}/g" $POSTFILE
sed -i -e "s/__AUDIOSIZE__/${AUDIOSIZE}/g" $POSTFILE
sed -i -e "s/__VIDEOSIZE__/${VIDEOSIZE}/g" $POSTFILE
sed -i -e "s/__DESCRIPTION__/${DESCRIPTION}/g" $POSTFILE
sed -i -e "s/__NUMBER_DIGITS__/${EPNUMBER}/g" $POSTFILE
ORDINALNUMBER=$(${PYTHON} -c "import inflect;print(inflect.engine().number_to_words(${EPNUMBER}).title())")
sed -i -e "s/__NUMBER_WORDS__/${ORDINALNUMBER}/g" ${POSTFILE}
cd -
echo "Need to do a commit and push in thebusfactor.party"
