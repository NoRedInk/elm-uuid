module Tests exposing (all, buildUuid, initialSeedFuzzer, randomInt, uuidFuzzer)

--import Check exposing (claim, claimTrue, that, is, true, false, for, quickCheck)
--import Check.Test exposing (evidenceToTest)

import Expect
import Fuzz
import Prng.Uuid as Uuid exposing (..)
import Random
import Random.Pcg.Extended as RandomE
import Shrink
import String
import Test exposing (..)


randomInt : Random.Generator Int
randomInt =
    Random.int RandomE.minInt RandomE.maxInt


buildUuid : Int -> Uuid
buildUuid integer =
    let
        initialSeed =
            RandomE.initialSeed integer []

        ( uuid, seed ) =
            RandomE.step generator initialSeed
    in
    uuid


initialSeedFuzzer : Fuzz.Fuzzer RandomE.Seed
initialSeedFuzzer =
    Fuzz.custom
        (Random.map (\x -> RandomE.initialSeed x []) randomInt)
        Shrink.noShrink


uuidFuzzer : Fuzz.Fuzzer Uuid
uuidFuzzer =
    Fuzz.custom (Random.map buildUuid randomInt) Shrink.noShrink


all : Test
all =
    describe "All tests"
        [ test "isValid - for valid uuid" <|
            \() ->
                "63B9AAA2-6AAF-473E-B37E-22EB66E66B76"
                    |> isValidUuid
                    |> Expect.true "should be valid"
        , test "isValid - for invalid uuid" <|
            \() ->
                "zz"
                    |> isValidUuid
                    |> Expect.false "should be invalid"
        , fuzz initialSeedFuzzer "generate uuid" <|
            \initialSeed ->
                let
                    ( uuid, nextSeed ) =
                        RandomE.step generator initialSeed
                in
                uuid
                    |> Uuid.toString
                    |> isValidUuid
                    |> Expect.true "should be valid uuid"
        , fuzz initialSeedFuzzer "generate two uuids" <|
            \initialSeed ->
                let
                    ( uuid1, seed1 ) =
                        RandomE.step generator initialSeed

                    ( uuid2, seed2 ) =
                        RandomE.step generator seed1
                in
                Expect.notEqual uuid1 uuid2
        , fuzz uuidFuzzer "roundtripping uuid through toString -> fromString keeps the Uuids intact" <|
            \uuid ->
                uuid
                    |> Uuid.toString
                    |> Uuid.fromString
                    |> Expect.equal (Just uuid)
        , fuzz uuidFuzzer "roundtripping uuid through toString -> fromString keeps the Uuids intact - upper casing is ignored" <|
            \uuid ->
                uuid
                    |> Uuid.toString
                    |> String.toUpper
                    |> Uuid.fromString
                    |> Expect.equal (Just uuid)
        , fuzz uuidFuzzer "roundtripping uuid through toString -> fromString keeps the Uuids intact - lower casing is ignored" <|
            \uuid ->
                uuid
                    |> Uuid.toString
                    |> String.toLower
                    |> Uuid.fromString
                    |> Expect.equal (Just uuid)
        ]
