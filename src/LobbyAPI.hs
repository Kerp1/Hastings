{-# LANGUAGE CPP #-}
-- |A module for defining the api the server provides towards the client
module LobbyAPI where
import Haste.App
import qualified Control.Concurrent as CC
import LobbyTypes
#ifdef __HASTE__
#define REMOTE(x) (remote undefined)
#else
import qualified LobbyServer as Server
#define REMOTE(x) (remote x)
#endif
-- |The api provided by the server.
data LobbyAPI = LobbyAPI
  { connect :: Remote (String -> Server ())
    -- |Creates a game on the server with the current client as host.
    -- |The 'Int' represents the default max number of players
  , createGame :: Remote (Int -> Server (Maybe String))
  , getGamesList :: Remote (Server [String])
    -- |Joins a game with the 'UUID' representetd by the 'String'.
    -- |The second 'String' is the password for the game, can be left as "" if there is no password.
    -- |Returns if the client successfully joined or not.
  , joinGame :: Remote (String -> String -> Server Bool)
  , findPlayersInGame :: Remote (Server [String])
    -- |Finds the name of the game with String as identifier
  , findGameNameWithID :: Remote (String -> Server String)
    -- |Finds the name of the game that the client is in
  , findGameName :: Remote (Server String)
  , getPlayerNameList :: Remote (Server [String])
    -- |Kicks a player frrom a game.
  , kickPlayer :: Remote (Name -> Server ())
    -- |Changes the nickname of the active player
  , changeNickName :: Remote (Name -> Server ())
    -- |Change the name of the game to the new name
  , changeGameName :: Remote (Name -> Server())
    -- |Reads the value from the lobby channel
  , readLobbyChannel :: Remote (Server LobbyMessage)
   -- |Changes the maximum amount of players
   , changeMaxNumberOfPlayers :: Remote (Int -> Server ())
    -- |Get clients name based on sid
  , getClientName :: Remote (Server String)
    -- |Join named chat
  , joinChat :: Remote (Name -> Server ())
    -- |Send ChatMessage over Named channel
  , sendChatMessage :: Remote (Name -> ChatMessage -> Server ())
    -- |Reads next ChatMessage from named chat channel.
  , readChatChannel :: Remote (Name -> Server ChatMessage)
    -- |Sets a password to the game the client is in as 'ByteString'
    -- |Only allowed if the current player is owner of it's game
  , setPassword :: Remote (String -> Server ())
    -- |Returns if the game is protected by a password or not. 'String' is the Game ID
  , isGamePasswordProtected :: Remote (String -> Server Bool)
  }

-- |Creates an instance of the api used by the client to communicate with the server.
newLobbyAPI :: LobbyState -> App LobbyAPI
newLobbyAPI (playersList, gamesList, chatList) =
   LobbyAPI <$> REMOTE((Server.connect playersList chatList))
            <*> REMOTE((Server.createGame gamesList playersList))
            <*> REMOTE((Server.getGamesList gamesList))
            <*> REMOTE((Server.playerJoinGame playersList gamesList))
            <*> REMOTE((Server.playerNamesInGameWithSid gamesList))
            <*> REMOTE((Server.findGameNameWithID gamesList))
            <*> REMOTE((Server.findGameNameWithSid gamesList))
            <*> REMOTE((Server.getConnectedPlayerNames playersList))
            <*> REMOTE((Server.kickPlayerWithSid gamesList))
            <*> REMOTE((Server.changeNickName playersList gamesList))
            <*> REMOTE((Server.changeGameNameWithSid gamesList playersList))
            <*> REMOTE((Server.readLobbyChannel playersList))
            <*> REMOTE((Server.changeMaxNumberOfPlayers gamesList))
            <*> REMOTE((Server.getClientName playersList))
            <*> REMOTE((Server.joinChat playersList chatList))
            <*> REMOTE((Server.sendChatMessage playersList chatList))
            <*> REMOTE((Server.readChatChannel playersList))
            <*> REMOTE((Server.setPasswordToGame gamesList))
            <*> REMOTE((Server.isGamePasswordProtected gamesList))
