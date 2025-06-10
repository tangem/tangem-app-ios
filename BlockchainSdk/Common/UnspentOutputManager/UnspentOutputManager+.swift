//
//  UnspentOutputManager+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension UnspentOutputManager where Self == CommonUnspentOutputManager {
    static func bitcoin(address: any Address, sorter: UTXOTransactionInputsSorter = BIP69UTXOTransactionInputsSorter(), isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .bitcoin(isTestnet: isTestnet),
            sorter: sorter,
            lockingScriptBuilder: .bitcoin(isTestnet: isTestnet)
        )
    }

    static func litecoin(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .litecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .litecoin()
        )
    }

    static func bitcoinCash(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .bitcoinCash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .bitcoinCash(isTestnet: isTestnet)
        )
    }

    static func dogecoin(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .dogecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dogecoin()
        )
    }

    static func dash(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .dash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dash(isTestnet: isTestnet)
        )
    }

    static func ravencoin(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .ravencoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ravencoin(isTestnet: isTestnet)
        )
    }

    static func ducatus(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .ducatus(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ducatus()
        )
    }

    static func clore(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .clore(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .clore()
        )
    }

    static func radiant(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .radiant(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .radiant()
        )
    }

    static func kaspa(address: any Address) -> Self {
        KaspaUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .kaspa(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .kaspa()
        )
    }

    static func fact0rn(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .fact0rn(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .fact0rn()
        )
    }

    static func pepecoin(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .pepecoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .pepecoin(isTestnet: isTestnet)
        )
    }
}
