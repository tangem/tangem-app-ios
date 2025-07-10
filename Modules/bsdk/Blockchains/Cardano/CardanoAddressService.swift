//
//  CardanoAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import SwiftCBOR
import CryptoSwift

struct CardanoAddressService {
    private let addressHeaderByte = Data([UInt8(97)])
    init() {}

    private func makeByronAddress(from walletPublicKey: Data) -> String {
        let hexPublicKeyExtended = walletPublicKey + Data(repeating: 0, count: 32) // extendedPublicKey
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended.toBytes)], [:]] as CBOR).encode() // makePubKeyWithAttributes
        let sha = forSha3.sha3(.sha256)
        // [REDACTED_TODO_COMMENT]
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)! // calculate blake 2b
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode() // makeHashWithAttributes
        let checksum = UInt64(addr.crc32()) // getCheckSum
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr))
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        let walletAddress = hexAddress.base58EncodedString
        return walletAddress
    }

    private func makeShelleyAddress(from walletPublicKey: Data) throws -> String {
        // [REDACTED_TODO_COMMENT]
        let publicKeyHash = Sodium().genericHash.hash(message: walletPublicKey.toBytes, outputLength: 28)!
        let addressBytes = addressHeaderByte + publicKeyHash
        let bech32 = Bech32()
        let walletAddress = try bech32.encode(CardanoAddressUtils.bech32Hrp, values: Data(addressBytes))
        return walletAddress
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension CardanoAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard !address.isEmpty else {
            return false
        }

        if CardanoAddressUtils.isShelleyAddress(address) {
            return (try? Bech32().decodeLong(address)) != nil

        } else {
            let decoded58 = address.base58DecodedBytes
            guard !decoded58.isEmpty else {
                return false
            }

            guard let cborArray = try? CBORDecoder(input: decoded58).decodeItem(),
                  let addressArray = cborArray[0],
                  let checkSumArray = cborArray[1] else {
                return false
            }

            guard case CBOR.tagged(_, let cborByteString) = addressArray,
                  case CBOR.byteString(let addressBytes) = cborByteString else {
                return false
            }

            guard case CBOR.unsignedInt(let checksum) = checkSumArray else {
                return false
            }

            let calculatedChecksum = UInt64(addressBytes.crc32())
            return calculatedChecksum == checksum
        }
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension CardanoAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsEdKey()

        switch addressType {
        case .default:
            let shelley = try makeShelleyAddress(from: publicKey.blockchainKey)
            return PlainAddress(value: shelley, publicKey: publicKey, type: addressType)
        case .legacy:
            let byron = makeByronAddress(from: publicKey.blockchainKey)
            return PlainAddress(value: byron, publicKey: publicKey, type: addressType)
        }
    }
}
