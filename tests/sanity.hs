{-# LANGUAGE CPP #-}
{-# LANGUAGE ViewPatterns #-}

import Prelude
import Control.Lens
import Control.Monad
import qualified Data.Attoparsec.ByteString.Char8 as P
import Data.ByteString (ByteString)
import Data.Thyme
import Data.Thyme.Time
import qualified Data.Time as T
import System.Locale
import Test.QuickCheck

import Common

#if MIN_VERSION_bytestring(0,10,0)
# if MIN_VERSION_bytestring(0,10,2)
import qualified Data.ByteString.Builder as B
# else
import qualified Data.ByteString.Lazy.Builder as B
# endif
import qualified Data.ByteString.Lazy as L
#else
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Text
#endif

{-# INLINE utf8String #-}
utf8String :: String -> ByteString
#if MIN_VERSION_bytestring(0,10,0)
utf8String = L.toStrict . B.toLazyByteString . B.stringUtf8
#else
utf8String = Text.encodeUtf8 . Text.pack
#endif

------------------------------------------------------------------------

prop_formatTime :: Spec -> UTCTime -> Property
prop_formatTime (Spec spec) t@(review thyme -> t')
        = printTestCase desc (s == s') where
    s = formatTime defaultTimeLocale spec t
    s' = T.formatTime defaultTimeLocale spec t'
    desc = "thyme: " ++ s ++ "\ntime:  " ++ s'

prop_parseTime :: Spec -> UTCTime -> Property
prop_parseTime (Spec spec) orig
        = printTestCase desc (fmap (review thyme) t == t') where
    s = T.formatTime defaultTimeLocale spec (review thyme orig)
    t = parseTime defaultTimeLocale spec s :: Maybe UTCTime
    t' = T.parseTime defaultTimeLocale spec s
    tp = P.parseOnly (timeParser defaultTimeLocale spec) . utf8String
    desc = "input: " ++ show s ++ "\nthyme: " ++ show t
        ++ "\ntime:  " ++ show t' ++ "\nstate: " ++ show (tp s)

------------------------------------------------------------------------

main :: IO ()
main = (exit . all isSuccess <=< mapM quickCheckResult) $
        prop_formatTime :
        prop_parseTime :
        []
  where
    isSuccess r = case r of Success {} -> True; _ -> False

