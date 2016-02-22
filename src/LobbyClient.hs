-- |Module for all of the client only code
module LobbyClient where
import Lobby
import Haste.App
import LobbyAPI
import Haste.DOM
import Haste.Concurrent
import Data.Maybe

-- |Main mehtod for the client.
clientMain :: LobbyAPI -> Client ()
clientMain api = do
  liftIO createLobbyDOM

  name <- prompt "Hello! Please enter your name:"
  onServer $ handshake api <.> name

  createGameBtn (createGame api) (findPlayersInGame api)

  gameList <- onServer $ getGamesList api
  mapM_ (addGame (joinGame api)) gameList

  playerDiv <- elemById "playerList"
  fork $ listenForChanges (getPlayerList api) addPlayerToPlayerlist 1000 $ fromJust playerDiv


  return ()
