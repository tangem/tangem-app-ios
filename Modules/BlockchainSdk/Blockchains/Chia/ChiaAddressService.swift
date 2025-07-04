//
//  ChiaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 PuzzleHash Chia documentation - https://docs.chia.net/guides/crash-course/signatures/
 */

struct ChiaAddressService: AddressService {
    // MARK: - Private Properties

    private(set) var isTestnet: Bool

    // MARK: - Implementation

    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let puzzle = ChiaPuzzleUtils().getPuzzleHash(from: publicKey.blockchainKey)
        let puzzleHash = try ClvmProgram.Decoder(programBytes: puzzle.bytes).deserialize().hash()
        let hrp = HRP.part(isTestnet: isTestnet)
        let encodeValue = try Bech32(variant: .bech32m).encode(hrp, values: puzzleHash)

        return PlainAddress(value: encodeValue, publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        do {
            let result = try Bech32(variant: .bech32m).decode(address)
            return HRP.part(isTestnet: isTestnet) == result.hrp
        } catch {
            return false
        }
    }
}

extension ChiaAddressService {
    /// Human Readable Part Prefix address Chia blockchain
    enum HRP: String {
        case txch
        case xch

        static func part(isTestnet: Bool) -> String {
            return isTestnet ? HRP.txch.rawValue : HRP.xch.rawValue
        }
    }
}
