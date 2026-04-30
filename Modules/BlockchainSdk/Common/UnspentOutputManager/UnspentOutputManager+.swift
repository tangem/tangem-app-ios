//
//  UnspentOutputManager+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension UnspentOutputManager where Self == CommonUnspentOutputManager {
    static func bitcoin(sorter: UTXOTransactionInputsSorter = BIP69UTXOTransactionInputsSorter(), isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .bitcoin(isTestnet: isTestnet),
            sorter: sorter,
            lockingScriptBuilder: .bitcoin(isTestnet: isTestnet)
        )
    }

    static func litecoin() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .litecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .litecoin()
        )
    }

    static func bitcoinCash(isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .bitcoinCash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .bitcoinCash(isTestnet: isTestnet)
        )
    }

    static func dogecoin() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .dogecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dogecoin()
        )
    }

    static func dash(isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .dash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dash(isTestnet: isTestnet)
        )
    }

    static func ravencoin(isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .ravencoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ravencoin(isTestnet: isTestnet)
        )
    }

    static func ducatus() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .ducatus(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ducatus()
        )
    }

    static func clore() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .clore(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .clore()
        )
    }

    static func radiant() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .radiant(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .radiant()
        )
    }

    static func kaspa() -> Self {
        KaspaUnspentOutputManager(
            preImageTransactionBuilder: .kaspa(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .kaspa()
        )
    }

    static func fact0rn() -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .fact0rn(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .fact0rn()
        )
    }

    static func pepecoin(isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            preImageTransactionBuilder: .pepecoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .pepecoin(isTestnet: isTestnet)
        )
    }
}
