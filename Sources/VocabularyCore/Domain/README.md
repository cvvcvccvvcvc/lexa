# Domain

This layer owns pure vocabulary models and review algorithms. It must not import SwiftUI, SwiftData, AVFoundation, or perform persistence fetches.

Scheduling decisions live here so they can be tested with deterministic dates and random generators.
