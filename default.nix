{ environment ? "production" }:
with import ./nix/functions.nix {
  inherit environment;

  rootDir = ./.;

  layout = "default.tmpl";

  pageOptions =
    { lib, sortByRecent, mkHtmlPage, mkMarkdownPage, mkPosts, loadPosts }:
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
  blogPostPages = mkPosts {
    name = "blogPosts";
    route = "/blog/";
    posts = loadPosts "/blog/" ./blog;
  };

  infoPostPages = mkPosts {
    name = "infoPosts";
    route = "/info/";
    posts = loadPosts "/info/" ./info;
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
  (copyFiles ./js "/js")
  (copyFiles ./images "/images")
] ++ blogPostPages ++ infoPostPages)
