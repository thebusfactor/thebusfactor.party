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

if [ -z "${1}" -o -z "${2}" ]; then
	echo "Usage: $0 filename description [silence, default: 00:00]"
	echo "Example:"
	echo "$0 \"2017-10-13 17-00-06.mkv\" \"Description goes here, patreon shit gets appended automatically\""
	exit
fi

if [ ! -e "$(dirname ${0})/patreon-cookie.sh" ]; then
	echo "Need to create the patreon-cookie.sh file"
	echo "Check out the patreon-cookie-example.sh for template"
	exit
fi

FILENAME=${1}
YEAR=$(basename ${FILENAME} | cut -c1-4)
DATE=$(basename ${FILENAME} | cut -c1-10)
if [ "$(date +'%Y' -d "${YEAR}")" != "${YEAR}" -o "$(date +'%Y-%m-%d' -d "${DATE}")" != "${DATE}" ]; then
	echo "Invalid filename, should have the date at the start, like 2017-10-03"
	exit
fi

S3LOC=$(dirname ${0})/../downloads.thebusfactor.party/
aws s3 sync s3://downloads.thebusfactor.party/ ${S3LOC}
EPNUMBER=$(ls -1 $S3LOC/*/*-TBF-*.mp4 | tail -1 | rev | cut -d '-' -f 1 | rev | cut -d '.' -f 1)
let EPNUMBER++
# Detect silence somehow, hard code for now. If you want to cut the end as well, do soemthing like the following (not tested, but should do it)
# SILENCE="00:11 -t 1:00:00"
SILENCE=${3:-00:00}
SOURCE=${FILENAME}
DEST=$S3LOC/${YEAR}/${DATE}-TBF-${EPNUMBER}
mkdir -p $(dirname ${DEST})
${FFMPEG} -loglevel 24 -i "${SOURCE}" -ss ${SILENCE} -c copy ${DEST}.mp4
VIDEOSIZE=$(du -b ${DEST}.mp4 | cut -f 1)
${FFMPEG} -loglevel 24 -i "${SOURCE}" -ss ${SILENCE} -vn ${DEST}.mp3
AUDIOSIZE=$(du -b ${DEST}.mp3 | cut -f 1)
DESCRIPTION="${2}"
YOUTUBEID=$(${YOUTUBE} --title="The Bus Factor! Episode ${EPNUMBER} (${DATE})" --tags "bus,infosec,technology" --description "${DESCRIPTION}\n\nFind us on https://thebusfactor.party, and consider joining our patreon at https://patreon.com/thebusfactor" ${DEST}.mp4)
# Sync after youtube upload, just to give youtube a chance to generate a thumbnail, which is used by patreon
aws s3 sync ${S3LOC} s3://downloads.thebusfactor.party/ --acl public-read
cd $(dirname ${0})
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
git add ${POSTFILE}
git commit -m "Add episode ${EPNUMBER}"
git push
cd -

source $(dirname ${0})/patreon-cookie.sh

CSRFJSON=$(curl 'https://www.patreon.com/REST/auth/CSRFTicket' -H 'cookie: '"${COOKIE}" --compressed)
CSRF=$(echo "${CSRFJSON}" | jq .token | tr -d '"')

POSTJSON=$(curl 'https://www.patreon.com/api/posts?include=user_defined_tags.null%2Ccampaign.creator.null%2Ccampaign.rewards.campaign.null%2Ccampaign.rewards.creator.null&fields\[post\]=post_type%2Cmin_cents_pledged_to_view&fields\[campaign\]=is_monthly&fields\[reward\]=amount_cents%2Ctitle&fields\[user\]=\[\]&fields\[post_tag\]=value&json-api-version=1.0' -H 'x-csrf-signature: '"${CSRF}" -H 'cookie: '"${COOKIE}" -H 'content-type: application/vnd.api+json' --data-binary '{"data":{"type":"post","attributes":{"post_type":"video_embed"}}}' --compressed)
POSTID=$(echo "${POSTJSON}" | jq .data.id | tr -d '"')

curl 'https://www.patreon.com/api/posts/'"${POSTID}"'?include=user.null%2Cattachments.null%2Cuser_defined_tags.null%2Ccampaign.earnings_visibility%2Ccampaign.rewards.null%2Cpoll&fields\[post\]=category%2Ccents_pledged_at_creation%2Cchange_visibility_at%2Ccomment_count%2Ccontent%2Ccreated_at%2Ccurrent_user_can_delete%2Ccurrent_user_can_view%2Ccurrent_user_has_liked%2Cdeleted_at%2Cearly_access_min_cents%2Cedit_url%2Cedited_at%2Cearly_access_min_cents%2Cembed%2Cimage%2Cis_automated_monthly_charge%2Cis_paid%2Clike_count%2Cmin_cents_pledged_to_view%2Cnum_pushable_users%2Cpatreon_url%2Cpatron_count%2Cpledge_url%2Cpost_file%2Cpost_type%2Cpublished_at%2Cscheduled_for%2Cthumbnail%2Ctitle%2Curl%2Cwas_posted_by_campaign_owner&json-api-version=1.0' -X PATCH -H 'x-csrf-signature: '"${CSRF}" -H 'cookie: '"${COOKIE}" -H 'content-type: application/vnd.api+json' --data-binary '{"data":{"type":"post","attributes":{"content":"<p>'"${DESCRIPTION}"'</p>","post_type":"video_embed","is_paid":true,"min_cents_pledged_to_view":0,"title":"The Bus Factor - Episode '"${EPNUMBER}"'","embed":{"description":"'"${DESCRIPTION}"'\n\nFind us on https://thebusfactor.party, and consider joining our patreon at https://patreon.com/thebusfactor","provider":"YouTube","provider_url":"https://www.youtube.com/","html":"\n<iframe\n    src=\"https://www.youtube.com/embed/'"${YOUTUBEID}"'\"\n    class=\"embedly-embed\"\n    width=\"854\"\n    height=\"480\"\n    frameborder=\"0\"\n    scrolling=\"no\"\n    allowfullscreen\n>\n</iframe>\n","url":"https://youtu.be/'"${YOUTUBEID}"'","subject":"maxresdefault.jpg"},"thumbnail":{"height":720,"url":"https://i.ytimg.com/vi/'"${YOUTUBEID}"'/maxresdefault.jpg","width":1280,"index":0},"tags":{"publish":true}},"relationships":{"post_tag":{"data":{"type":"post_tag","id":"user_defined;technology"}},"user_defined_tags":{"data":[{"id":"user_defined;bus","type":"post_tag"},{"id":"user_defined;infosec","type":"post_tag"},{"id":"user_defined;technology","type":"post_tag"}]}}},"included":[{"type":"post_tag","id":"user_defined;bus","attributes":{"value":"bus","cardinality":1}},{"type":"post_tag","id":"user_defined;infosec","attributes":{"value":"infosec","cardinality":1}},{"type":"post_tag","id":"user_defined;technology","attributes":{"value":"technology","cardinality":1}}]}' --compressed
unset COOKIE
