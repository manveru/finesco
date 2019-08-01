with import ./nix/functions.nix {
  links = [
    {
      url = "/";
      text = "Home";
    }
    {
      url = "/about.html";
      text = "会社概要";
    }
    {
      url = "/service.html";
      text = "サービス一覧";
    }
    {
      url = "/soudan.html";
      text = "ご相談の流れ";
    }
    {
      url = "/info.html";
      text = "お知らせ";
    }
    {
      url = "/column.html";
      text = "コラム";
    }
    {
      url = "/blog.html";
      text = "ブログ";
    }
    {
      url = "/contact.html";
      text = "お問い合わせ";
    }
    {
      url = "/english.html";
      text = "ENGLISH";
    }
    {
      url = "https://ja-jp.facebook.com/Finesco-Inc-427977463911779/";
      text = "Facebook";
    }
  ];
};
let
  pages = {
    index = mkHtmlPage (commonPageAttrs "index" {
      meta = {
        id = "home";
        title = "Home";
        links = navLinks "/";
        posts = take 2 (sortByRecent (loadPosts "/blog/" ./blog));
      };
    });

    about = mkHtmlPage (commonPageAttrs "about" { meta.title = "会社概要"; });

    service = mkMarkdownPage {
      name = "service.html";
      route = "/service.html";
      body = "service.md";
      templates = {
        "service.md" = ./templates/service.md;
        "markdown.tmpl" = ./templates/markdown.tmpl;
      };

      css = {
        route = "/css/service.css";
        main = "service.css";
        dependencies = cssDepsFor ./css "service.css";
      };

      meta = {
        id = "service";
        title = "サービス一覧";
        links = navLinks "/service.html";
      };
    };

    soudan = mkHtmlPage (commonPageAttrs "soudan" { meta.title = "ご相談の流れ"; });
    info = mkHtmlPage (commonBlogAttrs "info" { meta.title = "お知らせ"; });

    column = mkMarkdownPage (commonMarkdownAttrs "column" {
      name = "column.html";
      route = "/column.html";
      body = "column.md";
      templates = {
        "column.md" = ./templates/column.md;
        "markdown.tmpl" = ./templates/markdown.tmpl;
      };

      css = {
        route = "/css/column.css";
        main = "column.css";
        dependencies = cssDepsFor ./css "column.css";
      };

      meta = {
        id = "column";
        title = "コラム";
        links = navLinks "/column.html";
      };
    });

    blog = mkHtmlPage (commonBlogAttrs "blog" { meta.title = "お知らせ"; });
    contact = mkHtmlPage (commonPageAttrs "contact" { meta.title = "お問い合わせ"; });
    english =
      mkHtmlPage (commonPageAttrs "english" { meta.title = "English"; });

    blogPosts = mkPosts {
      name = "blogPosts";
      route = "/blog/";
      posts = loadPosts "/blog/" ./blog;
    };

    infoPosts = mkPosts {
      name = "infoPosts";
      route = "/info/";
      posts = loadPosts "/info/" ./info;
    };

    js = copyFiles ./js "/js";
    images = copyFiles ./images "/images";
  };

in mkSite {
  parts = with pages;
    [
      index
      about
      service
      soudan
      info
      column
      blog
      contact
      english
      js
      images
      favicons
    ] ++ blogPosts ++ infoPosts;
}
