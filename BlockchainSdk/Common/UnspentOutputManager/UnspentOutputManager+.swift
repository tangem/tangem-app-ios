//
//  UnspentOutputManager+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension UnspentOutputManager where Self == CommonUnspentOutputManager {
    static func bitcoin(changeAddress: any Address, sorter: UTXOTransactionInputsSorter = BIP69UTXOTransactionInputsSorter(), isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .bitcoin(isTestnet: isTestnet),
            sorter: sorter,
            lockingScriptBuilder: .bitcoin(isTestnet: isTestnet)
        )
    }

    static func litecoin(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .litecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .litecoin()
        )
    }

    static func bitcoinCash(changeAddress: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .bitcoinCash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .bitcoinCash(isTestnet: isTestnet)
        )
    }

    static func dogecoin(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .dogecoin(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dogecoin()
        )
    }

    static func dash(changeAddress: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .dash(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .dash(isTestnet: isTestnet)
        )
    }

    static func ravencoin(changeAddress: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .ravencoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ravencoin(isTestnet: isTestnet)
        )
    }

    static func ducatus(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .ducatus(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .ducatus()
        )
    }

    static func clore(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .clore(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .clore()
        )
    }

    static func radiant(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .radiant(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .radiant()
        )
    }

    static func kaspa(changeAddress: any Address) -> Self {
        KaspaUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .kaspa(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .kaspa()
        )
    }

    static func fact0rn(changeAddress: any Address) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .fact0rn(),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .fact0rn()
        )
    }

    static func pepecoin(changeAddress: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            changeAddress: changeAddress,
            preImageTransactionBuilder: .pepecoin(isTestnet: isTestnet),
            sorter: BIP69UTXOTransactionInputsSorter(),
            lockingScriptBuilder: .pepecoin(isTestnet: isTestnet)
        )
    }
}
