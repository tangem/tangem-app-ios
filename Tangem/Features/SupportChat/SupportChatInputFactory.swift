//
//  SupportChatInputFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The chat about the device as a whole rather than about a flow in progress: the logs carry every wallet on
/// it and the selected one is who Usedesk matches the conversation to. Shared by the entry points that open
/// the chat as it is — Details and the `tangem://support` link — so support meets the same client either way.
struct SupportChatInputFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @MainActor
    func makeInput(source: Analytics.SupportChatSource) -> SupportChatInputModel {
        let data = userWalletRepository.models.map {
            DetailsFeedbackData(
                userWalletEmailData: $0.emailData,
                walletModels: AccountWalletModelsAggregator.walletModels(from: $0.accountModelsManager)
            )
        }

        return SupportChatInputModel(
            logsComposer: LogsComposer(infoProvider: DetailsFeedbackDataCollector(data: data)),
            userIdentifier: userWalletRepository.selectedModel?.userWalletId.stringValue.lowercased(),
            source: source
        )
    }
}
