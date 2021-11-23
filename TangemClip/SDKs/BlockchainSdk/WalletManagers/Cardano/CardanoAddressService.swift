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

public class CardanoAddressService: AddressService {
    private let addressHeaderByte = Data([UInt8(97)])
    
    private let shelley: Bool
    
    public init(shelley: Bool) {
        self.shelley = shelley
    }
    
    public func makeAddresses(from walletPublicKey: Data) -> [Address] {
        if shelley {
            return [
                CardanoAddress(type: .bech32, value: makeShelleyAddress(from: walletPublicKey)),
                CardanoAddress(type: .legacy, value: makeByronAddress(from: walletPublicKey))
            ]
        }
        return [makeCardanoAddress(from: walletPublicKey)]
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        makeCardanoAddress(from: walletPublicKey).value
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty else {
            return false
        }
        
        if CardanoAddressUtils.isShelleyAddress(address) {
            return (try? Bech32().decodeLong(address)) != nil
            
        } else {
            guard let decoded58 = address.base58DecodedData?.bytes,
                !decoded58.isEmpty else {
                    return false
            }
            
            guard let cborArray = try? CBORDecoder(input: decoded58).decodeItem(),
                let addressArray = cborArray[0],
                let checkSumArray = cborArray[1] else {
                    return false
            }
            
            guard case let CBOR.tagged(_, cborByteString) = addressArray,
                case let CBOR.byteString(addressBytes) = cborByteString else {
                    return false
            }
            
            guard case let CBOR.unsignedInt(checksum) = checkSumArray else {
                return false
            }
            
            let calculatedChecksum = UInt64(addressBytes.crc32())
            return calculatedChecksum == checksum
        }
    }
    
    private func makeCardanoAddress(from pubkey: Data) -> CardanoAddress {
        shelley ?
            CardanoAddress(type: .bech32, value: makeShelleyAddress(from: pubkey)) :
            CardanoAddress(type: .legacy, value: makeByronAddress(from: pubkey))
    }
    
    private func makeByronAddress(from walletPublicKey: Data) -> String {
        let hexPublicKeyExtended = walletPublicKey + Data(repeating: 0, count: 32) // extendedPublicKey
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended.toBytes)], [:]] as CBOR).encode() // makePubKeyWithAttributes
        let sha = forSha3.sha3(.sha256)
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)! // calculate blake 2b
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode() // makeHashWithAttributes
        let checksum = UInt64(addr.crc32()) // getCheckSum
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr))
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        let walletAddress = String(base58: Data(hexAddress), alphabet: Base58String.btcAlphabet)
        return walletAddress
    }
    
    private func makeShelleyAddress(from walletPublicKey: Data) -> String {
        let publicKeyHash = Sodium().genericHash.hash(message: walletPublicKey.toBytes, outputLength: 28)!
        let addressBytes = addressHeaderByte + publicKeyHash
        let bech32 = Bech32()
        let walletAddress = bech32.encode(CardanoAddressUtils.bech32Hrp, values: Data(addressBytes))
        return walletAddress
    }
}
