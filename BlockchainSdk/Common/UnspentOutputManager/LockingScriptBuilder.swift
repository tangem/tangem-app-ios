//
//  LockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import WalletCore
import BitcoinCore

protocol LockingScriptBuilder {
    func lockingScript(for address: String) throws -> Data
}

extension LockingScriptBuilder where Self == WalletCoreLockingScriptBuilder {
    static var bitcoin: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .bitcoin) }
    static var litecoin: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .litecoin) }
    static var ravencoin: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .ravencoin) }
    static var bitcoinCash: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .bitcoinCash) }
    static var dash: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .dash) }
    static var dogecoin: LockingScriptBuilder { WalletCoreLockingScriptBuilder(coin: .dogecoin) }
    static var ducatus: LockingScriptBuilder { Bech32LockingScriptBuilder(bech32PrefixPattern: DucatusNetworkParams().bech32PrefixPattern) }
    static var fact0rn: LockingScriptBuilder { Bech32LockingScriptBuilder(bech32PrefixPattern: Fact0rnMainNetworkParams().bech32PrefixPattern) }
}

struct WalletCoreLockingScriptBuilder: LockingScriptBuilder {
    private let coin: CoinType

    /// private init to restrict unsupported CoinType
    fileprivate init(coin: CoinType) {
        self.coin = coin
    }

    func lockingScript(for address: String) throws -> Data {
        let script = WalletCore.BitcoinScript.lockScriptForAddress(address: address, coin: coin)
        let lockScript = script.data
        return lockScript
    }
}

struct Bech32LockingScriptBuilder: LockingScriptBuilder {
    private let converter: IAddressConverter

    init(bech32PrefixPattern: String) {
        // TEMP: Will replaced by our own solution
        converter = SegWitBech32AddressConverter(prefix: bech32PrefixPattern, scriptConverter: ScriptConverter())
    }

    func lockingScript(for address: String) throws -> Data {
        try converter.convert(address: address).lockingScript
    }
}
