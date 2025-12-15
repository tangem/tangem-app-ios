//
//  WalletModelFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum WalletModelFinder {
    @Injected(\.userWalletRepository)
    private static var userWalletRepository: UserWalletRepository

    static func findMainWalletModel(defaultAddress: String) throws -> Result {
        for userWalletModel in userWalletRepository.models {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
            if let walletModel = walletModels.first(where: { $0.isMainToken && $0.defaultAddressString == defaultAddress }) {
                return Result(userWalletModel: userWalletModel, walletModel: walletModel)
            }
        }

        throw Error.walletModelNotFound
    }

    static func findWalletModel(tokenItem: TokenItem) throws -> Result {
        for userWalletModel in userWalletRepository.models {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
            if let walletModel = walletModels.first(where: { $0.tokenItem == tokenItem }) {
                return Result(userWalletModel: userWalletModel, walletModel: walletModel)
            }
        }

        throw Error.walletModelNotFound
    }

    static func findWalletModel(userWalletId: UserWalletId, tokenItem: TokenItem) throws -> Result {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            throw Error.userWalletModelNotFound
        }

        let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
        let walletModel = walletModels.first(where: { $0.tokenItem == tokenItem })

        guard let walletModel else {
            AppLogger.error(error: "WalletModel not found for the specified token item: \(tokenItem)")
            throw Error.walletModelNotFound
        }

        return .init(userWalletModel: userWalletModel, walletModel: walletModel)
    }
}

extension WalletModelFinder {
    enum Error: LocalizedError {
        case userWalletModelNotFound
        case walletModelNotFound

        var errorDescription: String? {
            switch self {
            case .userWalletModelNotFound: "User wallet model not found"
            case .walletModelNotFound: "Wallet model not found"
            }
        }
    }

    struct Result {
        let userWalletModel: UserWalletModel
        let walletModel: any WalletModel
    }
}
