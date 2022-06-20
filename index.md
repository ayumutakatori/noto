---
title: PAPYRUS
layout: default.liquid
---
<h2 class="subtitle">さいきんのこと</h2>

{% for post in collections.posts.pages limit:10 %}
* {{ post.published_date }}：[{{ post.title }}]({{ post.permalink }})
{% endfor %}

<h2 class="subtitle">カテゴリー</h2>
{% assign categories = "TECHNOLOGY,SOUNDTRACK,PHOTOGRAPHY,HIBI,WORK,BOOK,CULTURE,ETC" | split: "," %}
{% for category in categories %}<a href="/categories/{{category}}.html">{{category}}</a> | {% endfor %}

<h2 class="subtitle">かこのきじ</h2>
{% for i in (2013..2022) reversed %}<a href="/yearly/{{i}}.html">{{i}}</a> | {% endfor %}
