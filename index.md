---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: default
---
<h1>Live Stream</h1>
<p>Find us at <a href="https://twitch.tv/thebusfactor">https://twitch.tv/thebusfactor</a>. We normally stream around 1700 NZT / 1400 AEST on Friday's.</p>

<!-- <iframe src="http://player.twitch.tv/?thebusfactor" height="200" width="200" scrolling="no" allowfullscreen="true"></iframe>. This is ugly so lets find a better way to embed it -->

<hr>

<h1>Social contacts</h1>
<p>We are also on twitter at <a href="https://twitter.com/thebusfactor">@thebusfactor</a>. You can view old videos below, or on youtube at <a href="https://www.youtube.com/channel/UCLJTj-fbNOGlWMAHpWQqHEQ">https://www.youtube.com/channel/UCLJTj-fbNOGlWMAHpWQqHEQ</a>.</p>
<p>We are also on patreon if you would wish to support us. Visit our page at <a href="https://www.patreon.com/thebusfactor">https://www.patreon.com/thebusfactor</a></p>
 

<h1>Previous Episodes</h1>

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href=".{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>
