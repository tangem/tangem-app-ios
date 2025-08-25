//
//  BLSUtilTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Testing
@testable import TangemHotSdk
@testable @preconcurrency import TangemSdk
@testable import TangemFoundation
import Foundation

struct BLSUtilTests {
    @Test
    func publicKey() throws {
        let result = try BLSUtil.publicKey(entropy: entropy)

        let expected = "B9247498D0F9EC5064185D717AF600E9F1788579D308471DF5AB76B9913E6E3E47F3363B8F424045DBA67630C4CA5222"

        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func signProducesCorrectBlsSignatures() throws {
        let signatures = try BLSUtil.sign(
            hashes: [Data(hexString: "824765209fcc9f8fa7cdf0f99fffaa1d5550d490aae98af563547d2811bba9cedb5b0d3ead47b4d2cfec635212150f0b0a5cb2d088837d4ff0386557eee8f6b5d0283d63d2e4e2c470d80810bc4b1ae26e7536013d6b7ee477c51643e05615c3")],
            entropy: entropy
        )

        let expected = Data(hexString: "81173A2A99D132B5C4B53A3032FD530927D23B0E49EA5F51950EBD9AD71BB7419CD5159FA9B5A4167285848BE273D1FA1211E22888759DAAFCABF32EBC4A632D74B550671A90CEE508DE78500EA7A6D76D0AAC84B7C5324ACD7A38509D94C06E")

        #expect(signatures.count == 1)
        #expect(signatures.first == .some(expected))
    }

    @Test
    func signProducesDeterministicOutput() throws {
        let signatures1 = try BLSUtil.sign(
            hashes: [Data(hexString: "824765209fcc9f8fa7cdf0f99fffaa1d5550d490aae98af563547d2811bba9cedb5b0d3ead47b4d2cfec635212150f0b0a5cb2d088837d4ff0386557eee8f6b5d0283d63d2e4e2c470d80810bc4b1ae26e7536013d6b7ee477c51643e05615c3")],
            entropy: entropy
        )

        let signatures2 = try BLSUtil.sign(
            hashes: [Data(hexString: "824765209fcc9f8fa7cdf0f99fffaa1d5550d490aae98af563547d2811bba9cedb5b0d3ead47b4d2cfec635212150f0b0a5cb2d088837d4ff0386557eee8f6b5d0283d63d2e4e2c470d80810bc4b1ae26e7536013d6b7ee477c51643e05615c3")],
            entropy: entropy
        )

        #expect(signatures1 == signatures2)
    }
}
