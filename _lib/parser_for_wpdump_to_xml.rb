require 'rexml/document'
require 'reverse_markdown'
require 'date'

wordpress_backup_filename = '/your/file/path/wordpress_backup.xml'
items_xpath = '/rss/channel/item'

file = File.read(wordpress_backup_filename)
xml_document = REXML::Document.new(file)
items = REXML::XPath.match(xml_document, items_xpath) # [REXML::Element]

items.each do |item|
  # publishなものだけ抽出する
  next if item.get_elements('wp:status').first&.text != "publish"
  next if item.get_elements('wp:ping_status').first&.text == "closed"
  # title
  title = item.get_elements('title').first.text
  # url
  url = item.get_elements('link').first.text
  # 公開日
  publish_date = DateTime.parse(item.get_elements('pubDate').first.text)
  # 本文
  text = item.get_elements('content:encoded').first.text

  # post_id
  post_id = item.get_elements('wp:post_id').first.text

  # category
  category = item.get_elements('category').first&.text

  # 本文
  content = ""
  text.each_line do |line|
    result = ReverseMarkdown.convert(line)
    content << result if result.length > 0
  end


  # ファイル作成
  markdown = "---
title: \"#{title}\"
layout: posts.liquid
is_draft: false
published_date: #{publish_date.new_offset('+0900').strftime("%Y-%m-%d %H:%M:%S +0900")}
categories: [\"#{category}\"]
tags: []
---

#{content}
  "
  File.open("posts/#{post_id}-#{publish_date.new_offset('+0900').strftime("%Y-%m-%d")}.md", "wb") do |io|
    io.write(markdown)
  end
end
