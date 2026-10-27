# ARce: an AR race replay

An iPhone and Mac app that replays recorded race sessions in augmented reality. It places a 3D circuit on a table and animates the cars lap by lap from telemetry data.

## Context

Built over four days in February 2022 (19 to 22 Feb) by a team of three, as "Challenge 2" of a developer challenge. I wrote most of the commits (48 of 74), covering the AR scene, the networking and the interaction features.

## What it shows

- An ARKit + RealityKit scene inside SwiftUI. The circuit model is anchored on a horizontal surface and the cars and tracking cones are animated from position data.
- Combine pipelines that fetch the session and per-lap telemetry, serialised so the laps arrive in order, and `CombineLatest` to compare two drivers side by side.
- Interaction modes: gestures, zoom buttons, grab and restore, a pointer, and a two-point distance measure built on custom geometry helpers.
- Overlays for brake and throttle indicators, driver names, the winner and weather data.
- A shared code base with an iOS AR target and a macOS target.

## Stack

Swift 5, SwiftUI, ARKit, RealityKit, Reality Composer, Combine. iOS 15 and macOS 11.

## Run it

Open the Xcode project and run the iPhone target on a device with ARKit support.

## Looking back (2026)

Leftover merge-conflict files (`Model_BASE`, `Model_LOCAL` and others) are still in the tree, and nothing is tested. Today I would use Swift Concurrency in place of the Combine chains and keep the interaction modes behind a protocol from day one. I did that refactor three months later in ARKit-RealityKit-Template.
