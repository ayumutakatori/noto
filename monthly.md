---
title: note
layout: default.liquid
---
<h2 class="subtitle">さいきんのこと</h2>

{% for post in collections.posts.pages limit:10 %}
* {{ post.published_date }}：[{{ post.title }}]({{ post.permalink }})
  {% endfor %}
