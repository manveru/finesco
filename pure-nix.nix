{ pkgs ? import ./nix/nixpkgs.nix }:
let
  inherit (pkgs) stdenv lib writeText;
  inherit (builtins)
    replaceStrings baseNameOf readDir attrValues fromJSON readFile;

  mkSite = { parts }:
    stdenv.mkDerivation rec {
      name = "site";

      inherit parts;

      buildCommand = ''
        mkdir -p $out

        for part in $parts; do
          cp -r $part/* $out
        done
      '';
    };

  partialPaths = { links = ./templates/links.html; };

  safeBaseNameOf = path:
    builtins.unsafeDiscardStringContext
    (replaceStrings [ "/nix/store/" ] [ "" ] (baseNameOf path));

  mkTemplate = path:
    writeText "mkTemplate" ''
      { partials, ... }@args: '''
        ${lib.fileContents (builtins.trace path path )}
      '''
    '';

  evalTemplate = { name, layout, src ? null, ... }@args:
    import (mkTemplate layout) (args // {
      partials = lib.mapAttrs (k: v: evalTemplate (args // { layout = v; }))
        partialPaths;
      body =
        if src != null then evalTemplate (args // { layout = src; }) else "";
    });

  mkPage = { name, route, src, layout ? null, ... }@args:
    let
      result =
        writeText route (evalTemplate (args // { inherit name layout src; }));
    in pkgs.runCommand "mkPage-${name}" { } ''
      mkdir -p $out
      cp ${result} $out/${route}
    '';

  mkStyle = { loadPath, scss, outName }:
    pkgs.runCommand "mkStyle-${outName}" {
      inherit loadPath scss outName;
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      LC_ALL = "en_US.UTF-8";
      nativeBuildInputs = [ pkgs.sass ];
    } ''
      mkdir -p $out
      sass --scss --sourcemap=file --style expanded --load-path $loadPath $scss $out/$outName
    '';

  mkStyles = { route, src }:
    let
      files = lib.mapAttrs (k: v:
        mkStyle {
          loadPath = src;
          outName = replaceStrings [ ".scss" ] [ ".css" ] k;
          scss = "${src}/${k}";
        }) (readDir src);
    in stdenv.mkDerivation rec {
      name = "styles";
      stylesheets = attrValues files;
      inherit route;
      buildCommand = ''
        mkdir -p $out/$route

        for stylesheet in $stylesheets; do
          ln -s $stylesheet/* $out/$route
        done
      '';
    };

  mkFiles = { route, src }:
    stdenv.mkDerivation rec {
      name = "files";
      inherit route src;
      buildCommand = ''
        mkdir -p $out/$route
        for file in $src/*; do
          ln -s $file $out/$route
        done
      '';
    };

  favicons = ''<meta property="favicons" content="favicons">'';

  htmlPage = id: src: args:
    mkPage ({
      name = id;
      inherit id src favicons;
      route = "${id}.html";
      navLink = navLinkFor "${id}.html";
      layout = ./templates/default.html;
    } // args);

  md2html = src:
    pkgs.runCommand "md2html-${safeBaseNameOf src}" {
      inherit src;
      nativeBuildInputs = [ pkgs.multimarkdown ];
    } ''
      mkdir -p $out
      multimarkdown -s "$src" -o "$out"
    '';

  md2htmlMeta = src:
    let
      raw = pkgs.runCommand "md2htmlMeta-${safeBaseNameOf src}" {
        inherit src;
        nativeBuildInputs = [ pkgs.ruby ];
      } ''
        ruby -ryaml -rjson -e 'puts(JSON.pretty_unparse(YAML.load_file(ARGV[0])))' "$src" > "$out"
      '';
    in fromJSON (readFile raw);

  markdownPage = route: src:
    { layout ? null, ... }@args:
    let
      meta = md2htmlMeta src;
      result = writeText route (evalTemplate (meta // args // {
        inherit layout;
        name = "outermarkdown";
        src = writeText "md" (evalTemplate (meta // args // {
          name = "markdown.html";
          layout = ./templates/markdown.html;
          src = md2html src;
        }));
      }));
    in pkgs.runCommand "markdownPage" { } ''
      mkdir -p $out
      cp -r ${result} $out/${route}
    '';

  blogPost = src:
    let
      meta = md2htmlMeta src;
      result = writeText "${meta.date}.html" (evalTemplate (meta // {
        name = "blogPosts-${safeBaseNameOf src}";
        layout = ./templates/default.html;
        inherit favicons;
        id = "blog";
        navLink = route: name: ''<a href=".${route}">${name}</a>'';
        src = writeText "blogPost-inner-${safeBaseNameOf src}" (evalTemplate
          (meta // {
            name = safeBaseNameOf src;
            layout = ./templates/post.html;
            src = md2html src;
          }));
      }));
    in pkgs.runCommand "blogPosts" { } ''
      mkdir -p $out/blog
      cp -r ${result} $out/blog/${meta.date}.html
    '';

  blogPosts = lib.mapAttrs (k: v: blogPost "${./blog}/${k}") (readDir ./blog);

  navLinkFor = active: route: name:
    if active == route then
      ''<a href="/${route}" class="active">${name}</a>''
    else
      ''<a href="/${route}">${name}</a>'';

in mkSite {
  parts = [
    (htmlPage "index" ./index.html {
      title = "Home";
      id = "home";
    })

    (htmlPage "soudan" ./templates/soudan.html { title = "ご相談の流れ"; })
    (htmlPage "about" ./templates/about.html { title = "会社概要"; })
    (htmlPage "contact" ./templates/contact.html { title = "お問い合わせ"; })
    (htmlPage "english" ./templates/english.html { title = "ENGLISH"; })

    # お知らせ
    # (htmlPage "/blog.html" "ブログ" }</li>

    (markdownPage "column.html" ./templates/column.md {
      navLink = navLinkFor "column.html";
      inherit favicons;
      layout = ./templates/default.html;
    })

    (markdownPage "service.html" ./templates/service.md {
      navLink = navLinkFor "service.html";
      inherit favicons;
      layout = ./templates/default.html;
    })

    (mkFiles {
      route = "images";
      src = ./images;
    })

    (mkFiles {
      route = "js";
      src = ./js;
    })

    (mkStyles {
      route = "css";
      src = ./scss;
    })
  ];
}
