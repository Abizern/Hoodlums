{-
 Hoodlums, October 2012

 Simplified rules:
 * A single deck is used, shuffled before each game
 * The PLAYER is dealt two cards.
   * If the hand is an ace and a picture card the PLAYER wins and the game is over.
 * The PLAYER chooses to Hit until:
   * The hand scores >21, the PLAYER loses and the game is over.
   * The hand scores 21, the PLAYER wins and the game is over.
   * The PLAYER chooses to stand.
 * The DEALER is dealt cards until the score is greater than 17
   * If the score is greater than 21, the PLAYER wins and the game is over.
   * If the score is greater than the PLAYER's hand, the DEALER wins and the game is over

 -}
module BlackJack where

import Control.Monad.State
import System.Random.Shuffle
import Control.Monad.Random
import Data.Maybe

data Suit = H | D | S | C
            deriving (Eq, Ord, Enum, Bounded)

instance Show Suit where
  show H = "♥"
  show D ="♦"
  show S = "♠"
  show C = "♣"

data Rank = A | Number Int | J | Q | K

instance Enum Rank where
    fromEnum A          = 1
    fromEnum (Number i) = i
    fromEnum J          = 11
    fromEnum Q          = 12
    fromEnum K          = 13
    toEnum   1          = A
    toEnum   11         = J
    toEnum   12         = Q
    toEnum   13         = K
    toEnum i
        | i > 1 && i < 11 = Number i
        | otherwise       = error "Invalid Rank!"

instance Bounded Rank where
    minBound = A
    maxBound = K

instance Show Rank where
    show A          = "A"
    show (Number i) = show i
    show J          = "J"
    show Q          = "Q"
    show K          = "K"

data Card = Card Rank Suit

instance Show Card where
    show (Card r s) = show r ++ show s

allEnums :: (Enum a, Bounded a) => [a]
allEnums = [minBound .. maxBound]

newDeck :: [Card]
newDeck = [Card r s | r <- allEnums, s <- allEnums]

shuffledDeck :: MonadRandom m => m [Card]
shuffledDeck = deckShuffle newDeck

deckShuffle :: MonadRandom m => [Card] -> m [Card]
deckShuffle = shuffleM

type Deck = [Card]

type BlackJackM = StateT Deck IO

runBlackJack :: BlackJackM a -> IO a
runBlackJack game = do
    d <- shuffledDeck
    evalStateT game d

reshuffle :: BlackJackM ()
reshuffle = shuffledDeck >>= put

dealACard :: BlackJackM Card
dealACard = do
    (c:d) <- get
    put d
    return c

dumpDeck :: BlackJackM ()
dumpDeck = do
    d <- get
    liftIO $ print d

data Turn = Hit | Stand

getTurn :: BlackJackM Turn
getTurn = do
    line <- liftIO $ getLine
    case line of
        "h" -> return Hit
        "s" -> return Stand
        _   -> (liftIO $ putStrLn "Invalid turn") >> getTurn

valueCard :: Card -> [Int]
valueCard (Card A _)          = [11,1]
valueCard (Card (Number i) _) = [i]
valueCard (Card _ _)          = [10]

valueHand :: [Card] -> Maybe Int
valueHand = listToMaybe . dropWhile (> 21) . allValues . map valueCard

allValues :: [[Int]] -> [Int]
allValues []  = [0]
allValues [x] = x
allValues (is:iss) = [ i + j | i <- is, j <- allValues iss ]

main = runBlackJack $ do
    dumpDeck
    {-c1 <- dealACard-}
    {-c2 <- dealACard-}
    {-let h = [c1, c2]-}
    {-liftIO $ print h-}
    {-liftIO $ print (valueHand h)-}
    {-dumpDeck-}
    let h = []
    h' <- loop h minHandTest (\h -> dealACard >>= return . (:h))
    liftIO $ print h'
    liftIO $ print (valueHand h')


minHandTest :: [Card] -> Bool
minHandTest h = case (valueHand h) of
                    Nothing           -> True
                    (Just n) | n > 12 -> True
                    _                 -> False

loop :: Monad m => a -> (a -> Bool) -> (a -> m a) -> m a
loop v p a
    | p v       = return v
    | otherwise = do
        v <- a v
        loop v p a
