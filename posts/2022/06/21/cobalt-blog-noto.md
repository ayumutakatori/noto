---
title: Cobaltでblogを作り直した
layout: posts.liquid
is_draft: false
published_date: 2022-06-23 19:00:00 +0900
categories: [TECHNOLOGY]
tags: ["liquid"]
---

## wordpressからの移行

長年Wordpressを使ってきたのですが、ようやくCobaltを使った静的サイトジェネレーターで移行を済ませてみました。
その前段階でmediumに移すことや、他ブログサービスに移すことやwordpress.comにそのまま移すことなどを検討していました。
wordpressのインフラやアップデートの面倒をかけてられないというところの解消をしたかったのですが、
独自ドメイン運用をすることや、PaaSを使うとなるとやはり適切にお金をかける必要があり少々悩みました。

いろいろ考えてもとより、「コンテンツを自分の手元で管理したい」と「インフラなどの面倒はあまり見たくない」と「エンジニアとして自分で作るを維持したい」いう考えがありその上でcobaltを選択してみました。
もう一つ「モバイルから投稿可能にしたい」という欲もあったのですが、mediumがモバイルでの投稿をできない方針にしたことでいい意味で諦めが付きました。

## Wordpress について

色々言われることが多いwordpressですが良かったことも個人的には結構あり

* 良かった
  * インストールをすれば投稿するだけの環境が整っている
  * コンテンツ（画像など）も合わせて管理できるのでとりあえず投げ込めばいいという感じ
  * 開発が続いているので投稿体験としてはそれほど悪くない
  * デザインも機能もプラグイン・テンプレートを追加することでいくらでも豪華に
  * 独自ドメイン設定も知識があれば無料でできる

逆に、移行するにあたったポイント

* 移行ポイント
  * wordpressの普及率高さ故に攻撃対象になりがち
  * ホスティングサーバにインストールしていたので管理コストがあった
  * プラグインも脆弱性になる可能性がある
  * テキストエディタがちょっと自分には立地すぎた

一番上の攻撃対象になりがちというのがほとんどすべてです。
WEBの開発者と言う職業なのでなんとなく自分のblog乗っ取られるのは避けたいという気持ちも少しありました。

## Cobalt にした理由

まずいちばん最初の選択肢はPaaSだったのですが（もっというとMediumだったのですが）、
自分の用途だと独自ドメインが用件に入ると有料になってしまうというのが少し悩ましかった。
次に自分でシステムを構築してみるかとも思ったのですが、時間がないことと何らかのフレームワークをおそらく使うため
何らかのアップデート、脆弱性対応からは避けられないかなと思いました。

そこで静的サイトジェネレーターを使って、GitHub Pagesを使って無料で独自ドメイン + ホスティングしてもらうという案で考えてみました。
ジェネレーターは色々あってすでにみんな便利そうだったのですが、触ったことないものにしたかったのとRustに関わるものから絞ってみて、
ZolaとCobaltの2択で名前が好みな Cobalt を選択しました。liquid にも興味があったのもあったため。

## wpからの移行手順

片手間にやっていたので時間がかかってしまった。

### wordpressのデータの引っこ抜き

下記の方法で試してみた。

* wordpressのデータがwordpress自体のエクスポートして取れるxmlファイル。
* wordpressにapi経由でデータを取得する方法（rubypress gemを使ってみた）

最初にxmlファイルをparseしてみたんだけど、ファイルのインデントが読みにくくすぐにできなさそうに見えたので一旦保留。
rubypress の方はmarkdwonで取りたいデータはかんたんに取れそうだったんだけど、markdownのファイルを作るフォーマットが決まってなかったので
一旦ymlに吐き出しておきたかったんだけどdumpしたものを読み込むのにデータを直しながらyaml化しないと大変そうで保留。
再度xmlファイルに取り掛かった。apiの方は何百記事を都度とったりしなければいけなく微妙だったので手元にファイルがあるxmlの方をどうにかすることにした。

### 画像ファイルの引っこ抜き

画像ファイルはホスティングサーバがSSH接続できたので、SSHでログインしてwordpressの `/wp-contents/uploads` をtarでかためてscpで引っこ抜いてきた。

### wordpress のパース → markdwonファイル作成

wordpressのparseはちょっと調整しながらなんとかできたので、liquidのフォーマットを少しつつかためて何となくこんな感じかなと言うタイミングで
parseしたものをmarkdownとして吐き出すscriptをRubyでかいた。

```ruby
# parser_for_wpdump_to_xml.rb

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
title: "#｛title｝"
layout: posts.liquid
is_draft: false
published_date: #｛publish_date.new_offset('+0900').strftime("%Y-%m-%d %H:%M:%S +0900")｝
categories: ["#｛category｝"]
tags: []
---

#｛content｝
  "
  File.open("posts/#｛post_id｝-#｛publish_date.new_offset('+0900').strftime("%Y-%m-%d")｝.md", "wb") do |io|
    io.write(markdown)
  end
end

```

いざ本当にサイトを動かしてみるとcategoryの表記を一括置換で書き換えたりしなければだった。
サイトの形を変えていくたびmarkdwonのファイルフォーマットも変えなければいけなかったので
やっぱり外部通信が発生しないエクスポートしたxmlファイルにしておいて今回は正解だった。

### cobaltのサイト土台作成

まだまだ改善の余地ありだけど現時点で動いている Cobalt のディレクトリ構成はこんな感じになっている。

