-- |Contains all functions related to DOM manipulation
module Lobby
  where

import Haste (Interval(Once), setTimer)
import Haste.App
import Haste.DOM
import Haste.Events

import Data.Maybe
import Data.List

import LobbyTypes
import LobbyAPI
import GameAPI
import Haste.App.Concurrent
import qualified Control.Concurrent as CC

initDOM :: Client ()
initDOM = do
  cssLink <- newElem "link" `with`
    [
      prop "rel"          =: "stylesheet",
      prop "type"         =: "text/css",
      prop "href"         =: "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css",
    --prop "integrity"    =: "sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7",
      prop "crossorigin"  =: "anonymous"
    ]

  appendChild documentBody cssLink

createBootstrapTemplate :: String -> Client Elem
createBootstrapTemplate parentName = do

  containerDiv <- newElem "div" `with`
    [
      attr "class" =: "container-fluid",
      attr "id"    =: "container-fluid"
    ]

  rowDiv <- newElem "div" `with`
    [
      attr "class" =: "row",
      attr "id"    =: "row"
    ]

  leftPaddingColDiv <- newElem "div" `with`
    [
      attr "class" =: "col-md-3",
      attr "id"    =: "leftContent"
    ]
  rightPaddingColDiv <- newElem "div" `with`
    [
      attr "class" =: "col-md-3",
      attr "id"    =: "rightContent"
    ]

  centerColDiv <- newElem "div" `with`
    [
      attr "class" =: "col-md-6",
      attr "id"    =: "centerContent"
    ]
  parentDiv <- newElem "div" `with`
    [
      prop "id" =: parentName
    ]

  appendChild documentBody containerDiv
  appendChild containerDiv rowDiv
  appendChild rowDiv parentDiv
  appendChild parentDiv leftPaddingColDiv
  appendChild parentDiv centerColDiv
  appendChild parentDiv rightPaddingColDiv

  return parentDiv
-- |Creates the initial DOM upon entering the lobby
createLobbyDOM :: LobbyAPI -> Client ()
createLobbyDOM api = do

  lobbyDiv <- createBootstrapTemplate "lobby"

  createGamebtn <- newElem "button" `with`
    [
      prop "id" =: "createGamebtn"
    ]
  crGamebtnText <- newTextElem "Create new game"

  header <- newElem "h1" `with`
    [
      attr "class" =: "text-center"
    ]

  headerText <- newTextElem "Hastings Lobby"
  appendChild header headerText

  nickDiv <- newElem "div" `with`
    [
      prop "id" =: "nickNameDiv"
    ]
  nickNameText <- newTextElem "Change nick name"
  nickNameField <- newElem "input" `with`
    [
      attr "type" =: "text",
      attr "id" =: "nickNameField"
    ]
  nickNameButton <- newElem "button" `with`
    [
      attr "id" =: "nickNameBtn"
    ]
  nickNameBtnText <- newTextElem "Change"

  appendChild nickNameButton nickNameBtnText
  appendChild nickDiv nickNameText
  appendChild nickDiv nickNameField
  appendChild nickDiv nickNameButton
  addChildrenToRightColumn [nickDiv]

  appendChild createGamebtn crGamebtnText

  playerList <- newElem "div" `with`
    [
      prop "id" =: "playerList"
    ]

  leftContent <- elemById "leftContent"
  liftIO $ createChatDOM $ fromJust leftContent

  appendChild documentBody lobbyDiv

  addChildrenToLeftColumn [playerList]
  addChildrenToCenterColumn [header, createGamebtn]

  onEvent nickNameField KeyPress $ \13 -> nickUpdateFunction

  clickEventString "nickNameBtn" nickUpdateFunction

  return ()

  where
    nickUpdateFunction =
      withElem "nickNameField" $ \field -> do
        newName <- getValue field
        case newName of
          Just ""   -> return ()
          Just name -> do
            setProp field "value" ""
            onServer $ changeNickName api <.> name
          Nothing   -> return ()

createChatDOM :: Elem -> IO ()
createChatDOM parentDiv = do

  br <- newElem "br"

  chatDiv <- newElem "div" `with`
    [
      attr "id" =: "chatDiv"
    ]

  chatBox <- newElem "textarea" `with`
    [
      attr "id"       =: "chatBox",
      attr "rows"     =: "10",
      attr "cols"     =: "18",
      attr "readonly" =: ""
    ]

  messageBox <- newElem "input" `with`
    [
      attr "type" =: "text",
      attr "id"   =: "messageBox",
      attr "cols" =: "60"
    ]

  appendChild parentDiv chatDiv
  appendChild chatDiv chatBox
  appendChild chatDiv br
  appendChild chatDiv messageBox

