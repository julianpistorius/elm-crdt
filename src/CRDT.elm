module CRDT exposing
    ( CRDT
    , ResolvedCRDT
    , demo
    , demoAsString
    , isResolved
    , length
    , resolve
    , toString
    , update
    )

import Array
import CRDTPath exposing (CRDTPath)
import Random


type ResolvedCRDT
    = ResolvedCRDT CRDT


type alias CRDT =
    { operations : List Operation, seed : Random.Seed }


type alias Operation =
    { userId : UserId, path : CRDTPath, char : Char, isTomb : Bool }


type alias UserId =
    String


demo : CRDT
demo =
    helloWorld


demoAsString : String
demoAsString =
    "HELLO WORLD"


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


resolve : CRDT -> Result String ResolvedCRDT
resolve crdt =
    if isResolved crdt then
        Ok (ResolvedCRDT crdt)

    else
        Err "Can't resolve crdt"


toString : ResolvedCRDT -> String
toString (ResolvedCRDT crdt) =
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
        |> insertCharsBetween userId infimumPath supremumPath (List.reverse charsBetween)


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


insertCharsBetween : UserId -> CRDTPath -> CRDTPath -> List Char -> CRDT -> CRDT
insertCharsBetween userId infimumPath supremumPath chars crdt =
    let
        tombAdjustedInfimum =
            crdt.operations
                |> List.filter .isTomb
                |> List.map .path
                |> CRDTPath.findPathExcluding infimumPath supremumPath

        ( chosenPath, newSeed ) =
            CRDTPath.choosePathBetween crdt.seed tombAdjustedInfimum supremumPath
    in
    case chars of
        char :: restChars ->
            let
                newOperation =
                    Operation userId chosenPath char False

                updatedCRDT =
                    { crdt | operations = newOperation :: crdt.operations, seed = newSeed }
            in
            insertCharsBetween userId chosenPath supremumPath restChars updatedCRDT

        [] ->
            crdt


isResolved : CRDT -> Bool
isResolved crdt =
    crdt.operations
        |> List.filter (not << .isTomb)
        |> List.map .path
        |> CRDTPath.allDifferent


length (ResolvedCRDT crdt) =
    List.length crdt.operations
