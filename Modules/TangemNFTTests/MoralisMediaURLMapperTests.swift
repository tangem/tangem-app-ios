//
//  MoralisMediaURLMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemNFT

@Suite("MoralisMediaURLMapperTests")
struct MoralisMediaURLMapperTests {
    @Test
    func prefersHighestResolution() {
        let url = MoralisMediaURLMapper.map(
            high: "https://media.moralis.io/high.png",
            medium: "https://media.moralis.io/medium.png",
            low: "https://media.moralis.io/low.png",
            original: "https://example.com/original.png"
        )

        #expect(url == URL(string: "https://media.moralis.io/high.png"))
    }

    @Test
    func skipsMissingAndEmptyCandidates() {
        let url = MoralisMediaURLMapper.map(
            high: nil,
            medium: "",
            low: nil,
            original: "https://example.com/original.png"
        )

        #expect(url == URL(string: "https://example.com/original.png"))
    }

    @Test
    func returnsNilWithoutCandidates() {
        #expect(MoralisMediaURLMapper.map(high: nil, medium: "", low: nil, original: nil) == nil)
    }

    @Test
    func convertsIPFSURL() {
        let url = MoralisMediaURLMapper.map("ipfs://QmImage/2.png")

        #expect(url == URL(string: "https://ipfs.io/ipfs/QmImage/2.png"))
    }
}
