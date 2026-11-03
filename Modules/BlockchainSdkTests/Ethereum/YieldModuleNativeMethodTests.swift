//
//  YieldModuleNativeMethodTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift
@testable import BlockchainSdk
import Testing

@Suite("Yield Module native ETH and Aave liquidity calls")
struct YieldModuleNativeMethodTests {
    private let wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    private let paddedWethAddress = "000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    @Test("Each selector is the first 4 bytes of keccak-256 of the contract signature")
    func selectorsMatchContractSignatures() {
        let methods: [(signature: String, method: SmartContractMethod)] = [
            ("wrappedNative()", WrappedNativeMethod()),
            ("entrySuspended(address)", EntrySuspendedMethod(tokenContractAddress: wethAddress)),
            ("pool()", YieldModulePoolMethod()),
            ("enterProtocolByOwnerWithNative()", EnterProtocolByOwnerWithNativeMethod()),
            ("enterProtocolByOwner(address,uint256)", EnterProtocolWithAmountMethod(tokenContractAddress: wethAddress, amount: .zero)),
            ("withdrawNative(uint256)", WithdrawNativeMethod(amount: .zero)),
            ("withdrawAndDeactivateNative()", WithdrawAndDeactivateNativeMethod()),
            ("getVirtualUnderlyingBalance(address)", VirtualUnderlyingBalanceMethod(assetContractAddress: wethAddress)),
        ]

        for (signature, method) in methods {
            let selector = Data(signature.utf8).sha3(.keccak256).prefix(4)

            #expect(method.methodId == "0x" + selector.hex(), "\(signature)")
        }
    }

    @Test("Encodes wrappedNative()")
    func wrappedNative() {
        #expect(WrappedNativeMethod().data.hex() == "eb6d3a11")
    }

    @Test("Encodes entrySuspended(address) with the token address as a 32-byte word")
    func entrySuspended() {
        let data = EntrySuspendedMethod(tokenContractAddress: wethAddress).data

        #expect(data.hex() == "729b4fc8" + paddedWethAddress)
    }

    @Test("Encodes pool()")
    func pool() {
        #expect(YieldModulePoolMethod().data.hex() == "16f0115b")
    }

    @Test("Encodes enterProtocolByOwnerWithNative() without arguments, the amount travels as the transaction value")
    func enterProtocolByOwnerWithNative() {
        #expect(EnterProtocolByOwnerWithNativeMethod().data.hex() == "0921ecd4")
    }

    @Test("Encodes enterProtocolByOwner(address,uint256) with the token address and the amount as 32-byte words")
    func enterProtocolByOwnerWithAmount() {
        let halfEther = BigUInt("500000000000000000")

        let data = EnterProtocolWithAmountMethod(tokenContractAddress: wethAddress, amount: halfEther).data

        #expect(data.hex() == "3e44dfd2" + paddedWethAddress + "00000000000000000000000000000000000000000000000006f05b59d3b20000")
    }

    @Test("Encodes withdrawNative(uint256) with the amount in wei")
    func withdrawNative() {
        let halfEther = BigUInt("500000000000000000")

        let data = WithdrawNativeMethod(amount: halfEther).data

        #expect(data.hex() == "84276d81" + "00000000000000000000000000000000000000000000000006f05b59d3b20000")
    }

    @Test("Encodes withdrawNative(uint256) with a zero amount as an all-zero word")
    func withdrawNativeZeroAmount() {
        let data = WithdrawNativeMethod(amount: .zero).data

        #expect(data.hex() == "84276d81" + String(repeating: "0", count: 64))
    }

    @Test("Encodes withdrawNative(uint256) with the largest uint256 amount")
    func withdrawNativeMaxAmount() {
        let maxUInt256 = BigUInt(2).power(256) - 1

        let data = WithdrawNativeMethod(amount: maxUInt256).data

        #expect(data.hex() == "84276d81" + String(repeating: "f", count: 64))
    }

    @Test("Encodes withdrawAndDeactivateNative()")
    func withdrawAndDeactivateNative() {
        #expect(WithdrawAndDeactivateNativeMethod().data.hex() == "4423380d")
    }

    @Test("Encodes getVirtualUnderlyingBalance(address) with the asset address as a 32-byte word")
    func virtualUnderlyingBalance() {
        let data = VirtualUnderlyingBalanceMethod(assetContractAddress: wethAddress).data

        #expect(data.hex() == "6fb07f96" + paddedWethAddress)
    }
}
