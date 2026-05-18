//
//  SwapRateDisplaySideResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("SwapRateDisplaySideResolver")
struct SwapRateDisplaySideResolverTests {
    // MARK: - Stable ↔ Stable

    @Test("USDT vs USDC: USDT is base (higher ranked)")
    func stableToStable_usdtVsUsdc() {
        let usdt = makeToken(id: "tether", symbol: "USDT")
        let usdc = makeToken(id: "usd-coin", symbol: "USDC")

        #expect(SwapRateDisplaySideResolver.resolve(from: usdt, to: usdc) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: usdc, to: usdt) == .toIsBase)
    }

    @Test("USDC vs DAI: USDC is base")
    func stableToStable_usdcVsDai() {
        let usdc = makeToken(id: "usd-coin", symbol: "USDC")
        let dai = makeToken(id: "dai", symbol: "DAI")

        #expect(SwapRateDisplaySideResolver.resolve(from: usdc, to: dai) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: dai, to: usdc) == .toIsBase)
    }

    // MARK: - Coin ↔ Stable

    @Test("ETH ↔ USDT: ETH is base regardless of direction")
    func coinToStable_ethUsdt() {
        let eth = makeNativeEthereum()
        let usdt = makeToken(id: "tether", symbol: "USDT")

        #expect(SwapRateDisplaySideResolver.resolve(from: eth, to: usdt) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: usdt, to: eth) == .toIsBase)
    }

    @Test("AAVE ↔ USDC: AAVE is base regardless of direction")
    func coinToStable_aaveUsdc() {
        let aave = makeToken(id: "aave", symbol: "AAVE")
        let usdc = makeToken(id: "usd-coin", symbol: "USDC")

        #expect(SwapRateDisplaySideResolver.resolve(from: aave, to: usdc) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: usdc, to: aave) == .toIsBase)
    }

    // MARK: - Coin ↔ Coin

    @Test("BTC ↔ ETH: ETH is the base regardless of direction")
    func coinToCoin_btcEth() {
        let btc = makeNativeBitcoin()
        let eth = makeNativeEthereum()

        #expect(SwapRateDisplaySideResolver.resolve(from: eth, to: btc) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: btc, to: eth) == .toIsBase)
    }

    @Test("AAVE ↔ BTC: AAVE is the base regardless of direction")
    func coinToCoin_aaveBtc() {
        let aave = makeToken(id: "aave", symbol: "AAVE")
        let btc = makeNativeBitcoin()

        #expect(SwapRateDisplaySideResolver.resolve(from: aave, to: btc) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: btc, to: aave) == .toIsBase)
    }

    @Test("UNI ↔ ETH: UNI is the base regardless of direction")
    func coinToCoin_uniEth() {
        let uni = makeToken(id: "uniswap", symbol: "UNI")
        let eth = makeNativeEthereum()

        #expect(SwapRateDisplaySideResolver.resolve(from: uni, to: eth) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: eth, to: uni) == .toIsBase)
    }

    @Test("AAVE → UNI (no BTC/ETH): receive (UNI) is the base")
    func coinToCoin_default() {
        let aave = makeToken(id: "aave", symbol: "AAVE")
        let uni = makeToken(id: "uniswap", symbol: "UNI")

        #expect(SwapRateDisplaySideResolver.resolve(from: aave, to: uni) == .toIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: uni, to: aave) == .toIsBase)
    }

    @Test("Token with unknown id is treated as a non-stable coin")
    func unknownIdTreatedAsCoin() {
        let unknown = makeToken(id: "some-random-id", symbol: "RND")
        let usdc = makeToken(id: "usd-coin", symbol: "USDC")

        #expect(unknown.isStablecoin == false)
        // Coin ↔ Stable: coin is the base
        #expect(SwapRateDisplaySideResolver.resolve(from: unknown, to: usdc) == .fromIsBase)
        #expect(SwapRateDisplaySideResolver.resolve(from: usdc, to: unknown) == .toIsBase)
    }

    @Test("Token with nil id is non-stable, even with USDT symbol")
    func nilIdNotStable() {
        let symbolOnlyUsdt = makeToken(id: nil, symbol: "USDT")
        #expect(symbolOnlyUsdt.isStablecoin == false)
    }

    // MARK: - TokenItem flags

    @Test("Native BTC blockchain is recognized as Bitcoin")
    func isBitcoinFlag() {
        #expect(makeNativeBitcoin().isBitcoin == true)
        #expect(makeNativeEthereum().isBitcoin == false)
        // WBTC token (symbol BTC-ish) is not native BTC
        let wbtc = makeToken(id: "wrapped-bitcoin", symbol: "WBTC")
        #expect(wbtc.isBitcoin == false)
    }

    @Test("Native Ethereum blockchain is recognized as Ethereum")
    func isEthereumFlag() {
        #expect(makeNativeEthereum().isEthereum == true)
        #expect(makeNativeBitcoin().isEthereum == false)
    }

    // MARK: - Helpers

    private func makeNativeBitcoin() -> TokenItem {
        .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    }

    private func makeNativeEthereum() -> TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    private func makeToken(id: String?, symbol: String) -> TokenItem {
        .token(
            .init(name: symbol, symbol: symbol, contractAddress: "0x\(symbol)", decimalCount: 18, id: id),
            .init(.ethereum(testnet: false), derivationPath: nil)
        )
    }
}
