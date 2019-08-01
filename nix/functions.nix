{ links ? [], pkgs ? import ./nixpkgs.nix }:
let
  inherit (pkgs) stdenv lib writeText runCommand infuse;
  inherit (builtins)
    attrNames placeholder replaceStrings baseNameOf readDir attrValues fromJSON
    readFile mapAttrs toJSON toFile listToAttrs;
  inherit (lib) take sort makeBinPath concatMapStrings;
in rec {
  inherit take;

  mkSite = { parts }:
    runCommand "finesco" { inherit parts; } ''
      mkdir -p $out

      for part in $parts; do
        chmod u+rw -R $out
        cp -r $part/* $out
      done
    '';

  builder = toFile "builder.sh" ''
    if [ -e .attrs.sh ]; then
      source .attrs.sh;
    fi

    eval "$buildCommand"
  '';

  # we use our own derivation because we don't need all the overhead of stdenv
  # and this speeds up builds a lot.
  mkDerivation = givenArgs:
    derivation (givenArgs // {
      out = placeholder "out";
      system = builtins.currentSystem;
      builder = "${pkgs.bash}/bin/bash";
      args = [ "-e" builder ];
    });

  layouts = {
    default = {
      template = "default.tmpl";
      templates = {
        "links.tmpl" = ../templates/links.tmpl;
        "default.tmpl" = ../templates/default.tmpl;
      };
    };
  };

  sortByRecent = sort (a: b: a.date > b.date);

  loadPosts = baseUrl: location:
    (attrValues (mapAttrs (k: v:
    let markdown = parseMarkdown "${location + "/${k}"}";
    in (markdown // { url = "${baseUrl}${markdown.date}.html"; }))
    (readDir location)));

  parseMarkdown = src:
    let
      raw = mkDerivation {
        name = "md2Meta";

        inherit src;

        PATH = makeBinPath [ pkgs.rubyEnv.wrappedRuby ];
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LC_ALL = "en_US.UTF-8";

        buildCommand = ''
          ruby ${../scripts/front_matter.rb} "$src" > $out
        '';
      };
    in fromJSON (readFile raw);

  navLinks = currentRoute:
    map (link:
    if currentRoute == link.url then
      ''<a href="${link.url}" class="active">${link.text}</a>''
    else
      ''<a href="${link.url}">${link.text}</a>'') links;

  cssTag = route: ''<link rel="stylesheet" href="${route}" />'';

  favicons = mkDerivation (let
    convertPNG = size:
      "convert -background none ${
        ../images/favicon.svg
      } -resize ${size}x${size}! +repage $out/images/favicons/favicon${size}.png";
    convertICO = "convert -background none ${
      ../images/favicon.svg
    } -define icon:auto-resize=32,64 +repage ico:- > $out/images/favicons/favicon.ico";
    in {
      name = "favicons";
      PATH = makeBinPath [ pkgs.coreutils pkgs.imagemagick ];

      buildCommand = ''
        mkdir -p $out/images/favicons
        ${convertICO}
        ${convertPNG "32"}
        ${convertPNG "57"}
        ${convertPNG "72"}
        ${convertPNG "144"}
      '';
    });

  # TODO:
  # maybe add this sometime (have to clean up HTML first)
  # tidy -ashtml -i --drop-empty-elements false
  mkHtmlPage =
    { name, route, body, layout ? layouts.default, templates, meta ? { }, css ?
      null, ... }@args:
    let
      combinedTemplates = layout.templates // templates;
      finalMeta = meta
        // (if css != null then { cssTag = cssTag css.route; } else { });
    in mkDerivation (args // {
      __structuredAttrs = true;

      inherit name combinedTemplates;

      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];

      buildCommand = let
        definitions =
          concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
        metaJSON = toFile "meta.json" (toJSON finalMeta);
        in ''
          for i in "''${!combinedTemplates[@]}"; do
            cp "''${combinedTemplates[$i]}" $i
          done

          mkdir -p $out
          ${if css != null then "cp -r ${mkCSS css}/* $out" else ""}
          sed -i 's!@@body@@!{{template "${body}" .}}!' "${layout.template}"
          infuse -f ${metaJSON} ${definitions} "${layout.template}" -o "$out${route}"
        '';
    });

  mkPost = { name, route, bodyTmpl, layout ? layouts.default, templates, meta ?
    { }, css ? null, ... }@args:
    let
      combinedTemplates = layout.templates // templates;
      finalMeta = meta
        // (if css != null then { cssTag = cssTag css.route; } else { });
    in mkDerivation (args // {
      __structuredAttrs = true;

      inherit name combinedTemplates;

      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];

      buildCommand = let
        definitions =
          concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
        metaJSON = toFile "meta.json" (toJSON finalMeta);
        in ''
          for i in "''${!combinedTemplates[@]}"; do
            cp "''${combinedTemplates[$i]}" $i
          done

          mkdir -p $out/$(dirname ${route})
          ${if css != null then "cp -r ${mkCSS css}/* $out" else ""}
          sed -i 's!@@body@@!{{template "${bodyTmpl}" .}}!' "${layout.template}"
          infuse -f ${metaJSON} ${definitions} "${layout.template}" -o "$out${route}"
        '';
    });

  mkPosts = { name, route, posts }:
    map (post:
    mkPost {
      name = "${name}-mkPost";
      route = "${route}/${post.date}.html";
      bodyTmpl = "post.tmpl";
      templates = { "post.tmpl" = ../templates/post.tmpl; };

      css = {
        route = "/css/blog.css";
        main = "blog.css";
        dependencies = cssDepsFor ../css "blog.css";
      };

      meta = {
        id = "blog";
        links = navLinks "/blog.html";
      } // post;
    }) posts;

  mkCSS = { route, dependencies, main }:
    mkDerivation {
      __structuredAttrs = true;

      name = "mkCSS";

      PATH =
        "${pkgs.coreutils}/bin:${pkgs.finescoYarnPackages}/node_modules/.bin";

      inherit dependencies main route;

      buildCommand = ''
        export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
        export LC_ALL="en_US.UTF-8"

        target=$out/$(dirname $route)
        mkdir -p $target

        for i in "''${!dependencies[@]}"; do
          cp "''${dependencies[$i]}" $i
        done

        postcss "$main" \
          -u postcss-import \
          -u postcss-cssnext \
          -u css-mqpacker \
          -o "$out$route"
      '';
    };

  mkMarkdownPage =
    { name, route, body, layout ? layouts.default, templates, meta ? { }, css ?
      null, ... }@args:
    let
      combinedTemplates = layout.templates // templates;
      markdown = parseMarkdown combinedTemplates."${body}";
      finalMeta = meta
        // (if css != null then { cssTag = cssTag css.route; } else { })
        // (markdown);
    in mkDerivation (args // {
      __structuredAttrs = true;

      inherit name combinedTemplates;

      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];

      markdownBody = markdown.body;

      buildCommand = let
        definitions =
          concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
        metaJSON = toFile "meta.json" (toJSON finalMeta);
        in ''
          for i in "''${!combinedTemplates[@]}"; do
            cp "''${combinedTemplates[$i]}" $i
          done

          mkdir -p $out
          ${if css != null then "cp -r ${mkCSS css}/* $out" else ""}

          echo "$markdownBody" > markdownBody.tmpl
          sed -i 's!@@body@@!{{template "markdown.tmpl" .}}!' "${layout.template}"
          sed -i 's!@@body@@!{{template "markdownBody.tmpl" .}}!' "markdown.tmpl"
          infuse -f ${metaJSON} -d markdownBody.tmpl ${definitions} "${layout.template}" -o "$out${route}"
        '';
    });

  copyFiles = from: to:
    mkDerivation {
      name = "copyFiles";
      PATH = makeBinPath [ pkgs.coreutils ];
      inherit from to;

      buildCommand = ''
        mkdir -p $out$to
        cp -r "$from"/* $out$to
      '';
    };

  cssDeps = src:
    let
      generated = mkDerivation {
        name = "cssDeps";
        PATH = makeBinPath [ pkgs.rubyEnv.wrappedRuby ];
        inherit src;
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LC_ALL = "en_US.UTF-8";

        buildCommand = ''
          ruby ${../scripts/css_deps.rb} "$src" > $out
        '';
      };
    in fromJSON (readFile generated);

  cssDepsFor = src: entryPoint:
    let allDeps = cssDeps src;
    in listToAttrs (map (v: {
      name = v;
      value = "${src + "/${v}"}";
    }) allDeps."${entryPoint}");

  commonAttrs = id:
    lib.recursiveUpdate {
      name = "${id}.html";
      route = "/${id}.html";
      body = "${id}.tmpl";
      templates = { "${id}.tmpl" = ../templates + "/${id}.tmpl"; };
      meta = { links = navLinks "/${id}.html"; };
    };

  commonPageAttrs = id:
    lib.recursiveUpdate (commonAttrs id {
      css = {
        route = "/css/${id}.css";
        main = "${id}.css";
        dependencies = cssDepsFor ../css "${id}.css";
      };

      meta = { id = "${id}"; };
    });

  commonBlogAttrs = id:
    lib.recursiveUpdate (commonAttrs id {
      templates = { "post-list.tmpl" = ../templates/post-list.tmpl; };

      css = {
        route = "/css/blog.css";
        main = "blog.css";
        dependencies = cssDepsFor ../css "blog.css";
      };

      meta = {
        id = "blog";
        posts = sortByRecent (loadPosts "/${id}/" (../. + "/${id}"));
      };
    });

  commonMarkdownAttrs = id:
    lib.recursiveUpdate {
      name = "${id}.html";
      route = "/${id}.html";
      body = "${id}.md";
      templates = {
        "${id}.md" = ../templates + "/${id}.md";
        "markdown.tmpl" = ../templates/markdown.tmpl;
      };

      css = {
        route = "/css/${id}.css";
        main = "${id}.css";
        dependencies = cssDepsFor ../css "${id}.css";
      };

      meta = {
        id = "${id}";
        title = "コラム";
        links = navLinks "/${id}.html";
      };
    };
}
