//
//  WalletConnectChainRequestResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import ReownWalletKit
import BlockchainSdk
@testable import Tangem

@Suite("WalletConnect switch and add chain requests")
struct WalletConnectChainRequestResolverTests {
    @Test("Switching to a network of the session succeeds without asking the user")
    func switchToSessionNetwork() {
        let resolution = resolve(.switchChain, chainId: "0xa4b1")

        #expect(resolution == .switched(.arbitrum(testnet: false)))
    }

    @Test("Switching to a network outside the session is answered as unrecognized so the dApp asks to add it")
    func switchToNetworkOutsideSession() {
        let resolution = resolve(.switchChain, chainId: "0x1237")

        #expect(resolution == .unrecognizedChain)
    }

    @Test("Switching to a network the app does not support is answered as unrecognized")
    func switchToUnsupportedNetwork() {
        let resolution = resolve(.switchChain, chainId: "0x7a69")

        #expect(resolution == .unrecognizedChain)
    }

    @Test("Adding a network of the session succeeds without asking the user")
    func addSessionNetwork() {
        let resolution = resolve(.addChain, chainId: "0x1")

        #expect(resolution == .alreadyAdded(.ethereum(testnet: false)))
    }

    @Test("Adding a network outside the session goes to the user", arguments: ["0x1237", "0x7a69"])
    func addNetworkOutsideSession(chainId: String) {
        let resolution = resolve(.addChain, chainId: chainId)

        #expect(resolution == .needsUserApproval)
    }

    @Test("A malformed switch is rejected as invalid params")
    func malformedSwitch() {
        #expect(resolve(.switchChain, params: AnyCodable([[String: String]]())) == .invalidParams)
        #expect(resolve(.switchChain, params: AnyCodable([["chainId": 1]])) == .invalidParams)
        #expect(resolve(.switchChain, params: AnyCodable([["chainId": "0x1"], ["chainId": "0xa4b1"]])) == .invalidParams)
    }

    @Test("An add without the fields EIP-3085 requires is rejected as invalid params, even for a session network")
    func malformedAdd() {
        #expect(resolve(.addChain, params: AnyCodable([["chainId": "0x1"]])) == .invalidParams)
    }

    @Test("Other methods are not resolved here", arguments: [WalletConnectMethod.sendTransaction, .personalSign])
    func otherMethods(method: WalletConnectMethod) {
        #expect(resolve(method, chainId: "0x1") == nil)
    }
}

// MARK: - Fixtures

private extension WalletConnectChainRequestResolverTests {
    func resolve(_ method: WalletConnectMethod, chainId: String) -> WalletConnectChainRequestResolver.Resolution? {
        let params = switch method {
        case .addChain:
            AnyCodable([
                WalletConnectAddEthereumChainMessageHandler.RequestParameterEntry(
                    chainId: chainId,
                    blockExplorerUrls: [],
                    nativeCurrency: .init(decimals: 18, name: "Ether", symbol: "ETH"),
                    chainName: "Fixture",
                    rpcUrls: ["https://rpc.fixture.org"]
                ),
            ])
        default:
            AnyCodable([["chainId": chainId]])
        }

        return resolve(method, params: params)
    }

    func resolve(_ method: WalletConnectMethod, params: AnyCodable) -> WalletConnectChainRequestResolver.Resolution? {
        WalletConnectChainRequestResolver.resolve(
            method: method,
            params: params,
            sessionBlockchains: [.ethereum(testnet: false), .arbitrum(testnet: false)]
        )
    }
}
