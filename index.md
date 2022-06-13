---
title: PAPYRUS
layout: default.liquid
---
<h2 class="subtitle">Articles!</h2>

{% for post in collections.posts.pages %}
* {{ post.published_date }}：[{{ post.title }}]({{ post.permalink }})
{% endfor %}
