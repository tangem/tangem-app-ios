//
// Copyright © 2023 m3g0byt3
//

import Foundation

@propertyWrapper
struct Clamp<T> where T: Comparable {
    private var value: T
    private let minValue: T
    private let maxValue: T

    var wrappedValue: T {
        get { callAsFunction() }
        set { value = newValue }
    }

    init(
        wrappedValue: T,
        minValue: T,
        maxValue: T
    ) {
        value = wrappedValue
        self.minValue = minValue
        self.maxValue = maxValue
    }

    func callAsFunction() -> T {
        clamp(value, min: minValue, max: maxValue)
    }
}

@_specialize(where T == Int)
@_specialize(where T == Float)
@_specialize(where T == Double)
@_specialize(where T == CGFloat)
@inline(__always)
func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(max(value, minValue), maxValue)
}
