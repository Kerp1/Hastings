module Table where

type Table = [Square]
data Color = Blue | Red | Pink | Green | Black | Yellow | White
 deriving (Show, Eq)

data Content = Empty | Piece Color
 deriving (Show, Eq)

data Square = Square Content Color Coord
 deriving (Show, Eq)

data GameState = GameState { gameTable :: Table
                           , currentPlayer :: String
                           , players :: [(String,Color)]
                           , fromCoord :: Maybe Coord
                           , playerMoveAgain :: Bool }

type Coord = (Int,Int)


startTable :: Table
startTable =                                    [(Square (Piece Black) Blue (12,0)), 
                                        (Square (Piece Black) Blue (11,1)), (Square (Piece Black) Blue (13,1)),
                                (Square (Piece Black) Blue (10,2)),(Square (Piece Black) Blue (12,2)), (Square (Piece Black) Blue (14,2)),
                        (Square (Piece Black) Blue (9,3)),(Square (Piece Black) Blue (11,3)), (Square (Piece Black) Blue (13,3)), (Square (Piece Black) Blue (15,3)),(Square (Piece Green) Yellow (0,4)),(Square (Piece Green) Yellow (2,4)), (Square (Piece Green) Yellow (4,4)), (Square Empty White (6,4)), (Square Empty White (8,4)), (Square Empty White (10,4)), (Square Empty White (12,4)), (Square Empty White (14,4)), (Square Empty White (16,4)), (Square (Piece Red) Pink (18,4)), (Square (Piece Red) Pink (20,4)), (Square (Piece Red) Pink (22,4)), (Square (Piece Red) Pink (24,4)), (Square (Piece Green) Yellow (1,5)), (Square (Piece Green) Yellow (3,5)), (Square (Piece Green) Yellow (5,5)), (Square Empty White (7,5)), (Square Empty White (9,5)), (Square Empty White (11,5)), (Square Empty White (13,5)), (Square Empty White (15,5)), (Square Empty White (17,5)), (Square (Piece Red) Pink (19,5)), (Square (Piece Red) Pink (21,5)), (Square (Piece Red) Pink (23,5)), (Square (Piece Green) Yellow (2,6)), (Square (Piece Green) Yellow (4,6)), (Square Empty White (6,6)), (Square Empty White (8,6)), (Square Empty White (10,6)), (Square Empty White (12,6)), (Square Empty White (14,6)), (Square Empty White (16,6)), (Square Empty White (18,6)), (Square (Piece Red) Pink (20,6)), (Square (Piece Red) Pink (22,6)), (Square (Piece Green) Yellow (3,7)), (Square Empty White (5,7)), (Square Empty White (7,7)), (Square Empty White (9,7)), (Square Empty White (11,7)), (Square Empty White (13,7)), (Square Empty White (15,7)), (Square Empty White (17,7)), (Square Empty White (19,7)), (Square (Piece Red) Pink (21,7)), (Square Empty White (4,8)), (Square Empty White (6,8)), (Square Empty White (8,8)), (Square Empty White (10,8)), (Square Empty White (12,8)), (Square Empty White (14,8)), (Square Empty White (16,8)), (Square Empty White (18,8)), (Square Empty White (20,8)), (Square (Piece Pink) Red (3,9)),  (Square Empty White (5,9)), (Square Empty White (7,9)), (Square Empty White (9,9)), (Square Empty White (11,9)), (Square Empty White (13,9)), (Square Empty White (15,9)), (Square Empty White (17,9)), (Square Empty White (19,9)), (Square (Piece Yellow) Green (21,9)), (Square (Piece Pink) Red (2,10)), (Square (Piece Pink) Red (4,10)), (Square Empty White (6,10)), (Square Empty White (8,10)), (Square Empty White (10,10)), (Square Empty White (12,10)), (Square Empty White (14,10)), (Square Empty White (16,10)), (Square Empty White (18,10)), (Square (Piece Yellow) Green (20,10)), (Square (Piece Yellow) Green (22,10)), (Square (Piece Pink) Red (1,11)), (Square (Piece Pink) Red (3,11)), (Square (Piece Pink) Red (5,11)), (Square Empty White (7,11)), (Square Empty White (9,11)), (Square Empty White (11,11)), (Square Empty White (13,11)), (Square Empty White (15,11)), (Square Empty White (17,11)), (Square (Piece Yellow) Green (19,11)), (Square (Piece Yellow) Green (21,11)), (Square (Piece Yellow) Green (23,11)), (Square (Piece Pink) Red (0,12)), (Square (Piece Pink) Red (2,12)), (Square (Piece Pink) Red (4,12)), (Square (Piece Pink) Red (6,12)), (Square Empty White (8,12)), (Square Empty White (10,12)), (Square Empty White (12,12)), (Square Empty White (14,12)), (Square Empty White (16,12)), (Square (Piece Yellow) Green (18,12)), (Square (Piece Yellow) Green (20,12)), (Square (Piece Yellow) Green (22,12)), (Square (Piece Yellow) Green (24,12)), (Square (Piece Blue) Black (9,13)), (Square (Piece Blue) Black (11,13)), (Square (Piece Blue) Black (13,13)), (Square (Piece Blue) Black (15,13)), (Square (Piece Blue) Black (10,14)), (Square (Piece Blue) Black (12,14)), (Square (Piece Blue) Black (14,14)), (Square (Piece Blue) Black (11,15)), (Square (Piece Blue) Black (13,15)), (Square (Piece Blue) Black (12,16))] 
