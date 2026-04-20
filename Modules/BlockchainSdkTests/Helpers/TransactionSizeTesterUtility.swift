//
//  TransactionSizeTesterUtility.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Testing

final class TransactionSizeTesterUtility {
    private let iPhone7MaxSize = 150
    private let cos_4_52_MaxSize = 255
    private let cos_4_52_AndAboveMaxSize = 944

    /// - Warning: Do not use the `#_sourceLocation` macro here to create a `SourceLocation` instance. At least in Swift 6.1 and Xcode 16.4,
    /// it causes an obscure compilation error (`Command SwiftCompile failed with a nonzero exit code`, no actual error code available)
    /// when this method is called from the `XCTest` test case.
    /// It looks like a compatibility issue between the `XCTest` and `SwiftTesting` frameworks.
    func testTxSize(
        _ data: Data?,
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
    ) {
        guard let data = data else {
            #expect(Bool(false), Comment(rawValue: "Transaction data for size test is nil"))
            return
        }

        #expect(isValidForIPhone7(data), "Testing tx size for iPhone 7 TX size = \(data.count)", sourceLocation: sourceLocation)
        #expect(isValidForCosBelow4_52(data), "Testing tx size for COS below 4.52 TX size = \(data.count)", sourceLocation: sourceLocation)
        #expect(isValidForCos4_52AndAbove(data), "Testing tx size for COS 4.52 and above TX size = \(data.count)", sourceLocation: sourceLocation)
    }

    /// - Warning: Do not use the `#_sourceLocation` macro here to create a `SourceLocation` instance. At least in Swift 6.1 and Xcode 16.4,
    /// it causes an obscure compilation error (`Command SwiftCompile failed with a nonzero exit code`, no actual error code available)
    /// when this method is called from the `XCTest` test case.
    /// It looks like a compatibility issue between the `XCTest` and `SwiftTesting` frameworks.
    func testTxSizes(
        _ data: [Data],
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
    ) {
        data.forEach {
            testTxSize($0, sourceLocation: sourceLocation)
        }
    }

    func isValidForIPhone7(_ data: Data) -> Bool {
        testSize(data: data, maxSize: iPhone7MaxSize)
    }

    func isValidForCosBelow4_52(_ data: Data) -> Bool {
        testSize(data: data, maxSize: cos_4_52_MaxSize)
    }

    func isValidForCos4_52AndAbove(_ data: Data) -> Bool {
        testSize(data: data, maxSize: cos_4_52_AndAboveMaxSize)
    }

    private func testSize(data: Data, maxSize: Int) -> Bool {
        data.count <= maxSize
    }
}