-- |Creates the DOM for a 'LobbyGame' inside the lobby
-- Useful since the Client is unaware of the specific 'LobbyGame' but can get the name and list with 'Name's of players from the server.
createGameDOM :: LobbyAPI -> String -> Client ()
createGameDOM api gameID = do
  parentDiv <- createBootstrapTemplate "lobbyGame"
  gameName <- onServer $ findGameName api <.> gameID
  players <- onServer $ findPlayersInGame api <.> gameID
  nameOfGame <- newTextElem gameName
  header <- newElem "h1" `with`
    [
      attr "id" =: "gameHeader",
      style "text-align" =: "center",
      style "margin-left" =: "auto",
      style "margin-right" =: "auto"
    ]
  appendChild header nameOfGame

  createStartGameBtn <- newElem "button" `with`
    [
      prop "id" =: "startGameButton"
    ]
  createStartGameBtnText <- newTextElem "Start game"
  appendChild createStartGameBtn createStartGameBtnText

  list <- newElem "div" `with`
    [
      prop "id" =: "playerList"
    ]
  listhead <- newTextElem "Players: "
  appendChild list listhead

  mapM_ (\p -> do
              name <- newTextElem $ p ++ " "
              appendChild list name
        ) players

  mapM_ (addPlayerWithKickToPlayerlist api gameID list) players

  gameNameDiv <- newElem "div"
  gameNameText <- newTextElem "Change game name"
  gameNameField <- newElem "input" `with`
    [
      attr "type" =: "text",
      attr "id" =: "gameNameField"
    ]
  gameNameButton <- newElem "button" `with`
    [
      attr "id" =: "gameNameBtn"
    ]
  gameNameBtnText <- newTextElem "Change"
  appendChild gameNameButton gameNameBtnText

  appendChild gameNameDiv gameNameText
  appendChild gameNameDiv gameNameField
  appendChild gameNameDiv gameNameButton

  addChildrenToLeftColumn [createStartGameBtn, list]
  addChildrenToRightColumn [gameNameDiv]
  addChildrenToCenterColumn [header]

  onEvent gameNameField KeyPress $ \13 -> gameUpdateFunction

  clickEventString "gameNameBtn" gameUpdateFunction

  return ()

  where
    gameUpdateFunction =
      withElem "gameNameField" $ \field -> do
        newName <- getValue field
        case newName of
          Just ""   -> return ()
          Just name -> do
            setProp field "value" ""
            onServer $ changeGameName api <.> gameID <.> name
          Nothing   -> return ()

-- |Deletes the DOM created for the intial lobby view
deleteLobbyDOM :: IO ()
deleteLobbyDOM = deleteDOM "container-fluid"

-- |Deletes the DOM created for a game in the lobby
deleteGameDOM :: IO ()
deleteGameDOM = deleteDOM "container-fluid"

-- |Helper function that deletes DOM given an identifier from documentBody
deleteDOM :: String -> IO ()
deleteDOM s = withElem s $ \element -> deleteChild documentBody element

-- |Creates a button for creating a 'LobbyGame'
createGameBtn :: LobbyAPI -> GameAPI-> Client ()
createGameBtn lapi gapi = do
  clickEventString "createGamebtn" onCreateBtnMouseClick
  return ()
  where
    onCreateBtnMouseClick = do
      maybeUuid <- onServer (createGame lapi)
      case maybeUuid of
        Nothing          -> return ()
        Just gameUuid -> do
          switchToGameDOM gameUuid
          withElem "playerList" $ \pdiv ->
            fork $ listenForChanges (players gameUuid) (changeWithKicks gameUuid) 1000 pdiv
          withElem "gameHeader" $ \gh ->
            fork $ changeHeader gameUuid gh ""
          clickEventString "startGameButton" $ do
              gameDiv <- newElem "div" `with`
                [
                  prop "id" =: "gameDiv"
                ]
              names <- onServer (players gameUuid)
              startGame gapi names gameDiv
          return ()

    switchToGameDOM guid = do
      liftIO deleteLobbyDOM
      createGameDOM lapi guid

    players gameUuid = findPlayersInGame lapi <.> gameUuid

    changeWithKicks = addPlayerWithKickToPlayerlist lapi

    -- Method that updates the header, will be deprecated when implementing channels for UI
    changeHeader :: String -> Elem -> String -> Client ()
    changeHeader gameUuid elem prevName = do
      gameName <- onServer $ findGameName lapi <.> gameUuid
      if gameName == prevName
        then
          setTimer (Once 1000) $ changeHeader gameUuid elem prevName
        else do
          clearChildren elem
          gameNameText <- newTextElem gameName
          appendChild elem gameNameText
          setTimer (Once 1000) $ changeHeader gameUuid elem gameName
      return ()


