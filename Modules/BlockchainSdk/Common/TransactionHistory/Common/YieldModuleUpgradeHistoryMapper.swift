//
//  YieldModuleUpgradeHistoryMapper.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum YieldModuleUpgradeHistoryMapper {
    static func innerMethodId(calldata: String?, blockchain: Blockchain) -> String? {
        guard
            let calldata,
            let upgrade = UpgradeToAndCallMethod(calldata: calldata),
            YieldModuleImplementations.version(ofImplementation: upgrade.newImplementation, on: blockchain) != nil,
            upgrade.callData.count >= Constants.methodIdLength
        else {
            return nil
        }

        return Data(upgrade.callData.prefix(Constants.methodIdLength)).hex().addHexPrefix()
    }
}

// MARK: - Constants

private extension YieldModuleUpgradeHistoryMapper {
    enum Constants {
        static let methodIdLength = 4
    }
}
