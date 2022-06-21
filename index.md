---
title: note
layout: default.liquid
---
<h2 class="subtitle">Logs</h2>

{% for post in collections.posts.pages limit:10 %}
* {{ post.published_date | date: "%Y/%m/%d" }}：[{{ post.title }} [{{post.categories}}]]({{ post.permalink }}) 
{% endfor %}

<h2 class="subtitle">Notice</h2>

<p>※2022/06 以前の記事は移行中です。時間を見つけてなおしていきます。</p>

