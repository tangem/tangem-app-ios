//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class BitcoinAddressService: AddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    
    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        return bech32.makeAddress(from: walletPublicKey)
    }
    
    public func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
    
    public func makeAddresses(from walletPublicKey: Data) -> [Address] {
        let bech32AddressString = bech32.makeAddress(from: walletPublicKey)
        let legacyAddressString = legacy.makeAddress(from: walletPublicKey)
        
        let bech32Address = BitcoinAddress(type: .bech32, value: bech32AddressString)
        
        let legacyAddress = BitcoinAddress(type: .legacy, value: legacyAddressString)
        
        return [bech32Address, legacyAddress]
    }
    
    public func make1Of2MultisigAddresses(firstPublicKey: Data, secondPublicKey: Data) throws -> [Address] {
        guard let script = try create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }
        let legacyAddressString = legacy.makeMultisigAddress(from: script.data.sha256Ripemd160)
        let scriptAddress = BitcoinScriptAddress(script: script, value: legacyAddressString, type: .legacy)
        let bech32AddressString = bech32.makeMultisigAddress(from: script.data.sha256())
        let bech32Address = BitcoinScriptAddress(script: script, value: bech32AddressString, type: .bech32)
        return [bech32Address, scriptAddress]
    }
    
    private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> HDWalletScript? {
        var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> HDPublicKey in
            let key = try Secp256k1Key(with: key)
            let compressed = try key.compress()
            let deCompressed = try key.decompress()
            return HDPublicKey(uncompressedPublicKey: deCompressed, compressedPublicKey: compressed, coin: .bitcoin)
        }
        pubKeys.sort(by: { $0.compressedPublicKey.lexicographicallyPrecedes($1.compressedPublicKey) })
        return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
    }
}

public class BitcoinLegacyAddressService: AddressService {
    private let converter: Base58AddressConverter
    
    init(networkParams: INetwork) {
        converter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let publicKey = BitcoinCorePublicKey(withAccount: 0,
                                             index: 0,
                                             external: true,
                                             hdPublicKeyData: walletPublicKey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2pkh).stringValue
        
        return address
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            _ = try converter.convert(address: address)
            return true
        } catch {
            return false
        }
    }
    
    public func makeMultisigAddress(from scriptHash: Data) -> String {
        let address = try! converter.convert(keyHash: scriptHash, type: .p2sh).stringValue
        
        return address
    }
}


public class BitcoinBech32AddressService: AddressService {
    private let converter: SegWitBech32AddressConverter
    
    init(networkParams: INetwork) {
        let scriptConverter = ScriptConverter()
        converter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: scriptConverter)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let compressedKey = try! Secp256k1Key(with: walletPublicKey).compress()
        let publicKey = BitcoinCorePublicKey(withAccount: 0,
                                             index: 0,
                                             external: true,
                                             hdPublicKeyData: compressedKey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2wpkh).stringValue
        
        return address
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            _ = try converter.convert(address: address)
            return true
        } catch {
            return false
        }
    }
    
    public func makeMultisigAddress(from scriptHash: Data) -> String {
        print("Script hash hex: ", scriptHash.hex)
        let address = try! converter.convert(scriptHash: scriptHash).stringValue
        
        return address
    }
}

extension BitcoinAddressService: MultisigAddressProvider {
    public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) -> [Address]? {
        do {
            return try make1Of2MultisigAddresses(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey)
        } catch {
            print(error)
            return nil
        }
    }
}
