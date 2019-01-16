//
//  Address.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import CryptoSwift

struct AddressHelper {

    static func getBTCAddress(_ hexWalletPublicKey: String) -> [String]? {
        var addresses = [String]()

        let hexPublicKey = hexWalletPublicKey

        let binaryPublicKey = dataWithHexString(hex: hexPublicKey)

        guard let binaryHash = sha256(binaryPublicKey) else {
            return nil
        }

        let binaryRipemd160 = RIPEMD160.hash(message: binaryHash)

        let hexRipend160 = "00" + binaryRipemd160.hexEncodedString()

        let binaryExtendedRipemd = dataWithHexString(hex: hexRipend160)
        guard let binaryOneSha = sha256(binaryExtendedRipemd) else {
            return nil
        }

        guard let binaryTwoSha = sha256(binaryOneSha) else {
            return nil
        }

        let binaryTwoShaToHex = binaryTwoSha.hexEncodedString()
        let checkHex = String(binaryTwoShaToHex[..<binaryTwoShaToHex.index(binaryTwoShaToHex.startIndex, offsetBy: 8)])
        let addCheckToRipemd = hexRipend160 + checkHex

        let binaryForBase58 = dataWithHexString(hex: addCheckToRipemd)
        let address = String(base58Encoding: binaryForBase58)

        let hexRipend1601 = "6F" + binaryRipemd160.hexEncodedString()
        let binaryExtendedRipemd1 = dataWithHexString(hex: hexRipend1601)

        guard let binaryOneSha1 = sha256(binaryExtendedRipemd1) else {
            return nil
        }

        guard let binaryTwoSha1 = sha256(binaryOneSha1) else {
            return nil
        }

        let binaryTwoShaToHex1 = binaryTwoSha1.hexEncodedString()
        let checkHex1 = String(binaryTwoShaToHex1[..<binaryTwoShaToHex1.index(binaryTwoShaToHex1.startIndex, offsetBy: 8)])
        let addCheckToRipemd1 = hexRipend1601 + checkHex1 //binary Address
        let binaryForBase581 = dataWithHexString(hex: addCheckToRipemd1)
        let address1 = String(base58Encoding: binaryForBase581) //Address

        addresses.append(address)
        addresses.append(address1)

        return addresses
    }

    static func getETHAddress(_ hexWalletPublicKey: String) -> String {

        let hexPublicKey = hexWalletPublicKey
        let hexPublicKeyWithoutTwoFirstLetters = String(hexPublicKey[hexPublicKey.index(hexPublicKey.startIndex, offsetBy: 2)...])
        let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
        let keccak = binaryCuttPublicKey.sha3(.keccak256)
        let hexKeccak = keccak.hexEncodedString()
        let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex, offsetBy: 24)...])
        let ethAddress = "0x" + cutHexKeccak

        return ethAddress
    }

}
