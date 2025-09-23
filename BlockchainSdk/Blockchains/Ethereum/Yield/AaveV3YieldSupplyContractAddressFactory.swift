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
        case .polygon(let testnet) where testnet == false: "0x685345d16aA462FB52bDB0D73807a199d1c5Ef76"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }

    func getProcessorAddress() throws -> String {
        switch blockchain {
        case .ethereum(let testnet) where testnet: "0x234D7653Ee1B6d8d87D008e613757Ac2f6Bd5a69"
        case .polygon(let testnet) where testnet == false: "0xA32019c38a7EF45b87c09155600EEc457915b782"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }

    func poolContractAddress() throws -> String {
        switch blockchain {
        case .ethereum(let testnet) where testnet: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951"
        case .polygon(let testnet) where testnet == false: "0x794a61358D6845594F94dc1DB02A252b5b4814aD"
        default: throw YieldModuleError.unsupportedBlockchain
        }
    }
}
