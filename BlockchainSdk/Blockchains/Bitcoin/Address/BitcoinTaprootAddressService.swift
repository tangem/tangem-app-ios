//
//  BitcoinTaprootAddressService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class BitcoinTaprootAddressService {
    private let taprootBuilder: TaprootLockingScriptBuilder

    init(networkParams: UTXONetworkParams) {
        taprootBuilder = .init(network: networkParams)
    }
}

// MARK: - AddressValidator

extension BitcoinTaprootAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        let taprootAddress = try? taprootBuilder.decode(address: address)
        return taprootAddress != nil
    }
}
