//
//  NFTIPFSURLConverterTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemNFT

@Suite("NFTIPFSURLConverterTests")
struct NFTIPFSURLConverterTests {
    @Test(
        arguments: [
            TestCase(
                entry: URL(string: "ipfs://QmYRubXNCPiXstjdqDtsY7xmv1SNnnmVKazRGe")!,
                expected: URL(string: "https://ipfs.io/ipfs/QmYRubXNCPiXstjdqDtsY7xmv1SNnnmVKazRGe")!
            ),
            TestCase(
                entry: URL(string: "ipfs://QmHash/some/path/file.png")!,
                expected: URL(string: "https://ipfs.io/ipfs/QmHash/some/path/file.png")!
            ),
            TestCase(
                entry: URL(string: "ipfs://QmHash/file.png?foo=bar#section1")!,
                expected: URL(string: "https://ipfs.io/ipfs/QmHash/file.png?foo=bar#section1")!
            ),
            TestCase(
                entry: URL(string: "ipfs://ipfs/hash/image.jpeg")!,
                expected: URL(string: "https://ipfs.io/ipfs/hash/image.jpeg")!
            ),
            TestCase(
                entry: URL(string: "https://example.com/file.png")!,
                expected: URL(string: "https://example.com/file.png")!
            ),
            TestCase(
                entry: URL(string: "ipfs://file.png")!,
                expected: URL(string: "https://ipfs.io/ipfs/file.png")!
            ),
        ]
    )
    func convert(testCase: TestCase) {
        #expect(NFTIPFSURLConverter.convert(testCase.entry) == testCase.expected)
    }
}

extension NFTIPFSURLConverterTests {
    struct TestCase {
        let entry: URL
        let expected: URL
    }
}
