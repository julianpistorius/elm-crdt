module Example exposing (suite)

import CRDT exposing (Operation(..))
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Random
import Test exposing (..)


suite : Test
suite =
    describe "CRDT"
        [ describe "CRDT.toString"
            [ test "constructs the correct string from a list of two operations in the correct order" <|
                \_ ->
                    let
                        crdt =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 7 ] 'i'
                                ]
                            }
                    in
                    Expect.equal (CRDT.toString crdt) "Hi"
            , test "constructs the correct string from a list of two operations even if the order is not correct" <|
                \_ ->
                    let
                        crdt =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 7 ] 'i'
                                , Insert "bob" [ 1 ] 'H'
                                ]
                            }
                    in
                    Expect.equal (CRDT.toString crdt) "Hi"
            , todo "constructs a to be resolved string if different users edited the same position"

            --, test "constructs a to be resolved string if different users edited the same position" <|
            --    \_ ->
            --        let
            --            crdt =
            --                {seed = Random.initialSeed 42, operations = [ Insert "bob" [ 1 ] 'H'
            --                , Insert "bob" [ 7 ] 'i'
            --                , Insert "alice" [ 0 ] 'H'
            --                , Insert "alice" [ 7 ] 'o'
            --                ]
            --        in
            --        Expect.equal (CRDT.toString crdt) "Hi"
            , test "constructs the correct string from a list of many operations even if the order is not correct" <|
                \_ ->
                    let
                        crdt =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 7 ] 'W'
                                , Insert "bob" [ 11 ] 'L'
                                , Insert "bob" [ 10 ] 'R'
                                , Insert "bob" [ 4 ] 'L'
                                , Insert "bob" [ 5 ] 'O'
                                , Insert "bob" [ 3 ] 'L'
                                , Insert "bob" [ 2 ] 'E'
                                , Insert "bob" [ 6 ] ' '
                                , Insert "bob" [ 8 ] 'O'
                                , Insert "bob" [ 13 ] 'D'
                                ]
                            }
                    in
                    Expect.equal (CRDT.toString crdt) "HELLO WORLD"
            ]
        , describe "CRDT.update"
            [ test "it adds a character to the end if the updated version differs by one character" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 7 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hel"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 7 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "it adds two characters to the last position if the updated version differs by two characters" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 7 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hell"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 11 ] 'l'
                            , Insert "bob" [ 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 7 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "it adds one character to a sub-register if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hel"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 14, 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "it adds one character to a sub-register if there is no space between two characters in the parent register" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 0 ] 'K'
                                , Insert "bob" [ 1 ] 'n'
                                ]
                            }
                                |> CRDT.update "bob" "Kan"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 0, 10 ] 'a'
                            , Insert "bob" [ 0 ] 'K'
                            , Insert "bob" [ 1 ] 'n'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "it adds one character to a sub-register if there is no space between two characters in the parent register for a long word" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 0 ] 'K'
                                , Insert "bob" [ 1 ] 'n'
                                , Insert "bob" [ 5 ] 'g'
                                , Insert "bob" [ 11 ] 'u'
                                , Insert "bob" [ 14 ] 'r'
                                , Insert "bob" [ 14 ] 'u'
                                ]
                            }
                                |> CRDT.update "bob" "Kanguru"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 0, 10 ] 'a'
                            , Insert "bob" [ 0 ] 'K'
                            , Insert "bob" [ 1 ] 'n'
                            , Insert "bob" [ 5 ] 'g'
                            , Insert "bob" [ 11 ] 'u'
                            , Insert "bob" [ 14 ] 'r'
                            , Insert "bob" [ 14 ] 'u'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "it adds two characters to a sub-register if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hel"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 14, 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "adds characters to a sub-register in front if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "AHe"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 0, 10 ] 'A'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "adds multiple characters to a sub-register in front if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "ABHe"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 0, 11 ] 'B'
                            , Insert "bob" [ 0, 10 ] 'A'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "adds multiple characters to a sub-register at the end if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hell"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 14, 11 ] 'l'
                            , Insert "bob" [ 14, 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            , test "adds multiple characters to a sub-sub-register at the end if the parent register is already full" <|
                \_ ->
                    let
                        calculatedResult =
                            { seed = Random.initialSeed 42
                            , operations =
                                [ Insert "bob" [ 14, 14 ] 'l'
                                , Insert "bob" [ 14, 10 ] 'l'
                                , Insert "bob" [ 1 ] 'H'
                                , Insert "bob" [ 14 ] 'e'
                                ]
                            }
                                |> CRDT.update "bob" "Hello"
                                |> .operations

                        expectedResult =
                            [ Insert "bob" [ 14, 14, 10 ] 'o'
                            , Insert "bob" [ 14, 14 ] 'l'
                            , Insert "bob" [ 14, 10 ] 'l'
                            , Insert "bob" [ 1 ] 'H'
                            , Insert "bob" [ 14 ] 'e'
                            ]
                    in
                    Expect.equal calculatedResult expectedResult
            ]
        ]
