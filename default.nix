{ environment ? "production" }:
with import ./nix/functions.nix {
  inherit environment;

  rootDir = ./.;

  layout = "default.tmpl";

  pageOptions = { lib, sortByRecent, mkHtmlPage, mkMarkdownPage, loadPosts }:
    let
      blogPosts = sortByRecent (loadPosts "/blog/" ./blog);
      infoPosts = sortByRecent (loadPosts "/info/" ./info);
    in [
      {
        url = "/";
        title = "Home";
        id = "home";
        compiler = mkHtmlPage;
        meta.posts = lib.take 2 blogPosts;
      }

      {
        url = "/about.html";
        title = "会社概要";
        id = "about";
        compiler = mkHtmlPage;
      }

      {
        url = "/service.html";
        title = "サービス一覧";
        id = "service";
        compiler = mkMarkdownPage;
      }

      {
        url = "/soudan.html";
        title = "ご相談の流れ";
        id = "soudan";
        compiler = mkHtmlPage;
      }

      {
        url = "/info.html";
        title = "お知らせ";
        id = "info";
        compiler = mkHtmlPage;
        meta.posts = infoPosts;
        meta.css = "blog";
        meta.id = "blog";
        meta.atomTag = ''
          <link href="/info.atom" type="application/atom+xml" rel="alternate" title="Info Atom feed" />
        '';
      }

      {
        url = "/column.html";
        title = "コラム";
        id = "column";
        compiler = mkMarkdownPage;
      }

      {
        url = "/blog.html";
        title = "ブログ";
        id = "blog";
        compiler = mkHtmlPage;
        meta.posts = blogPosts;
        meta.atomTag = ''
          <link href="/blog.atom" type="application/atom+xml" rel="alternate" title="Blog Atom feed" />
        '';
      }

      {
        url = "/contact.html";
        title = "お問い合わせ";
        id = "contact";
        compiler = mkHtmlPage;
      }

      {
        url = "/english.html";
        title = "ENGLISH";
        id = "english";
        compiler = mkHtmlPage;
      }

      {
        url = "https://ja-jp.facebook.com/Finesco-Inc-427977463911779/";
        title = "Facebook";
      }

      {
        url = "/rules.html";
        title = "コラム";
        id = "rules";
        compiler = mkMarkdownPage;
        hidden = true;
      }

      {
        url = "/privacy.html";
        title = "コラム";
        id = "privacy";
        compiler = mkMarkdownPage;
        hidden = true;
      }

      {
        url = "/disclaimer.html";
        title = "コラム";
        id = "disclaimer";
        compiler = mkMarkdownPage;
        hidden = true;
      }
    ];
};
let
  lastPostDate = posts:
    if (builtins.length posts) > 0 then (builtins.head posts).date else null;

  postsToAtom = posts:
    map (post: {
      id = "tag:finesco.jp,2019:blog,${post.date}";
      author = "Finesco";
    } // post) posts;

  infoPosts = sortByRecent (loadPosts "/info/" ./info);
  blogPosts = sortByRecent (loadPosts "/blog/" ./blog);

  atomMeta = id: posts: {
      posts = postsToAtom posts;
      id = "tag:finesco.jp,2019:blog";
      blogURL = "https://finesco.jp/${id}";
      feedURL = "https://finesco.jp/${id}.atom";
      author = "Finesco";
      generator.version = "2019.08";
      generator.url = "http://github.com/manveru/finesco";
      generator.name = "Finesco";
      updated = lastPostDate posts;
    };

  blogPostPages = mkPosts {
    name = "blogPosts";
    route = "/blog/";
    posts = blogPosts;
  };

  infoPostPages = mkPosts {
    name = "infoPosts";
    route = "/info/";
    posts = infoPosts;
  };

  blogFeed = mkAtom {
    route = "/blog.atom";
    meta = atomMeta "blog" blogPosts;
    posts = infoPosts;
  };

  infoFeed = mkAtom {
    route = "/info.atom";
    meta = atomMeta "info" infoPosts;
  };

in mkSite ({ copyFiles, compiled }:
with compiled;
[
  home
  about
  service
  soudan
  info
  column
  blog
  contact
  english
  rules
  privacy
  disclaimer
  favicons
  infoFeed
  blogFeed
  (copyFiles ./js "/js")
  (copyFiles ./images "/images")
] ++ blogPostPages ++ infoPostPages)
