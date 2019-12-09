//
//  AddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class BitcoinAddressFactory {
    func makeAddress(from cardPublicKey: Data, testnet: Bool) -> String {
//        let hexPublicKey = card.walletPublicKey
//
//        let binaryPublicKey = dataWithHexString(hex: hexPublicKey)
//
//        guard let binaryHash = sha256(binaryPublicKey) else {
//            assertionFailure()
//            return
//        }
//
//        let binaryRipemd160 = RIPEMD160.hash(message: binaryHash)
//        let netSelectionByte = card.isTestBlockchain ? "6f" : "00"
//        let hexRipend160 = netSelectionByte + binaryRipemd160.hexEncodedString()
//
//        let binaryExtendedRipemd = dataWithHexString(hex: hexRipend160)
//        guard let binaryOneSha = sha256(binaryExtendedRipemd) else {
//            assertionFailure()
//            return
//        }
//
//        guard let binaryTwoSha = sha256(binaryOneSha) else {
//            assertionFailure()
//            return
//        }
//
//        let binaryTwoShaToHex = binaryTwoSha.hexEncodedString()
//        let checkHex = String(binaryTwoShaToHex[..<binaryTwoShaToHex.index(binaryTwoShaToHex.startIndex, offsetBy: 8)])
//        let addCheckToRipemd = hexRipend160 + checkHex
//
//        let binaryForBase58 = dataWithHexString(hex: addCheckToRipemd)
//
//        return String(base58Encoding: binaryForBase58)
    }
}