```
❯ tree -L 2
.
├── _cobalt.yml
├── _defaults
│   ├── pages.md
│   └── posts.md
├── _includes
│   ├── categories.liquid
│   ├── footer.liquid
│   ├── head.liquid
│   ├── header.liquid
│   └── yearly.liquid
├── _layouts
│   ├── default.liquid
│   └── posts.liquid
├── _lib
│   └── parser_for_wpdump_to_xml.rb
├── categories
│   ├── BOOK.md
│   ├── CULTURE.md
│   ├── ETC.md
│   ├── HIBI.md
│   ├── PHOTOGRAPHY.md
│   ├── SOUNDTRACK.md
│   ├── TECHNOLOGY.md
│   └── WORK.md
├── docs <= cobalt buildで吐き出されるところ、GitHub Pagesで公開されるディレクトリ
│   ├── CNAME
│   ├── categories
│   ├── index.html
│   ├── posts
│   ├── public
│   ├── rss.xml
│   └── yearly
├── index.md
├── posts
│   ├── 2022
│   └── past <= ここにwordpressの移行ファイルをつっこんでいる
├── public
│   ├── css
│   ├── fonts
│   └── images
└── yearly
    ├── 2013.md
    ├── 2014.md
    ├── 2015.md
    ├── 2016.md
    ├── 2017.md
    ├── 2018.md
    ├── 2019.md
    ├── 2020.md
    ├── 2021.md
    └── 2022.md

```

カテゴリーと過去の記事のところは絶対方法があるような気がするんだけど、
cobaltとliquidのドキュメントが読み込めてない。

_cobalt.yml はまだまだ必要最低限

```yaml
destination: docs

site:
  title: NOTO
  description: note
  base_url: https://noto.katsumataryo.com
posts:
  rss: rss.xml
assets:
  sass:
    style: Nested
```

### GitHub Pages

GitHub Pages はむしろ解説しているところがたくさんあるので特に言及はなしですが、
`$ cobalt build` したあとに全体をGitHubにまるごと上げて、_cobalt.ymlでbuildの吐き出し先が指定できたのでPagesで指定できる
`docs` をサイトとして公開できるディレクトリとした。

### liquidとcobalt

色々ツールとして使っていると言いながら、結局は公開されているのは素のHTMLという感じ。データベースもなし。
ただcobaltの恩恵を受けているなと感じるのは liquidがテンプレートやインクルードやデータを提供してくれてるところ。

例えば 2022 年の記事タイトルを表示する部分は下みたいな感じになっている。

```liquid
# 2022.md
---
title: "2022"
layout: default.liquid
---
｛% include "yearly.liquid" %｝
```
```liquid
# yearly.luquid

｛% assign target_year = page.title %｝
## ｛｛target_year｝｝

｛% for post in collections.posts.pages %｝
｛% assign year = post.published_date | date: "%Y" %｝ ｛% if year == target_year %｝ * 
｛｛ post.published_date | date: "%Y/%m/%d" ｝｝：[｛｛ post.title ｝｝](/｛｛ post.permalink ｝｝) ｛% endif %｝
｛% endfor %｝
```

```liquid
<!DOCTYPE html>
<html>
    <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# website: http://ogp.me/ns/website#">
        ｛% include "head.liquid" %｝
    </head>
    <body>
        ｛% include "header.liquid" %｝
        <div class="content">
          ｛｛ page.content ｝｝
        </div>
        <div class="footer">
        ｛% include "footer.liquid" %｝
        </div>
    </body>
</html>
```

で表示されているページがこんな感じ

<figure><img class="in_article" src="/public/images/2022/06/2022-06-21.png"></figure>

こんな感じでイテレータもあるしテンプレートもあるし変数も使えるしフィルターというかデータ加工も割と豊富。
レイアウトやファイルの構造をいじったとき、素のHTMLなら全ファイル書き換えていかなければいけないところを
`$ cobalt build` で一発というのはやっぱり爽快。

確認も`$ cobalt serve` で `localhost:3000` が見れるようになるのでらくらく。

```shell
❯ cobalt serve
[info] Building from "/noto" into "/noto/docs"
Error: serve command failed
Info: caused by Failed to render content for posts/2022/06/21/cobalt-blog-noto.html
Info: caused by liquid: Unknown index
  with:
    variable=page
    requested index=content
    available indexes=tags, permalink, slug, title, description, collection, is_draft, previous, next, file, data, published_date, categories, weight
from: ｛% include "head.liquid" %｝
  with:
    "head.liquid"=head.liquid

```

こんな感じでエラーも出してくれる。

### その他

* CSSは昔の知識で何とかむりくりやってる。
* FontsはGoogle Fontで見つけて読みやすそうなのを読み込めるようにしてみた。
* OGP設定はちょっと勉強してなんとか意図したとおりに表示されるようになった気がする。
* 記事を作るときmarkdwonのフォーマットがあるのでそれを簡単に作れるようにしないとちょっとめんどくさい。
* `｛` とか `%` とか特殊文字をmarkdownで書くときエスケープしなければいけないのがちょっとめんどくさい。これどうにかなるような気もする
* github actionで `$ cobalt build` が蹴れるきがする。これがうまく行けば（PR作成時などにbuildしてdocsに格納できれば）githubのモバイル上で記事を書いたりできるような気がする。

## 現在の完成形

というわけでこんな感じになっています。

<figure><img class="in_article" src="/public/images/2022/06/2022-06-21.png"></figure>

まだやりたいことがあるので少しずつ改善をしていきたい。