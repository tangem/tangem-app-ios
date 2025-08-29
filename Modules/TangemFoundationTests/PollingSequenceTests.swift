//
//  PollingSequenceTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemFoundation

final class PollingSequenceTests: XCTestCase {
    private var delayProvider: InstantPollDelayProvider!

    override func setUp() async throws {
        delayProvider = InstantPollDelayProvider()
    }

    override func tearDown() async throws {
        delayProvider = nil
    }

    func testPollingNormal() async {
        let targetValue = 5

        var currentValue = 0
        let polling = PollingSequence<Int>(
            interval: 1,
            request: {
                currentValue += 1
                return currentValue
            },
            delayProvider: delayProvider
        )

        var values: [Int] = []
        sequence: for await result in polling {
            switch result {
            case .success(let value):
                values.append(value)
                if value == targetValue {
                    break sequence
                }
            case .failure:
                XCTFail("Should not fail")
            }
        }

        let elapsed = await delayProvider.elapsed

        XCTAssertEqual(values, [1, 2, 3, 4, 5])
        XCTAssertEqual(elapsed, 4)
    }

    func testPollingError() async {
        struct TestError: Error {}
        var callCount = 0

        let polling = PollingSequence<Int>(
            interval: 1,
            request: {
                callCount += 1
                if callCount == 2 { throw TestError() }
                return callCount
            },
            delayProvider: delayProvider
        )

        var results: [Result<Int, Error>] = []
        sequence: for await result in polling {
            results.append(result)
            if case .failure = result {
                break sequence
            }
        }

        let elapsed = await delayProvider.elapsed

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(try? results[0].get(), 1)
        switch results[1] {
        case .failure(let error as TestError):
            XCTAssertNotNil(error)
        default:
            XCTFail("Expected TestError")
        }
        XCTAssertEqual(elapsed, 1)
    }

    func testPollingCancel() async {
        let polling = PollingSequence<Int>(
            interval: 1,
            request: { Int.random(in: 1 ... 100) },
            delayProvider: delayProvider
        )

        let task = Task {
            var results: [Result<Int, Error>] = []
            for await result in polling {
                results.append(result)
            }
            return results
        }

        task.cancel()
        let results = await task.value
        let elapsed = await delayProvider.elapsed

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(elapsed, 0)
    }
}
