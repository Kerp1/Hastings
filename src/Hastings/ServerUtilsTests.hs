module Hastings.ServerUtilsTests where

import Test.QuickCheck
import Haste.App (SessionID, liftIO)
import Data.Word (Word64)
import Control.Concurrent (Chan, newChan)
import System.IO.Unsafe (unsafePerformIO)
import Data.List (nub)

import LobbyTypes
import Hastings.ServerUtils

-- Arbitrary instances for the Data types

-- |Arbitrary ClientEntry
-- Does not have any chat channels, and the LobbyChannel is created
-- by unsafePerformIO (!)
instance Arbitrary ClientEntry where
  arbitrary = do
    sessionIDWord64 <- arbitrary
    clientNr <- arbitrary :: Gen Int
    let chan = unsafePerformIO newChan
    return $ ClientEntry sessionIDWord64 ("ClientEntry " ++ show clientNr) [] chan

-- |Arbitrary GameData
-- Limits the maxAmountOfPlayers to 26.
instance Arbitrary GameData where
  arbitrary = do
    gameNr <- arbitrary :: Gen Int
    maxPlayers <- arbitrary :: Gen Int
    let maxPlayers' = 1 + (abs.flip mod 25) maxPlayers -- Reasonable amount of max players
    playersNum <- arbitrary :: Gen Int
    let playersNum' = (abs.flip mod maxPlayers') playersNum -- No more players than max nuber
    clients <- sequence [ arbitrary | _ <- [1..playersNum']]
    return $ GameData clients ("GameData " ++ show gameNr) maxPlayers'


-- Tests

prop_getUUIDFromGamesList :: [LobbyGame] -> Property
prop_getUUIDFromGamesList list = not (null list) ==>
  [fst x | x <- list ] == getUUIDFromGamesList list

prop_deletePlayerFromGame_length :: Int -> LobbyGame -> Property
prop_deletePlayerFromGame_length i g@(_, gameData) = not (null (players gameData)) ==>
  length (players gameData) - 1 == length (players newGameData)
  where
    (_, newGameData) = deletePlayerFromGame playerName g

    i' =  abs $ mod i (length $ players gameData)
    player = players gameData !! i'
    playerName = name player

-- |Property that checks that only the correct one has changed, and all others have the same length.
-- Runs nub on the list of players since sessionID's are meant to be unique
-- Also goes through each LobbyGame to make sure the GameID is unique.
-- Will fail if `18446744073709551615` is the sessionID of one of the clients.
prop_addPlayerToGame_length :: Int -> [LobbyGame] -> Property
prop_addPlayerToGame_length i list = not (null list) ==>
  addPlayerToGamePropTemplate i list fun
  where
    fun :: String -> [LobbyGame] -> [LobbyGame] -> Bool
    fun gameID list newList = all prop $ zip list newList
      where
        prop ((guuid,og), (_,ng)) | guuid == gameID = length (nub $ players og) + 1 == length (players ng)
                                  | otherwise       = length (players og) == length (players ng)

-- |Checks that only one lobbyGame has changed
prop_addPlayerToGame_unique :: Int -> [LobbyGame] -> Property
prop_addPlayerToGame_unique i list = not (null list) ==>
  addPlayerToGamePropTemplate i list (\_ list newList -> 1 >= foldr addIfChanged 0 (zip list newList))
  where
    addIfChanged ((guuid,og), (_,ng)) | length (players og) == length (players ng) = (+ 0)
                                      | otherwise                                  = (+ 1)
-- |Template for tests with addPlayerToGame
-- Requires a function that wants the GameID (of the game that was changed), and two lists of games
-- , one unchanged and one where a player has been added.
addPlayerToGamePropTemplate :: Int -> [LobbyGame] -> (String -> [LobbyGame] -> [LobbyGame] -> Bool) -> Bool
addPlayerToGamePropTemplate i list fun = fun gameID list' newList
  where
    list' = zipWith newLobbyGame list [0..]
    newLobbyGame (_, gameData) i = (show i, gameData)

    i' = abs $ mod i (length list')

    lobbyChan = unsafePerformIO newChan
    client = ClientEntry 18446744073709551615 "new client" [] lobbyChan
    gameID = fst $ list' !! i'
    newList = addPlayerToGame client gameID list'

    playersList list = players $ snd $ list !! i'

  -- other prop: check that it was not possible to join if max has been reached

-- |Checks that findGameWithID finds the correct game
prop_findGameWithID :: Int -> [LobbyGame] -> Property
prop_findGameWithID i list = not (null list) ==>
  case findGameWithID gameID list' of
    Nothing         -> False
    Just (guuid, _) -> gameID == guuid
  where
    i' = abs $ mod i (length list')
    gameID = fst $ list' !! i'

    list' = zipWith newLobbyGame list [0..]
    newLobbyGame (_, gameData) i = (show i, gameData)
