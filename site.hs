{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid                    ( mappend )
import           Hakyll
import           Control.Applicative            ( Alternative(..) )
import           Text.Regex.PCRE                ( (=~) )
import           Debug.Trace                    ( trace )

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

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match "scss/*.scss" $ do
    route $ setExtension "css"
    compile $ sassCompiler

  match "posts/*" $ do
    route $ setExtension "html"
    compile
      $   pandocCompiler
      >>= saveSnapshot "content"
      >>= loadAndApplyTemplate "templates/post.html"    postCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

  create ["blog.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx =
            listField "posts" postCtx (return posts)
              `mappend` constField "title" "Archives"
              `mappend` constField "id"    "blog"
              `mappend` standardContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/blog.html"    archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      let indexCtx = constField "title" "Home" `mappend` standardContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  createHtmlPage "about"   "会社概要"
  createHtmlPage "contact" "お問い合わせ"
  createHtmlPage "soudan"  "ご相談の流れ"

  match "templates/*.md" $ do
    route $ gsubRoute "templates/" (const "") `composeRoutes` setExtension
      "html"
    compile
      $   pandocCompiler
      >>= loadAndApplyTemplate "templates/markdown.html" standardContext
      >>= loadAndApplyTemplate "templates/default.html" standardContext
      >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler


postCtx :: Context String
postCtx =
  dateField "date" "%Y-%m-%d"
    `mappend` teaserField "teaser" "content"
    `mappend` constField "id" "blog"
    `mappend` standardContext

standardContext = functionField "navLink" navLink <> defaultContext

sassCompiler :: Compiler (Item String)
sassCompiler =
  getResourceString
    >>= withItemBody
          (            "sass"
          `unixFilter` [ "-s"
                       , "--scss"
                       , "--style"
                       , "compressed"
                       , "--load-path"
                       , "scss"
                       ]
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
        template = (fromFilePath ("templates/" ++ name ++ ".html"))

    makeItem ""
      >>= loadAndApplyTemplate template                 htmlCtx
      >>= loadAndApplyTemplate "templates/default.html" htmlCtx
      >>= relativizeUrls

optionalField :: String -> (Item a -> Maybe (Compiler String)) -> Context a
optionalField key f = field key $ \i -> case f i of
  Nothing    -> empty
  Just value -> value


navLink :: [String] -> Item String -> Compiler String
navLink args item =
  return $ "<a " ++ classAttr ++ "href='" ++ to ++ "'>" ++ title ++ "</a>"
 where
  [to, title] = args
  itemName    = show $ itemIdentifier item
  classAttr   = if (navLinkIsActive to itemName) then " class='active' " else ""

navLinkIsActive :: String -> String -> Bool
navLinkIsActive to itemName
  | Just m <- matchPattern "^([^/.]+)\\.html$"
  = to == "/" ++ m ++ ".html"
  | Just m <- matchPattern "^posts/([^/.]+)\\.md$"
  = to == "/blog.html"
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
