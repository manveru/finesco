{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid                    ( mappend )
import           Hakyll
import           Control.Applicative            ( )
import           Text.Regex.PCRE                ( (=~) )

main :: IO ()
main = hakyll $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "images/uploads/*" $ do
    route idRoute
    compile copyFileCompiler

  match "fonts/*" $ do
    route idRoute
    compile copyFileCompiler

  match "js/*" $ do
    route idRoute
    compile copyFileCompiler

  match "scss/*.scss" $ do
    route $ setExtension "css"
    compile $ sassCompiler

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- firstTwo =<< recentFirst =<< loadAll "posts/*.md"
      let indexCtx = constField "title" "Home"
            `mappend` listField "posts" postCtx (return posts)
            `mappend` standardContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*.md" $ do
    route $ gsubRoute "templates/" (const "") `composeRoutes` setExtension
      "html"
    compile
      $   pandocCompiler
      >>= loadAndApplyTemplate "templates/markdown.html" standardContext
      >>= loadAndApplyTemplate "templates/default.html"  standardContext
      >>= relativizeUrls

  createBlogPosts "posts/*.md" "templates/post.html"
  createBlogList "Blog" "blog.html" "posts/*.md" "templates/blog.html"

  createBlogPosts "info/*.md" "templates/post.html"
  createBlogList "Information" "info.html" "info/*.md" "templates/info.html"

  createHtmlPage "about"   "会社概要"
  createHtmlPage "contact" "お問い合わせ"
  createHtmlPage "soudan"  "ご相談の流れ"
  createHtmlPage "english" "ENGLISH"

  match "templates/*" $ compile templateBodyCompiler

firstTwo :: Monad m => [a] -> m [a]
firstTwo items = return $ take 2 items

postCtx :: Context String
postCtx =
  dateField "date" "%Y-%m-%d"
    `mappend` teaserField "teaser" "content"
    `mappend` constField "id" "blog"
    `mappend` metadataField
    `mappend` standardContext

standardContext :: Context String
standardContext = functionField "navLink" navLink <> defaultContext

sassCompiler :: Compiler (Item String)
sassCompiler =
  getResourceString
    >>= withItemBody
          (unixFilter
            "sass"
            ["-s", "--scss", "--style", "expanded", "--load-path", "scss"]
          )
    >>= return
    .   fmap compressCss

createHtmlPage :: String -> String -> Rules ()
createHtmlPage name title = create [fromFilePath (name ++ ".html")] $ do
  route idRoute
  compile $ do
    let htmlCtx =
          constField "title" title
            `mappend` constField "id" name
            `mappend` standardContext
        templateFile = (fromFilePath ("templates/" ++ name ++ ".html"))

    makeItem ""
      >>= loadAndApplyTemplate templateFile             htmlCtx
      >>= loadAndApplyTemplate "templates/default.html" htmlCtx
      >>= relativizeUrls

createBlogPosts :: Pattern -> Identifier -> Rules ()
createBlogPosts glob templateFile = match glob $ do
  route $ setExtension "html"
  compile
    $   pandocCompiler
    >>= saveSnapshot "content"
    >>= loadAndApplyTemplate templateFile             postCtx
    >>= loadAndApplyTemplate "templates/default.html" postCtx
    >>= relativizeUrls

createBlogList :: String -> Identifier -> Pattern -> Identifier -> Rules ()
createBlogList title target glob templateFile = create [target] $ do
  route idRoute
  compile $ do
    posts <- recentFirst =<< loadAll glob
    let blogCtx =
          constField "id" "blog"
          `mappend` constField "title" title
            `mappend` listField "posts" postCtx (return posts)
            `mappend` standardContext

    makeItem ""
      >>= loadAndApplyTemplate templateFile             blogCtx
      >>= loadAndApplyTemplate "templates/default.html" blogCtx
      >>= relativizeUrls


navLink :: [String] -> Item String -> Compiler String
navLink args item =
  return $ "<a " ++ classAttr ++ "href='" ++ to ++ "'>" ++ title ++ "</a>"
 where
  [to, title] = args
  itemName    = show $ itemIdentifier item
  classAttr   = if (navLinkIsActive to itemName) then " class='active' " else ""

navLinkIsActive :: String -> String -> Bool
navLinkIsActive to itemName
  | to == "/" && itemName == "index.html"
  = True
  | Just m <- matchPattern "^([^/.]+)\\.html$"
  = to == "/" ++ m ++ ".html"
  | Just _ <- matchPattern "^posts/([^/.]+)\\.md$"
  = to == "/blog.html"
  | Just _ <- matchPattern "^info/([^/.]+)\\.md$"
  = to == "/info.html"
  | Just m <- matchPattern "^([^/.]+)\\.md$"
  = to == "/" ++ m ++ ".md"
  | Just m <- matchPattern "^templates/([^.]+)\\.md$"
  = to == "/" ++ m ++ ".html"
  | otherwise
  = error (to ++ " / " ++ itemName)
 where
  firstMatch :: (String, String, String, [String]) -> Maybe String
  firstMatch (_, _, _, [name]) = Just name
  firstMatch _                 = Nothing
  matchPattern :: String -> Maybe String
  matchPattern pat = firstMatch $ itemName =~ pat
