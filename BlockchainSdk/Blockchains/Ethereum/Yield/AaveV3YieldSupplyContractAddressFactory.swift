//
//  AaveV3YieldSupplyContractAddressFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

class AaveV3YieldSupplyContractAddressFactory {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func getFactoryAddress() throws -> String {
        switch blockchain {
        case .ethereum(let testnet) where testnet: "0x62bc085Ef9e7700Af1F572cefCfdf4228E4EA3b8"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }

    func getProcessorAddress() throws -> String {
        switch blockchain {
        case .ethereum(let testnet) where testnet: "0x234D7653Ee1B6d8d87D008e613757Ac2f6Bd5a69"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }

    func poolContractAddress() throws -> String {
        switch blockchain {
        case .ethereum(let testnet) where testnet: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }
}
