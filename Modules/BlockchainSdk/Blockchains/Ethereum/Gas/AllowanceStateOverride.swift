//
//  AllowanceStateOverride.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift
import TangemFoundation

// MARK: - AllowanceSlot

/// Points at the `_allowances` mapping in one ERC20 contract: a base storage slot plus its layout.
/// `baseSlot` is a small number for flat layouts, or a pre-computed 32-byte value for ERC-7201 namespaced storage.
struct AllowanceSlot {
    enum Layout {
        case solidity
        case vyper
    }

    let baseSlot: BigUInt
    let layout: Layout

    init(baseSlot: BigUInt, layout: Layout = .solidity) {
        self.baseSlot = baseSlot
        self.layout = layout
    }

    static func solidity(_ slot: UInt64) -> Self {
        AllowanceSlot(baseSlot: BigUInt(slot), layout: .solidity)
    }

    static func vyper(_ slot: UInt64) -> Self {
        AllowanceSlot(baseSlot: BigUInt(slot), layout: .vyper)
    }

    func storageKey(owner: String, spender: String) -> Data {
        let ownerBytes = Self.pad32(Data(hexString: owner))
        let spenderBytes = Self.pad32(Data(hexString: spender))
        let slotBytes = Self.pad32(baseSlot.serialize())

        // Inner level is identical for both languages — only the outer concatenation order differs.
        // Solidity: keccak256(spender . keccak256(owner . slot)); Vyper: keccak256(keccak256(owner . slot) . spender).
        // https://jellopaper.org/hashed-locations/
        let inner = (ownerBytes + slotBytes).sha3(.keccak256)

        switch layout {
        case .solidity:
            return (spenderBytes + inner).sha3(.keccak256)
        case .vyper:
            return (inner + spenderBytes).sha3(.keccak256)
        }
    }

    // MARK: Candidates

    /// OZ v5 ERC20 `_allowances` slot: ERC-7201 namespace `openzeppelin.storage.ERC20`, base `…bace00`,
    /// `_allowances` at offset 1 → `…bace01`. Re-derivable via `erc7201Base(namespace:offsetInStruct:)` (see tests).
    /// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v5.0.0/contracts/token/ERC20/ERC20Upgradeable.sol
    /// ERC-7201 formula: https://eips.ethereum.org/EIPS/eip-7201
    static let ozV5ERC20Allowances = BigUInt(
        "52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace01",
        radix: 16
    )!

    /// All realistic `_allowances` slots — overridden together in one `eth_estimateGas` request.
    /// Overriding a slot the contract doesn't read is a no-op, so we throw every realistic candidate at once.
    static let candidates: [AllowanceSlot] = {
        // OZ v4 ERC20Upgradeable: `Initializable`@0, `ContextUpgradeable.__gap[50]`@1–50, `_balances`@51,
        // `_allowances`@52 (canonical chain only, no subclass storage above `_allowances`).
        // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.6/contracts/token/ERC20/ERC20Upgradeable.sol
        let ozV4UpgradeableAllowancesSlot: UInt64 = 52

        var slots: [AllowanceSlot] = []

        // Flat Solidity range — OZ v2-v4 (non-upgradeable), USDT, DAI, WETH, Solmate. Empirical envelope.
        slots += (0 ..< 20).map { AllowanceSlot.solidity(UInt64($0)) }

        // The only realistic mid-range slot observed in the wild — OZ v4 upgradeable's `_allowances@52`.
        slots.append(.solidity(ozV4UpgradeableAllowancesSlot))

        // OZ v5 ERC-7201 namespaced storage — far slot derived from the namespace string.
        slots.append(AllowanceSlot(baseSlot: ozV5ERC20Allowances, layout: .solidity))

        // Vyper-compiled tokens (rare; e.g. Curve). Best-effort: operand order follows jellopaper
        // (see `storageKey`), but unverified by a golden vector and version-dependent — Vyper moved
        // toward hash-based slots (vyperlang/vyper#1733), so flat 0..<5 may miss newer contracts.
        slots += (0 ..< 5).map { AllowanceSlot.vyper(UInt64($0)) }

        return slots
    }()

    // MARK: Verification helper (dev / tests only — not called in production)

    /// Re-derives an ERC-7201 namespace slot: `keccak256(abi.encode(keccak256(namespace) - 1)) & ~0xff`,
    /// plus the struct offset. Used by tests to verify hardcoded constants like `ozV5ERC20Allowances`.
    static func erc7201Base(namespace: String, offsetInStruct: BigUInt = 0) -> BigUInt {
        let namespaceHash = Data(namespace.utf8).sha3(.keccak256)
        let namespaceHashMinusOne = BigUInt(namespaceHash) - 1
        let abiEncodedSeed = pad32(namespaceHashMinusOne.serialize())
        let slotHash = abiEncodedSeed.sha3(.keccak256)

        // Clears the lowest byte to leave a 256-slot gap for struct fields, per EIP-7201.
        let lowByteMask = ((BigUInt(1) << 256) - 1) ^ BigUInt(0xff)
        let namespaceBase = BigUInt(slotHash) & lowByteMask

        return namespaceBase + offsetInStruct
    }

    /// Left-pads to a 32-byte EVM word. Inputs are always <= 32 bytes here (20-byte addresses,
    /// unsigned `BigUInt` slots), so a plain left-pad is sufficient and never truncates.
    private static func pad32(_ input: Data) -> Data {
        input.leadingZeroPadding(toLength: 32)
    }
}

// MARK: - EthereumAccountOverride

/// One Ethereum account's override for `eth_estimateGas` / `eth_call`: which storage slots to pretend
/// have which values during simulation.
public struct EthereumAccountOverride: Encodable {
    public let stateDiff: [String: String]

    public init(stateDiff: [String: String]) {
        self.stateDiff = stateDiff
    }

    /// Builds state overrides that fake unlimited ERC20 allowance for `(owner, spender)` on `tokenAddress`.
    /// Returns `{ token (lowercased): override }`, ready to encode as the 3rd `eth_estimateGas` param.
    public static func unlimitedAllowance(
        tokenAddress: String,
        owner: String,
        spender: String
    ) -> [String: Self] {
        let maxUInt256Hex = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
        let stateDiff = AllowanceSlot.candidates.reduce(into: [String: String]()) { result, slot in
            let key = slot.storageKey(owner: owner, spender: spender)
            result["0x" + key.hex()] = maxUInt256Hex
        }

        return [tokenAddress.lowercased(): Self(stateDiff: stateDiff)]
    }
}
