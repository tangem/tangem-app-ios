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
        existingList: StoredUserTokenList,
        editedList: StoredUserTokenList,
        source: UserTokensReorderingSource
    ) {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)

        var output: [String] = []
        output.append("Performing reordering (initiated by \(source))")

        output.append("Old grouping option: \(existingList.grouping)")
        output.append("Old sorting option: \(existingList.sorting)")
        output.append("Old token list:")
        for item in existingList.entries {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        output.append("New grouping option: \(editedList.grouping)")
        output.append("New sorting option: \(editedList.sorting)")
        output.append("New token list:")
        for item in editedList.entries {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        AppLogger.info(output.joined(separator: "\n"))
    }

    private func description(
        for item: StoredUserTokenList.Entry,
        walletModelsKeyedByIds: [WalletModelId: any WalletModel]
    ) -> String {
        let walletModel = walletModelsKeyedByIds[item.walletModelId]

        return objectDescription(
            "Token: \(item.name)",
            userInfo: [
                "state": description(for: walletModel?.walletModelState),
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
