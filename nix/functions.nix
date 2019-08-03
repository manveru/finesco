{ rootDir, layout, pageOptions ? [ ], environment ? "production", pkgs ? import ./nixpkgs.nix }@globalArgs:
let
  inherit (pkgs) stdenv lib writeText runCommand infuse;
  inherit (builtins)
    attrNames placeholder replaceStrings baseNameOf readDir attrValues fromJSON
    readFile mapAttrs toJSON toFile listToAttrs pathExists trace;
  inherit (lib)
    take sort makeBinPath concatMapStrings subtractLists attrByPath
    optionalAttrs;

  pp = value: trace value value;
in rec {
  inherit take;

  defaultLayout = tmplDepsFor (rootDir + "/templates/") globalArgs.layout;

  pages = pageOptions {
    inherit mkHtmlPage mkMarkdownPage mkPosts loadPosts lib sortByRecent;
  };

  isHidden = page: attrByPath [ "hidden" ] false page;

  links = subtractLists [ null ]
    (map (page: if isHidden page then null else { inherit (page) url title; })
    pages);

  sortByRecent = sort (a: b: a.date > b.date);

  loadPosts = baseUrl: location:
    (attrValues (mapAttrs (k: v:
    let markdown = parseMarkdown "${location + "/${k}"}";
    in (markdown // { url = "${baseUrl}${markdown.date}.html"; }))
    (readDir location)));

  navLinks = currentRoute:
    map (link:
    if currentRoute == link.url then
      ''<a href="${link.url}" class="active">${link.title}</a>''
    else
      ''<a href="${link.url}">${link.title}</a>'') links;

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

  tmplDeps = src:
    let
      generated = mkDerivation {
        name = "tmplDeps";
        PATH = makeBinPath [ pkgs.rubyEnv.wrappedRuby ];
        inherit src;
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LC_ALL = "en_US.UTF-8";

        buildCommand = ''
          ruby ${../scripts/tmpl_deps.rb} "$src" > $out
        '';
      };
    in fromJSON (readFile generated);

  tmplDepsFor = src: entryPoint:
    let allDeps = tmplDeps src;
    in listToAttrs (map (v: {
      name = v;
      value = "${src + "/${v}"}";
    }) allDeps."${entryPoint}");

  compileCSS = {id, ...}@page:
    let
      basename = "${attrByPath [ "meta" "css" ] id page}.css";
      route = "/css/${basename}";
    in {
      inherit route;
      file = mkCSS {
        inherit route;
        main = basename;
        dependencies = cssDepsFor (rootDir + "/css/") basename;
      };
    };

  compiledPages = listToAttrs (subtractLists [ null ] (map (page:
    if page ? compiler then {
      name = page.id;
      value = page.compiler ({
        name = page.id;

        meta = {
          inherit (page) id title url;
          inherit environment;
          links = navLinks page.url;
          cssTag = ''<link rel="stylesheet" href="${(compileCSS page).route}" />'';
        } // (optionalAttrs (page ? meta) page.meta);

        route = if page.url == "/" then "/index.html" else page.url;

        cssFile = (compileCSS page).file;

      } // (if pathExists (rootDir + "/templates/${page.id}.tmpl") then {
        templates = tmplDepsFor (rootDir + "/templates/") "${page.id}.tmpl";
        body = "${page.id}.tmpl";
      } else {
        templates = (tmplDepsFor (rootDir + "/templates/") "markdown.tmpl") // {
          "${page.id}.md" = (rootDir + "/templates/${page.id}.md");
        };
        body = "${page.id}.md";
      }));
    } else
      null) pages));

  mkSite = chooseParts:
    runCommand "finesco" {
      parts = chooseParts ({
        compiled = compiledPages;
        inherit copyFiles;
      });
    } ''
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

  mkTemplate = { name, route, body, layout ? defaultLayout, templates
    , meta ? { }, cssFile ? null, buildPhase ? "", ... }@args:
    let
      combinedTemplates = layout // templates;
      definitions =
        concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
      metaJSON = toFile "meta.json" (toJSON meta);
    in mkDerivation ({
      name = "mkTemplate-${name}";
      __structuredAttrs = true;
      inherit combinedTemplates;
      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];
      layoutTemplate = globalArgs.layout;

      buildCommand = ''
        for i in "''${!combinedTemplates[@]}"; do
          cp "''${combinedTemplates[$i]}" $i
        done

        mkdir -p $out
        ${if cssFile != null then "cp -r ${cssFile}/* $out" else ""}

        ${buildPhase { inherit metaJSON definitions; }}
      '';
    });

  mkHtmlPage = { body, route, ... }@args:
    mkTemplate (args // {
      buildPhase = { metaJSON, definitions }: ''
        sed -i 's!@@body@@!{{template "${body}" .}}!' "$layoutTemplate"
        infuse -f ${metaJSON} ${definitions} "$layoutTemplate" -o "$out${route}"
      '';
    });

  mkPost = { name, route, bodyTmpl, layout ? defaultLayout, templates
    , meta ? { }, cssFile ? null, ... }@args:
    let combinedTemplates = layout // templates;
        definitions =
          concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
        metaJSON = toFile "meta.json" (toJSON meta);
    in mkDerivation (args // {
      __structuredAttrs = true;
      inherit name combinedTemplates;
      layoutTemplate = globalArgs.layout;
      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];

      buildCommand = ''
          for i in "''${!combinedTemplates[@]}"; do
            cp "''${combinedTemplates[$i]}" $i
          done

          mkdir -p $out/$(dirname ${route})
          ${if cssFile != null then "cp -r ${cssFile}/* $out" else ""}
          sed -i 's!@@body@@!{{template "${bodyTmpl}" .}}!' "$layoutTemplate"
          infuse -f ${metaJSON} ${definitions} "$layoutTemplate" -o "$out${route}"
        '';
    });

  mkPosts = { name, route, posts }:
    map (post:
    let
    css = compileCSS {id = "blog"; };
      in
    mkPost {
      name = "${name}-mkPost";
      route = "${route}/${post.date}.html";
      bodyTmpl = "post.tmpl";
      templates = { "post.tmpl" = ../templates/post.tmpl; };

      cssFile = css.file;

      meta = {
        inherit environment;
        id = "blog";
        links = navLinks "/blog.html";
        cssTag = ''<link rel="stylesheet" href="${css.route}" />'';
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

  mkMarkdownPage = { name, route, body, layout ? defaultLayout, templates
    , meta ? { }, cssFile ? null, ... }@args:
    let
      combinedTemplates = layout // templates;
      markdownMeta = parseMarkdown combinedTemplates."${body}";
      finalMeta = meta // markdownMeta;
      definitions =
        concatMapStrings (f: ''-d "${f}" '') (attrNames combinedTemplates);
      metaJSON = toFile "meta.json" (toJSON finalMeta);
    in mkDerivation ({
      __structuredAttrs = true;

      inherit name combinedTemplates;

      PATH = makeBinPath [ pkgs.coreutils pkgs.infuse pkgs.gnused ];

      markdownBody = markdownMeta.body;
      layoutTemplate = globalArgs.layout;

      buildCommand = ''
        for i in "''${!combinedTemplates[@]}"; do
          cp "''${combinedTemplates[$i]}" $i
        done

        mkdir -p $out
        ${if cssFile != null then "cp -r ${cssFile}/* $out" else ""}

        echo "$markdownBody" > markdownBody.tmpl
        sed -i 's!@@body@@!{{template "markdown.tmpl" .}}!' "$layoutTemplate"
        sed -i 's!@@body@@!{{template "markdownBody.tmpl" .}}!' "markdown.tmpl"
        infuse -f ${metaJSON} -d markdownBody.tmpl ${definitions} "$layoutTemplate" -o "$out${route}"
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
}
