---
layout: default.liquid
---
<h3 class="subtitle">Articles!</h3>

{% for post in collections.posts.pages %}
* {{ post.published_date }}：[{{ post.title }}]({{ post.permalink }})
{% endfor %}
