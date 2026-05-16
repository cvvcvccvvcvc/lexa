import Foundation

public protocol ReviewRandomGenerator {
    mutating func nextUnitDouble() -> Double
}

public extension ReviewRandomGenerator {
    mutating func nextDouble(in range: Range<Double>) -> Double {
        precondition(range.lowerBound < range.upperBound)
        return range.lowerBound + (range.upperBound - range.lowerBound) * nextUnitDouble()
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        precondition(range.lowerBound <= range.upperBound)
        return range.lowerBound + (range.upperBound - range.lowerBound) * nextUnitDouble()
    }

    mutating func nextBool() -> Bool {
        nextUnitDouble() < 0.5
    }
}

public struct SeededReviewRandomGenerator: ReviewRandomGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func nextUnitDouble() -> Double {
        state = state &* 2862933555777941757 &+ 3037000493
        let mantissa = state >> 11
        return Double(mantissa) / Double(UInt64(1) << 53)
    }
}

public struct SystemReviewRandomGenerator: ReviewRandomGenerator {
    private var generator = SystemRandomNumberGenerator()

    public init() {}

    public mutating func nextUnitDouble() -> Double {
        Double.random(in: 0..<1, using: &generator)
    }
}
