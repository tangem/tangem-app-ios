//
//  UserTokensReorderingLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct UserTokensReorderingLogger {
    let walletModels: [any WalletModel]

    func logReorder(
        existingAccount: StoredCryptoAccount,
        editedTokens: UserTokensRepositoryUpdateRequest,
        source: UserTokensReorderingSource
    ) {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)

        var output: [String] = []
        output.append("Performing reordering (initiated by \(source))")

        output.append("Old grouping option: \(existingAccount.grouping)")
        output.append("Old sorting option: \(existingAccount.sorting)")
        output.append("Old token list:")
        for item in existingAccount.tokens {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        output.append("New grouping option: \(editedTokens.grouping)")
        output.append("New sorting option: \(editedTokens.sorting)")
        output.append("New token list:")
        for item in editedTokens.tokens {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        AppLogger.info(output.joined(separator: "\n"))
    }

    private func description(
        for item: StoredCryptoAccount.Token,
        walletModelsKeyedByIds: [WalletModelId: any WalletModel]
    ) -> String {
        let walletModel = item.walletModelId.flatMap { walletModelsKeyedByIds[$0] }

        return objectDescription(
            "Token: \(item.name)",
            userInfo: [
                "state": description(for: walletModel?.state),
                "canUseQuotes": description(for: walletModel?.canUseQuotes),
                "isCustom": description(for: walletModel?.isCustom),
            ]
        )
    }

    private func description(for state: WalletModelState?) -> String {
        guard let state else {
            return .unknown
        }

        switch state {
        case .created:
            return "created"
        case .loaded:
            return "loaded"
        case .loading:
            return "loading"
        case .noAccount:
            return "noAccount"
        case .failed(let error):
            return "failed (\(error.localizedDescription))"
        }
    }

    private func description(for optionalValue: any OptionalProtocol) -> String {
        guard let optionalValue = optionalValue.wrapped else {
            return .unknown
        }

        return String(describing: optionalValue)
    }
}
