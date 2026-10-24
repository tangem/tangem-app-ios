//
//  CampaignAccountScope.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum CampaignAccountScope {
    case crypto
    case cryptoAndJoint

    var walletsProvider: CommonTokenSelectorWalletsProvider {
        switch self {
        case .crypto: .cryptoAccounts()
        case .cryptoAndJoint: .cryptoJointAccounts()
        }
    }

    var addTokenAccountFilter: ((AddTokenFlowConfiguration.AccountContext) -> Bool)? {
        switch self {
        case .crypto: { !($0.account is any JointAccountModel) }
        case .cryptoAndJoint: nil
        }
    }

    func accounts(from accountModelsManager: AccountModelsManager) -> [any CryptoAccountModel] {
        switch self {
        case .crypto: AccountModelsAggregator(.crypto).models(from: accountModelsManager)
        case .cryptoAndJoint: AccountModelsAggregator(.crypto, .joint).models(from: accountModelsManager)
        }
    }
}
