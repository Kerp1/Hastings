-- |All types that are used by the Lobby are placed in here.
module LobbyTypes where
import qualified Control.Concurrent as CC
import Haste.App
import Data.List
import Data.Word
import Haste.Binary (Binary, Get)
import Data.ByteString.Char8 (ByteString)
import ChineseCheckers.Table (GameAction)

-- |A type synonym to clarify that some Strings are Names.
type Name = String
-- |A client entry is a player with a SessionID as key.
data ClientEntry = ClientEntry {sessionID    :: SessionID
                               ,name         :: Name
                               ,chats        :: [Chat]
                               ,lobbyChannel :: CC.Chan LobbyMessage
                               ,gameChannel  :: CC.Chan GameAction}
clientEntry sid name lobbyChannel gameChannel = ClientEntry sid name [] lobbyChannel gameChannel


instance Show ClientEntry where
  show c = "sessionID: " ++ show (sessionID c) ++ " name: " ++ show (name c)

instance Eq ClientEntry where
  c1 == c2 = sessionID c1 == sessionID c2
  c1 /= c2 = sessionID c1 /= sessionID c2

-- |A list with all the players connected to the game.
type ConcurrentClientList = CC.MVar [ClientEntry]

-- | The state of the lobby being passed around.
type LobbyState = (Server ConcurrentClientList, Server ConcurrentChatList)

-- |A chat message sent on a channel.
data ChatMessage = ChatMessage       {from    :: Name
                                     ,content :: String}
                 | ChatJoin
                 | ChatAnnounceJoin  {from :: Name}
                 | ChatLeave
                 | ChatAnnounceLeave {from :: Name}
                 | ChatError {errorMessage :: String}

-- |A chat has a name and all sessionIDs currently in the chat.
type Chat = (Name, CC.Chan ChatMessage)

instance Binary ChatMessage where
  put (ChatMessage from content) = do
    put (0 :: Word8)
    put from
    put content
  put  ChatJoin =
    put (1 :: Word8)
  put (ChatAnnounceJoin from) = do
    put (2 :: Word8)
    put from
  put  ChatLeave =
    put (3 :: Word8)
  put (ChatAnnounceLeave from) = do
    put (4 :: Word8)
    put from

  get = do
    tag <- get :: Get Word8
    case tag of
      0 -> do
        from <- get :: Get String
        content <- get :: Get String
        return $ ChatMessage from content
      1 ->
        return ChatJoin
      2 -> do
        from <- get :: Get String
        return $ ChatAnnounceJoin from
      3 ->
        return ChatLeave
      4 -> do
        from <- get :: Get String
        return $ ChatAnnounceLeave from

-- |A list of all the chats in the lobby.
type ConcurrentChatList = CC.MVar [Chat]

-- |LobbyMessage is a message to a client idicating some udate to the state that the cliet has to adapt to.
data LobbyMessage = NickChange | GameNameChange | KickedFromGame | GameAdded | ClientJoined
      | ClientLeft | PlayerJoinedGame | PlayerLeftGame | StartGame | LobbyError {lobbyErrorMessage :: String}

instance Binary LobbyMessage where
  put NickChange       = put (0 :: Word8)
  put GameNameChange   = put (1 :: Word8)
  put KickedFromGame   = put (2 :: Word8)
  put GameAdded        = put (3 :: Word8)
  put ClientJoined     = put (4 :: Word8)
  put ClientLeft       = put (5 :: Word8)
  put PlayerJoinedGame = put (6 :: Word8)
  put PlayerLeftGame   = put (7 :: Word8)
  put StartGame        = put (8 :: Word8)
  put (LobbyError msg) = do
    put (9 :: Word8)
    put msg

  get = do
    tag <- get :: Get Word8
    case tag of
      0 -> return NickChange
      1 -> return GameNameChange
      2 -> return KickedFromGame
      3 -> return GameAdded
      4 -> return ClientJoined
      5 -> return ClientLeft
      6 -> return PlayerJoinedGame
      7 -> return PlayerLeftGame
      8 -> return StartGame
      9 -> do
        msg <- get :: Get String
        return $ LobbyError msg

instance Binary Bool where
  put True  = put (0 :: Word8)
  put False = put (1 :: Word8)

  get = do
    tag <- get :: Get Word8
    case tag of
      0 -> return True
      1 -> return False
