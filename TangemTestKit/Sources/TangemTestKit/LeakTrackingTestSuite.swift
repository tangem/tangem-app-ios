//
//  LeakTrackingTestSuite.swift
//  TangemTestKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing

/// Base class that verifies tracked objects are deallocated when the suite is released.
///
/// Call ``trackForMemoryLeaks(_:)`` for any object that should be released by the end of the test.
/// The check runs in `deinit`, so leaks are reported when the suite is torn down.
open class LeakTrackingTestSuite {
    private var deinitializationExpectations: [() -> Void]

    public init() {
        deinitializationExpectations = []
    }

    deinit {
        deinitializationExpectations.forEach { $0() }
    }

    /// Tracks an object for potential memory leaks.
    ///
    /// Use this in tests where you create instances via helper factories:
    /// ```swift
    /// /// A factory method for your system under test.
    /// func makeSUT() -> MyService {
    ///     let dependency1 = 42
    ///     let dependency2 = "Beep bop"
    ///     let service = MyService(dependency1, dependency2)
    ///     return trackForMemoryLeaks(service)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - instance: Object instance to track for deallocation.
    ///   - sourceLocation: The source location to which a potential leak should be attributed.
    /// - Returns: The same instance for fluent factory usage.
    @discardableResult
    public func trackForMemoryLeaks<TObject: AnyObject>(
        _ instance: TObject,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TObject {
        deinitializationExpectations.append { [weak instance] in
            #expect(
                instance == nil,
                "Instance is expected to be deallocated. Potential memory leak",
                sourceLocation: sourceLocation
            )
        }

        return instance
    }
}
