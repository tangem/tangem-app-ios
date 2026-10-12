//
//  SafeAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import TangemFoundation

/// The counterfactual Safe v1.5.0 address of an owner composition: known before the contract exists and the same on
/// every supported network, since Safe is deployed at canonical addresses on all of them.
///
/// ```
/// initializer = Safe.setup(ownersSortedLowercase, threshold, 0, "", fallbackHandler, 0, 0, 0)
/// salt        = keccak256(keccak256(initializer) ++ uint256(saltNonce))
/// deployData  = proxyCreationCode ++ uint256(uint160(singleton))
/// address     = keccak256(0xff ++ proxyFactory ++ salt ++ keccak256(deployData))[12..31]
/// ```
///
/// - Warning: The owners are sorted *after* they are lowercased. `'B'` (0x42) sorts ahead of `'a'` (0x61), so sorting
/// the checksummed strings orders the initializer differently and yields an address that is not the composition's.
public enum SafeAddressUtils {
    /// - Parameter owners: The address every member signs the Safe's operations with, in any order and any case.
    /// - Throws: `ComputationError`, whose every case would otherwise pass silently as a well-formed address that
    /// simply is not the composition's — the worst outcome for a value funds are sent to.
    public static func compute(
        owners: [String],
        threshold: Int,
        singleton: SafeSingleton
    ) throws(ComputationError) -> String {
        try validate(owners: owners, threshold: threshold)

        let salt = keccak(keccak(initializer(owners: owners, threshold: threshold)) + word(Constants.saltNonce))
        let deploymentData = bytes(of: Constants.proxyCreationCode) + addressWord(singleton.address)
        let proxy = keccak([Constants.create2Prefix] + bytes(of: Constants.proxyFactory) + salt + keccak(deploymentData))

        let address = Array(proxy.suffix(Constants.addressLength)).toHexString()

        // Checksumming only fails on an input that is not hex, which twenty bytes rendered as hex cannot be
        return EVMAddressUtils.toChecksumAddress(address) ?? address.addHexPrefix()
    }

    /// The ABI encoding of `setup`: eight head words, then the owners array, then the empty `data`.
    /// - Note: Internal so that a failing vector can be told apart at this step rather than at the address alone.
    static func initializer(owners: [String], threshold: Int) -> [UInt8] {
        let sorted = owners.map { $0.lowercased() }.sorted()
        let ownersOffset = Constants.setupHeadWords * Constants.wordLength
        let dataOffset = ownersOffset + Constants.wordLength * (1 + sorted.count)

        return bytes(of: Constants.setupSelector)
            + word(ownersOffset) // _owners, offset to the tail
            + word(threshold) // _threshold
            + word(0) // to
            + word(dataOffset) // data, offset to the tail
            + addressWord(Constants.fallbackHandler)
            + word(0) // paymentToken
            + word(0) // payment
            + word(0) // paymentReceiver
            + word(sorted.count) // _owners.length
            + sorted.flatMap(addressWord)
            + word(0) // data.length
    }
}

// MARK: - Private

private extension SafeAddressUtils {
    static func validate(owners: [String], threshold: Int) throws(ComputationError) {
        guard owners.isNotEmpty else {
            throw .noOwners
        }

        if let malformed = owners.first(where: { !$0.isEvmAddress }) {
            throw .malformedOwnerAddress(malformed)
        }

        // Two owners telling apart by case alone make a Safe that cannot be deployed, and the initializer
        // lowercases them, which is where the duplicate would stop being visible
        let lowercased = owners.map { $0.lowercased() }

        guard lowercased.count == lowercased.unique().count else {
            throw .duplicateOwners
        }

        guard (Constants.minThreshold ... owners.count).contains(threshold) else {
            throw .thresholdOutOfRange(threshold: threshold, ownersCount: owners.count)
        }
    }

    static func keccak(_ bytes: [UInt8]) -> [UInt8] {
        bytes.sha3(.keccak256)
    }

    /// - Warning: Non-negative values only, which every caller here is: a negative threshold is turned away by
    /// `validate` before it could be encoded as a small positive number rather than as two's complement.
    static func word(_ value: Int) -> [UInt8] {
        let raw = withUnsafeBytes(of: UInt64(value).bigEndian, Array.init)

        return Array(repeating: 0, count: Constants.wordLength - raw.count) + raw
    }

    /// A 20-byte address left-padded to a 32-byte ABI word.
    static func addressWord(_ address: String) -> [UInt8] {
        Array(repeating: 0, count: Constants.addressWordPadding) + bytes(of: address)
    }

    static func bytes(of hex: String) -> [UInt8] {
        Data(hexString: hex.removeHexPrefix()).bytes
    }
}

// MARK: - Auxiliary types

public extension SafeAddressUtils {
    /// A composition that belongs to no deployable Safe.
    enum ComputationError: Error, Equatable {
        case noOwners
        /// Not a `0x`-prefixed 20-byte hex address, which would lose a nibble or shift the ABI word it is padded into.
        case malformedOwnerAddress(String)
        /// An address appears among the owners more than once, compared without regard to the letter case.
        case duplicateOwners
        /// Outside `1...ownersCount`, so no set of signatures could ever satisfy it.
        case thresholdOutOfRange(threshold: Int, ownersCount: Int)
    }
}

// MARK: - Constants

private extension SafeAddressUtils {
    enum Constants {
        static let proxyFactory = "0x14F2982D601c9458F93bd70B218933A6f8165e7b"
        static let fallbackHandler = "0x3EfCBb83A4A7AfcB4F68D501E2c2203a38be77f4"

        /// `type(SafeProxy).creationCode`, read off `proxyCreationCode()` on the v1.5.0 factory.
        /// - Warning: Not to be recompiled from `SafeProxy.sol` — the trailing metadata hash of a local build differs
        /// from the deployed one. keccak256 of this blob: `0x941b3e88811b2f33b8e26783c7407d2e978404581a21c9f07abf2cad9cb87e12`.
        static let proxyCreationCode = """
        608060405234801561001057600080fd5b506040516101b63803806101b68339818101604052602081101561003357600080\
        fd5b8101908080519060200190929190505050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffff\
        ffffffffffffffffffffffffffffff1614156100ca576040517f08c379a00000000000000000000000000000000000000000\
        0000000000000000815260040180806020018281038252602281526020018061019460229139604001915050604051809103\
        90fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffff\
        ffffffffffffffffffffff16021790555050607b806101196000396000f3fe608060405260005463a619486e60003560e01c\
        14156024578060601b606c5260206060f35b3660008037600080366000845af43d6000803e806040573d6000fd5b3d6000f3\
        fea2646970667358221220e61834ebd2d8cd909d362bf67c47ef58fd665df38e6dd036ce65611101d072e964736f6c634300\
        07060033496e76616c69642073696e676c65746f6e20616464726573732070726f7669646564
        """

        /// keccak256("setup(address[],uint256,address,bytes,address,address,uint256,address)")[0..3]
        static let setupSelector = "0xb63e800d"
        static let setupHeadWords = 8
        static let saltNonce = 0
        static let wordLength = 32
        static let addressLength = 20
        static let addressWordPadding = 12
        static let create2Prefix: UInt8 = 0xff
        static let minThreshold = 1
    }
}
