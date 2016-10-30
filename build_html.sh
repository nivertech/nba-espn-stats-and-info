#!/bin/bash

echo '<html>' > index.html
echo '<head>' >> index.html
echo '<title>NBA ESPN Stats & Info</title>' >> index.html
echo '<meta charset="UTF-8">' >> index.html
echo '</head>' >> index.html
echo '<body>' >> index.html
echo '<center>' >> index.html

newest_id_to_get=$(\
	curl -s --compressed 'https://twitter.com/ESPNStatsInfo' | \
	tr -d '\n' | \
	sed 's/data-tweet-id/\ndata-tweet-id/g' | \
	grep -F TweetText | \
	head -1 | \
	awk -F '"' '{print $2}' \
)


#get last x pages of tweets
x=10
for ((i=1;i<=x;i++)); do 
	tweets=$( \
		curl -s --compressed "https://mobile.twitter.com/i/rw/profile/timeline?max_id=$newest_id_to_get&screen_name=ESPNStatsInfo&type=tweets" | \
		tr -d '\n' | \
		sed 's/data-tweet-id/\ndata-tweet-id/g' | \
		grep -F TweetText \
	)

	found_ids=$( \
		echo "$tweets" | \
		grep -F -f keywords.list | \
		awk -F '"' '{print $2}' \
	)

	if [ ! -z "$found_ids" ]; then
		echo "$found_ids" | \
		xargs -n 1 -I {} curl -s --compressed "https://api.twitter.com/1.1/statuses/oembed.json?id={}" | \
		jq --raw-output '.html' | \
		sed 's/<script.*script>/ /g' >> index.html
	fi

	newest_id_to_get=$(echo "$tweets" | tail -1 | awk -F '"' '{print $2}')

	echo "$i $x" | awk '{print 100*$1/$2 "%..."}'
done

echo '</center>' >> index.html
echo '<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>' >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html
