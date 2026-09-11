//
//  JointAccountJoinViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization

@MainActor
final class JointAccountJoinViewModel: ObservableObject {
    let accountIconViewData: AccountIconView.ViewData
    let title: AttributedString
    let subtitle: AttributedString
    let creatorName: String
    let isWalletSelectionAvailable: Bool

    @Published private(set) var walletName: String
    @Published private(set) var walletImage: ImageValue?

    private let preview: JointAccountInvitePreview
    private let availableUserWalletModels: [any UserWalletModel]
    private var selectedUserWalletModel: any UserWalletModel
    private weak var coordinator: JointAccountJoinRoutable?

    init?(
        preview: JointAccountInvitePreview,
        userWalletModels: [any UserWalletModel],
        coordinator: JointAccountJoinRoutable?
    ) {
        let availableUserWalletModels = UserWalletModelsProvider.available(from: userWalletModels)

        guard let userWalletModel = UserWalletModelsProvider.default(from: availableUserWalletModels) else {
            return nil
        }

        self.preview = preview
        self.availableUserWalletModels = availableUserWalletModels
        selectedUserWalletModel = userWalletModel
        isWalletSelectionAvailable = availableUserWalletModels.count > 1
        self.coordinator = coordinator

        accountIconViewData = Self.makeAccountIconViewData(config: preview.config)
        title = Self.makeTitle(accountName: preview.config.name)
        subtitle = Self.makeSubtitle(config: preview.config)
        creatorName = preview.creator.name
        walletName = userWalletModel.name

        loadWalletImage()
    }

    func onCreatorInfoTap() {
        coordinator?.openCreatorDetails(
            name: preview.creator.name,
            address: preview.creator.address,
            accentColor: accountIconViewData.backgroundColor
        )
    }

    func onWalletTap() {
        let accountSelectorViewModel = AccountSelectorViewModel(
            userWalletModels: availableUserWalletModels,
            preferredDisplayMode: .wallets
        ) { [weak self] selectedCell in
            self?.select(userWalletModel: selectedCell.userWalletModel)
            self?.coordinator?.closeWalletSelection()
        }

        coordinator?.openWalletSelection(accountSelectorViewModel: accountSelectorViewModel)
    }

    func onContinueTap() {
        coordinator?.continueJoin(userWalletModel: selectedUserWalletModel)
    }

    func onCloseTap() {
        coordinator?.closeJoin()
    }
}

// MARK: - Private

private extension JointAccountJoinViewModel {
    func select(userWalletModel: any UserWalletModel) {
        selectedUserWalletModel = userWalletModel
        walletName = userWalletModel.name
        walletImage = nil

        loadWalletImage()
    }

    func loadWalletImage() {
        let userWalletModel = selectedUserWalletModel

        Task { [weak self] in
            let image = await userWalletModel.walletImageProvider.loadSmallImage()

            // A wallet picked while this one was still loading keeps its own icon
            guard let self, selectedUserWalletModel.userWalletId == userWalletModel.userWalletId else {
                return
            }

            walletImage = image
        }
    }

    static func makeAccountIconViewData(config: JointAccountSignedConfig) -> AccountIconView.ViewData {
        let icon = AccountModel.CompositeIcon(rawName: config.icon, rawColor: config.iconColor)
            ?? AccountModel.CompositeIcon(name: .letter, color: .azure)

        return AccountModelUtils.UI.iconViewData(compositeIcon: icon, accountName: config.name)
    }

    static func makeTitle(accountName: String) -> AttributedString {
        var title = AttributedString(Localization.jointAccountJoinTitle(accountName))
        title.foregroundColor = DesignSystem.Color.textSecondary

        if let range = title.range(of: accountName) {
            title[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return title
    }

    static func makeSubtitle(config: JointAccountSignedConfig) -> AttributedString {
        let signers = Localization.jointAccountJoinSubtitleValue(config.threshold, config.membersCount)
        var subtitle = AttributedString(Localization.jointAccountJoinSubtitle(signers))
        subtitle.foregroundColor = DesignSystem.Color.textSecondary

        if let range = subtitle.range(of: signers) {
            subtitle[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return subtitle
    }
}
