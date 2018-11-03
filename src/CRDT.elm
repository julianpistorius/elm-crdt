module CRDT exposing (CRDT, demo, toString, update)

import Array
import CRDTPath exposing (CRDTPath)
import Random


type alias CRDT =
    { operations : List Operation, seed : Random.Seed }


type alias Operation =
    { userId : UserId, path : CRDTPath, char : Char, isTomb : Bool }


type alias UserId =
    String


demo : CRDT
demo =
    helloWorld


helloWorld : CRDT
helloWorld =
    { operations =
        [ { userId = "bob", path = CRDTPath.demoPath [ 1 ], char = 'H', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 2 ], char = 'E', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 6 ], char = ' ', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 3 ], char = 'L', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 10 ], char = 'R', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 4 ], char = 'L', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 8 ], char = 'O', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 5 ], char = 'O', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 7 ], char = 'W', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 11 ], char = 'L', isTomb = False }
        , { userId = "bob", path = CRDTPath.demoPath [ 13 ], char = 'D', isTomb = False }
        ]
    , seed = Random.initialSeed 42
    }


toString : CRDT -> String
toString crdt =
    crdt.operations
        |> List.filter (not << .isTomb)
        |> List.sortBy (.path >> CRDTPath.sortOrder)
        |> List.map .char
        |> String.fromList


toCharsWithPath : CRDT -> List ( Char, CRDTPath )
toCharsWithPath crdt =
    crdt.operations
        |> List.filter (not << .isTomb)
        |> List.sortBy (.path >> CRDTPath.sortOrder)
        |> List.map (\operation -> ( operation.char, operation.path ))


update : UserId -> String -> CRDT -> CRDT
update userId updatedString crdt =
    let
        ( infimumPath, charsAfterInfimum, unmatchedCharsWithPaths ) =
            findLastMatchingPath
                (String.toList updatedString)
                (toCharsWithPath crdt)
                CRDTPath.absoluteInfimum

        ( supremumPath, charsBetween, stillUnmatchedCharsWithPaths ) =
            findLastMatchingPath
                (List.reverse charsAfterInfimum)
                (List.reverse unmatchedCharsWithPaths)
                CRDTPath.absoluteSupremum
    in
    crdt
        |> markBetweenAsTomb infimumPath supremumPath
        |> insertCharsBetween infimumPath supremumPath (List.reverse charsBetween)


findLastMatchingPath : List Char -> List ( Char, CRDTPath ) -> CRDTPath -> ( CRDTPath, List Char, List ( Char, CRDTPath ) )
findLastMatchingPath chars charsWithPaths currentPath =
    case charsWithPaths of
        ( charFromCRDT, path ) :: restCharsWithPath ->
            case chars of
                charFromString :: restCharsFromString ->
                    if charFromCRDT == charFromString then
                        findLastMatchingPath restCharsFromString restCharsWithPath path

                    else
                        ( currentPath, chars, charsWithPaths )

                [] ->
                    ( currentPath, chars, restCharsWithPath )

        [] ->
            ( currentPath, chars, [] )


markBetweenAsTomb : CRDTPath -> CRDTPath -> CRDT -> CRDT
markBetweenAsTomb infimumPath supremumPath givenCrdt =
    { givenCrdt
        | operations = List.map (markOperationAsTomb infimumPath supremumPath) givenCrdt.operations
    }


markOperationAsTomb : CRDTPath -> CRDTPath -> Operation -> Operation
markOperationAsTomb infimumPath supremumPath operation =
    if CRDTPath.isBetween infimumPath supremumPath operation.path then
        { operation | isTomb = True }

    else
        operation


insertCharsBetween : CRDTPath -> CRDTPath -> List Char -> CRDT -> CRDT
insertCharsBetween infimumPath supremumPath chars crdt =
    let
        ( chosenPath, newSeed ) =
            CRDTPath.choosePathBetween crdt.seed infimumPath supremumPath
    in
    case chars of
        char :: restChars ->
            let
                newOperation =
                    { userId = "bob", path = chosenPath, char = char, isTomb = False }

                updatedCRDT =
                    { crdt | operations = newOperation :: crdt.operations, seed = newSeed }
            in
            insertCharsBetween chosenPath supremumPath restChars updatedCRDT

        [] ->
            crdt



-- I can't use CRDT.toString crdt because it might not be a valid string because multiple users might have added conflicting inserts
-- It might actually be alright as long as the CRDT version has different characters
