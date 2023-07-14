//
//  ThreadSafeContainer.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSwapping

class ThreadSafeContainerTests: XCTestCase {
    func testConcurrentReadWriteCountUsingSingleQueue() {
        let workingQueue = DispatchQueue(label: "workingQueue", qos: .userInitiated, attributes: .concurrent)
        let randomDictionaryKeys = (0 ..< 100).map { _ in UUID().uuidString }
        let container: ThreadSafeContainer<[String: Int]> = [:]

        let readCount = 20000
        let writeCount = 20000

        let expectationFulfillQueue = DispatchQueue(label: "expectationFulfillQueue")
        let expectation = expectation(description: #function)
        expectation.expectedFulfillmentCount = (readCount + writeCount) / 1000

        workingQueue.async {
            DispatchQueue.concurrentPerform(iterations: readCount) { i in
                container.value[randomDictionaryKeys.randomElement()!] = Int.random(in: 0 ... 1_000_000_007)
                let count = i + 1
                if count % 1000 == 0 {
                    expectationFulfillQueue.async {
                        print("Completed \(count)th write")
                        expectation.fulfill()
                    }
                }
            }
        }

        workingQueue.async {
            DispatchQueue.concurrentPerform(iterations: writeCount) { i in
                let value = container.value[randomDictionaryKeys.randomElement()!]
                let count = i + 1
                if count % 1000 == 0 {
                    expectationFulfillQueue.async {
                        expectation.fulfill()
                        print("Completed \(count)th read with value: \(String(describing: value))")
                    }
                }
            }
        }

        wait(for: [expectation])
    }

    func testConcurrentReadWriteCountUsingMultipleQueues() {
        let workingQueue1 = DispatchQueue(label: "workingQueue1", qos: .userInitiated, attributes: .concurrent)
        let workingQueue2 = DispatchQueue(label: "workingQueue2", qos: .userInitiated, attributes: .concurrent)
        let randomDictionaryKeys = (0 ..< 100).map { _ in UUID().uuidString }
        let container: ThreadSafeContainer<[String: Int]> = [:]

        let queue1WorkCount = 20000
        let queue2WorkCount = 20000

        let expectationFulfillQueue = DispatchQueue(label: "expectationFulfillQueue")
        let expectation = expectation(description: #function)
        expectation.expectedFulfillmentCount = (queue1WorkCount + queue2WorkCount) / 1000

        workingQueue1.async {
            DispatchQueue.concurrentPerform(iterations: queue1WorkCount) { i in
                let count = i + 1
                if Bool.random() {
                    container.value[randomDictionaryKeys.randomElement()!] = Int.random(in: 0 ... 1_000_000_007)
                    if count % 1000 == 0 {
                        expectationFulfillQueue.async {
                            print("Completed \(count)th write")
                            expectation.fulfill()
                        }
                    }
                } else {
                    let value = container.value[randomDictionaryKeys.randomElement()!]
                    if count % 1000 == 0 {
                        expectationFulfillQueue.async {
                            expectation.fulfill()
                            print("Completed \(count)th read with value: \(String(describing: value))")
                        }
                    }
                }
            }
        }

        workingQueue2.async {
            DispatchQueue.concurrentPerform(iterations: queue2WorkCount) { i in
                let count = i + 1
                if Bool.random() {
                    container.value[randomDictionaryKeys.randomElement()!] = Int.random(in: 0 ... 1_000_000_007)
                    if count % 1000 == 0 {
                        expectationFulfillQueue.async {
                            print("Completed \(count)th write")
                            expectation.fulfill()
                        }
                    }
                } else {
                    let value = container.value[randomDictionaryKeys.randomElement()!]
                    if count % 1000 == 0 {
                        expectationFulfillQueue.async {
                            expectation.fulfill()
                            print("Completed \(count)th read with value: \(String(describing: value))")
                        }
                    }
                }
            }
        }

        wait(for: [expectation])
    }

    func testDataIntegrityWhenMutatedConcurrently() {
        typealias Mutation = (indexToMutate: Int, valueToAdd: Int)

        let mutationsCount = 20000
        let maxValueToAdd = Int.max / mutationsCount // To avoid integer overflow
        let mutatedArray = Array(repeating: 0, count: 100)

        let mutations: [Mutation] = (0 ..< mutationsCount).map { _ in
            let indexToMutate = Int.random(in: 0 ..< mutatedArray.count)
            let valueToAdd = Int.random(in: 0 ..< maxValueToAdd)
            return (indexToMutate, valueToAdd)
        }

        var synchronousResult = mutatedArray
        for mutation in mutations {
            synchronousResult[mutation.indexToMutate] += mutation.valueToAdd
        }

        let workingQueue = DispatchQueue(label: "workingQueue", qos: .userInitiated, attributes: .concurrent)
        let container = ThreadSafeContainer(mutatedArray)
        let expectationFulfillQueue = DispatchQueue(label: "expectationFulfillQueue")
        let expectation = expectation(description: #function)
        expectation.expectedFulfillmentCount = mutationsCount / 1000

        workingQueue.async {
            DispatchQueue.concurrentPerform(iterations: mutationsCount) { i in
                let mutation = mutations[i]
                container.value[mutation.indexToMutate] += mutation.valueToAdd
                let count = i + 1
                if count % 1000 == 0 {
                    expectationFulfillQueue.async {
                        expectation.fulfill()
                        print("Completed \(count)th write")
                    }
                }
            }
        }

        wait(for: [expectation])
        XCTAssertEqual(synchronousResult, container.value)
    }

    func testExpressibleByDictionaryLiteralConformanceForEmptyContainerWrappingDictionary() {
        let emptyThreadSafeContainer: ThreadSafeContainer<[String: String]> = [:]
        let emptyDictionary: [String: String] = [:]

        XCTAssertEqual(emptyThreadSafeContainer.value, emptyDictionary)
    }

    func testExpressibleByDictionaryLiteralConformanceForNonEmptyContainerWrappingDictionary() {
        // Duplicate keys are used intentionally
        let nonEmptyThreadSafeContainer: ThreadSafeContainer<[String: String]> = [
            "foo1": "baz",
            "foo1": "baz",
            "foo2": "nonqwerty",
            "foo2": "qwerty",
            "hello": "world",
        ]
        let nonEmptyDictionary: [String: String] = [
            "foo1": "baz",
            "foo2": "qwerty",
            "hello": "world",
        ]

        XCTAssertEqual(nonEmptyThreadSafeContainer.value, nonEmptyDictionary)
    }

    func testExpressibleByArrayLiteralConformanceForEmptyContainerWrappingArray() {
        let emptyThreadSafeContainer: ThreadSafeContainer<[String]> = []
        let emptyArray: [String] = []

        XCTAssertEqual(emptyThreadSafeContainer.value, emptyArray)
    }

    func testExpressibleByArrayLiteralConformanceForNonEmptyContainerWrappingArray() {
        let nonEmptyThreadSafeContainer: ThreadSafeContainer<[String]> = [
            "foo",
            "baz",
            "qwerty",
            "hello",
            "world",
        ]
        let nonEmptyArray: [String] = [
            "foo",
            "baz",
            "qwerty",
            "hello",
            "world",
        ]

        XCTAssertEqual(nonEmptyThreadSafeContainer.value, nonEmptyArray)
    }

    func testExpressibleByArrayLiteralConformanceForEmptyContainerWrappingSet() {
        let emptyThreadSafeContainer: ThreadSafeContainer<Set<String>> = []
        let emptySet: Set<String> = []

        XCTAssertEqual(emptyThreadSafeContainer.value, emptySet)
    }

    func testExpressibleByArrayLiteralConformanceForNonEmptyContainerWrappingSet() {
        // Duplicate values are used intentionally
        let nonEmptyThreadSafeContainer: ThreadSafeContainer<Set<String>> = [
            "foo",
            "baz",
            "baz",
            "baz",
            "qwerty",
            "hello",
            "world",
        ]
        // Duplicate values are used intentionally
        let nonEmptySet: Set<String> = [
            "foo",
            "baz",
            "baz",
            "baz",
            "qwerty",
            "hello",
            "world",
        ]

        XCTAssertEqual(nonEmptyThreadSafeContainer.value, nonEmptySet)
    }
}
