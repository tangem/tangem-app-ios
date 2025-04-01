//
//  UnspentOutputManager+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension UnspentOutputManager where Self == CommonUnspentOutputManager {
    static func bitcoin(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .bitcoin(isTestnet: isTestnet),
            lockingScriptBuilder: .bitcoin(isTestnet: isTestnet)
        )
    }

    static func litecoin(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .litecoin(),
            lockingScriptBuilder: .litecoin()
        )
    }

    static func bitcoinCash(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .bitcoinCash(isTestnet: isTestnet),
            lockingScriptBuilder: .bitcoinCash(isTestnet: isTestnet)
        )
    }

    static func dogecoin(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .dogecoin(),
            lockingScriptBuilder: .dogecoin()
        )
    }

    static func dash(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .dash(isTestnet: isTestnet),
            lockingScriptBuilder: .dash(isTestnet: isTestnet)
        )
    }

    static func ravencoin(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .ravencoin(isTestnet: isTestnet),
            lockingScriptBuilder: .ravencoin(isTestnet: isTestnet)
        )
    }

    static func ducatus(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .ducatus(),
            lockingScriptBuilder: .ducatus()
        )
    }

    static func clore(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .clore(),
            lockingScriptBuilder: .clore()
        )
    }

    static func radiant(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .radiant(),
            lockingScriptBuilder: .radiant()
        )
    }

    static func kaspa(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .kaspa(),
            lockingScriptBuilder: .kaspa()
        )
    }

    static func fact0rn(address: any Address) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .fact0rn(),
            lockingScriptBuilder: .fact0rn()
        )
    }

    static func pepecoin(address: any Address, isTestnet: Bool) -> Self {
        CommonUnspentOutputManager(
            address: address,
            preImageTransactionBuilder: .pepecoin(isTestnet: isTestnet),
            lockingScriptBuilder: .pepecoin(isTestnet: isTestnet)
        )
    }
}