-- |Creates a listener for a click event with the Elem with the given String and a function.
clickEventString :: String -> Client () -> Client HandlerInfo
clickEventString identifier fun =
  withElem identifier $ \e ->
    clickEventElem e fun

-- |Creates a listener for a click event with the given 'Elem' and a function.
clickEventElem :: Elem -> Client () -> Client HandlerInfo
clickEventElem e fun =
   onEvent e Click $ \(MouseData _ mb _) ->
      case mb of
        Just MouseLeft -> fun
        Nothing        -> return ()

-- |Adds DOM for a game
addGame :: LobbyAPI -> String -> Client ()
addGame api gameID =
  withElems ["lobby", "centerContent", "createGamebtn"] $ \[lobbyDiv, centerContent, createGamebtn] -> do
    gameDiv <- newElem "div"
    gameName <- onServer $ findGameName api <.> gameID
    gameEntry <- newElem "button" `with`
      [
        prop "id" =: gameName
      ]
    textElem <- newTextElem gameName
    appendChild gameEntry textElem
    appendChild gameDiv gameEntry
    insertChildBefore centerContent createGamebtn gameDiv

    clickEventString gameName $ do
      onServer $ joinGame api <.> gameID
      players <- onServer $ findPlayersInGame api <.> gameID
      liftIO deleteLobbyDOM
      createGameDOM api gameID
      withElem "playerList" $ \pdiv ->
          fork $ listenForChanges (findPlayersInGame api <.> gameID) (addPlayerWithKickToPlayerlist api gameID) 1000 pdiv

    return ()

-- |Queries the server for a list in an interval, applies a function for every item in the list .
listenForChanges :: (Eq a, Binary a) => Remote (Server [a]) -> (Elem -> a -> Client ()) -> Int -> Elem -> Client ()
listenForChanges remoteCall addChildrenToParent updateDelay parent = listenForChanges' []
  where
    listenForChanges' currentData = do
      remoteData <- onServer remoteCall
      if currentData == remoteData
        then
          setTimer (Once updateDelay) $ listenForChanges' currentData
        else
          (do
            clearChildren parent
            mapM_ (addChildrenToParent parent) remoteData
            setTimer (Once updateDelay) $ listenForChanges' remoteData)
      return ()

-- |Convenience function for calling on the kick function.
kickFunction :: String -> Name -> LobbyAPI -> Client ()
kickFunction string name api = onServer $ kickPlayer api <.> string <.> name

-- |Adds the playername and a button to kick them followed by a <br> tag to the given parent.
addPlayerWithKickToPlayerlist :: LobbyAPI -> String -> Elem -> String -> Client ()
addPlayerWithKickToPlayerlist api gameID parent name = do
  textElem <- newTextElem name
  br <- newElem "br"
  kickBtn <- newElem "button"
  kick <- newTextElem "kick"
  clickEventElem kickBtn $ kickFunction gameID name api
  appendChild kickBtn kick
  appendChild parent textElem
  appendChild parent kickBtn
  appendChild parent br

-- |Adds the playername followed by a <br> tag to the given parent.
addPlayerToPlayerlist :: Elem -> String -> Client ()
addPlayerToPlayerlist parent name = do
  textElem <- newTextElem name
  br <- newElem "br"
  appendChild parent textElem
  appendChild parent br

-- |Adds the DOM for a list of games
addGameToDOM :: LobbyAPI -> String -> Client ()
addGameToDOM api gameName = do
  gameDiv <- newElem "div"
  gameEntry <- newElem "button" `with`
    [
      prop "id" =: gameName
    ]
  textElem <- newTextElem gameName
  appendChild gameEntry textElem
  appendChild gameDiv gameEntry
  appendChild documentBody gameDiv

  clickEventString gameName $ onServer $ joinGame api <.> gameName
  return ()

addChildrenToCenterColumn :: [Elem] -> Client ()
addChildrenToCenterColumn = addChildrenToParent  "centerContent"

addChildrenToLeftColumn :: [Elem] -> Client ()
addChildrenToLeftColumn = addChildrenToParent "leftContent"

addChildrenToRightColumn :: [Elem] -> Client ()
addChildrenToRightColumn = addChildrenToParent "rightContent"

addChildrenToParent :: String -> [Elem] -> Client ()
addChildrenToParent parent children = do
  parentElem <- elemById parent
  mapM_ (appendChild $ fromJust parentElem) children
