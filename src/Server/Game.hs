module Server.Game where

import Haste.App (SessionID)
import Control.Concurrent (modifyMVar_, readMVar)
import Data.UUID
import System.Random
import Data.ByteString.Char8 (ByteString, empty, pack, unpack)
import Crypto.PasswordStore (makePassword, verifyPassword)
import Control.Monad (when)

import Hastings.Utils
import Hastings.ServerUtils
import LobbyTypes

import qualified Hastings.Database.Game as GameDB
import qualified Hastings.Database.Fields as Fields
import qualified Database.Esqueleto as Esql

-- |Removes a player from it's game
leaveGame :: ConcurrentClientList -> SessionID -> IO ()
leaveGame mVarClients sid = do
  clientList <- readMVar mVarClients
  dbGame <- GameDB.retrieveGameBySid sid
  case dbGame of
     Just (Esql.Entity gameKey _) -> do
      GameDB.removePlayerFromGame sid gameKey
      sessionIds <- GameDB.retrieveSessionIdsInGame gameKey

      messageClientsWithSid KickedFromGame clientList [sid]
      messageClientsWithSid PlayerLeftGame clientList sessionIds

     _                            -> return ()

createGame :: ConcurrentClientList -> SessionID -> Int -> IO (Maybe String)
createGame mVarClients sid maxPlayers = do
  clientList <- readMVar mVarClients
  gen <- newStdGen
  let (uuid, g) = random gen
  let uuidStr = Data.UUID.toString uuid

  existingGame <- GameDB.retrieveGameByUUID uuidStr
  case existingGame of
    Just _  -> return Nothing
    Nothing -> do
      gameKey <- GameDB.saveGame uuidStr uuidStr maxPlayers sid ""
      GameDB.addPlayerToGame sid gameKey
      messageClients GameAdded clientList
      return $ Just uuidStr

-- |Lets a player join a game
playerJoinGame :: ConcurrentClientList  -- ^The list of all players connected
               -> SessionID             -- ^The SessionID of the player
               -> String                -- ^The UUID of the game to join
               -> String                -- ^The password of the game, if no password this can be ""
               -> IO Bool               -- ^Returns if able to join or not
playerJoinGame mVarClients sid gameID passwordString = do
  clientList <- readMVar mVarClients
  dbGame <- GameDB.retrieveGameByUUID gameID
  case dbGame of
    Just (Esql.Entity gameKey game) -> do
      let passwordOfGame = pack $ Fields.gamePassword game
      numberOfPlayersInGame <- GameDB.retrieveNumberOfPlayersInGame gameID

      if passwordOfGame == empty || verifyPassword (pack passwordString) passwordOfGame
        then if Fields.gameMaxAmountOfPlayers game > numberOfPlayersInGame
          then do
            GameDB.addPlayerToGame sid gameKey
            sessionIds <- GameDB.retrieveSessionIdsInGame gameKey
            messageClientsWithSid PlayerJoinedGame clientList sessionIds
            return True
          else do
            messageClientsWithSid (LobbyError "Game is full") clientList [sid]
            return False
        else do
          messageClientsWithSid (LobbyError "Wrong password") clientList [sid]
          return False
    _                              -> return False

-- |Finds the name of a game given it's identifier
findGameNameWithID :: String -> IO String
findGameNameWithID gameID = do
  dbGame <- GameDB.retrieveGameByUUID gameID
  case dbGame of
    Just (Esql.Entity _ game) -> return $ Fields.gameName game
    _                         -> return ""

-- |Finds the name of the game the client is currently in
findGameNameWithSid :: SessionID -> IO String
findGameNameWithSid sid = do
  dbGame <- GameDB.retrieveGameBySid sid
  case dbGame of
    Just (Esql.Entity _ game) -> return $ Fields.gameName game
    Nothing                   -> return ""

-- |Finds the name of the players of the game the current client is in
playerNamesInGameWithSid :: SessionID -> IO [String]
playerNamesInGameWithSid sid = do
  dbGame <- GameDB.retrieveGameBySid sid
  case dbGame of
    Just (Esql.Entity gameKey _) -> do
      playersInGame <- GameDB.retrievePlayersInGame gameKey
      return $ map (Fields.playerUserName . Esql.entityVal) playersInGame
    Nothing                      -> return []

-- |Kicks the player with index 'Int' from the list of players in
-- the game that the current client is in.
kickPlayerWithSid :: GamesList -> SessionID -> Int -> IO ()
kickPlayerWithSid mVarGames sid clientIndex = do
  gamesList <- readMVar mVarGames
  case findGameWithSid sid gamesList of
    Nothing   -> return ()
    Just game@(_,gameData) -> do
      modifyMVar_ mVarGames $ \games ->
        return $ updateListElem (deletePlayerFromGame clientIndex) (== game) games
      messageClients KickedFromGame [players gameData !! clientIndex]
      messageClients PlayerLeftGame $ players gameData

-- |Change the name of a 'LobbyGame' that the connected client is in
changeGameNameWithSid :: ConcurrentClientList -> SessionID -> Name -> IO ()
changeGameNameWithSid mVarClients sid newName = do
  clientList <- readMVar mVarClients
  dbGame <- GameDB.retrieveGameBySid sid
  case dbGame of
    Nothing                   -> return ()
    Just (Esql.Entity _ game) -> do
      GameDB.setNameOnGame (Fields.gameUuid game) newName
      messageClients GameNameChange clientList

-- |Changes the maximum number of players for a game
-- Requires that the player is the last in the player list (i.e. the owner)
changeMaxNumberOfPlayers :: SessionID -> Int -> IO ()
changeMaxNumberOfPlayers sid newMax = do
  dbGame <- GameDB.retrieveGameBySid sid
  case dbGame of
    Nothing                  -> return ()
    Just (Esql.Entity _ game) ->
      when (sid == Fields.gameOwner game) $
        GameDB.setNumberOfPlayersInGame (Fields.gameUuid game) newMax


-- |Sets the password (as a 'ByteString') of the game the client is in.
-- |Only possible if the client is the owner of the game.
setPasswordToGame :: GamesList -> SessionID -> String -> IO ()
setPasswordToGame mVarGames sid passwordString = do
  let password = pack passwordString
  hashedPassword <- makePassword password 17
  gamesList <- readMVar mVarGames
  case (findGameWithSid sid gamesList, isOwnerOfGame sid gamesList) of
    (Just game, True)          ->
      modifyMVar_ mVarGames $ \games ->
        return $ updateListElem
          (\(guuid, gData) -> (guuid, gData {gamePassword = hashedPassword}))
          (== game)
          games
    (Just (_,gameData), False) ->
      maybe
        (return ())
        (\client -> messageClients (LobbyError "Not owner of the game") [client])
        (lookupClientEntry sid (players gameData))

-- |Returns True if game is password protected, False otherwise. 'String' is the UUID of the game
isGamePasswordProtected :: GamesList -> String -> IO Bool
isGamePasswordProtected mVarGames guuid = do
  gamesList <- readMVar mVarGames
  case findGameWithID guuid gamesList of
    Nothing           -> return False
    Just (_,gameData) -> return $ gamePassword gameData /= empty
