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
    @Published private(set) var state: State = .loading
    @Published private(set) var walletName: String = ""
    @Published private(set) var walletImage: ImageValue?

    private var selectedUserWalletModel: (any UserWalletModel)?
    private var availableUserWalletModels: [any UserWalletModel] = []

    private let inviteId: String
    private let networkService: JointAccountsNetworkService
    private let userWalletModels: [any UserWalletModel]
    private weak var coordinator: JointAccountJoinRoutable?

    init(
        inviteId: String,
        networkService: JointAccountsNetworkService,
        userWalletModels: [any UserWalletModel],
        coordinator: JointAccountJoinRoutable?
    ) {
        self.inviteId = inviteId
        self.networkService = networkService
        self.userWalletModels = userWalletModels
        self.coordinator = coordinator

        loadInvite()
    }

    func onCreatorInfoTap() {
        guard case .loaded(let content) = state else {
            return
        }

        coordinator?.openCreatorDetails(
            name: content.preview.creator.name,
            address: content.preview.creator.address,
            accentColor: content.accountIconViewData.backgroundColor
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
        guard case .loaded(let content) = state, let selectedUserWalletModel else {
            return
        }

        coordinator?.continueJoin(userWalletModel: selectedUserWalletModel, preview: content.preview)
    }

    func onRetryTap() {
        guard case .loadFailed(let isRetrying) = state, !isRetrying else {
            return
        }

        state = .loadFailed(isRetrying: true)
        loadInvite()
    }

    func onCloseTap() {
        coordinator?.closeJoin()
    }
}

// MARK: - Loading

private extension JointAccountJoinViewModel {
    func loadInvite() {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let preview = try await networkService.getInvitePreview(inviteId: inviteId)
                handle(preview: preview)
            } catch {
                handle(loadingError: error)
            }
        }
    }

    func handle(preview: JointAccountInvitePreview) {
        let available = UserWalletModelsProvider.available(from: userWalletModels)

        guard let userWalletModel = UserWalletModelsProvider.default(from: available) else {
            // Every wallet is locked, so there is none to join with — offered a retry because unlocking one
            // is what the user has to do anyway, and the invite itself is fine
            state = .loadFailed(isRetrying: false)
            return
        }

        availableUserWalletModels = available
        selectedUserWalletModel = userWalletModel
        walletName = userWalletModel.name

        state = .loaded(
            Content(
                preview: preview,
                accountIconViewData: Self.makeAccountIconViewData(config: preview.config),
                title: Self.makeTitle(accountName: preview.config.name),
                subtitle: Self.makeSubtitle(config: preview.config),
                creatorName: preview.creator.name,
                isWalletSelectionAvailable: available.count > 1
            )
        )

        loadWalletImage()
    }

    func handle(loadingError: Error) {
        state = Self.isInviteRejected(loadingError) ? .invalidInvite : .loadFailed(isRetrying: false)
    }

    /// The endpoint turns the wallet away with these two when the invite is spent, revoked or never existed —
    /// retrying would only ask the same question again.
    static func isInviteRejected(_ error: Error) -> Bool {
        guard let apiError = error as? TangemAPIError else {
            return false
        }

        switch apiError.code {
        case .notFound, .conflict:
            return true
        default:
            return false
        }
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
        guard let userWalletModel = selectedUserWalletModel else {
            return
        }

        Task { [weak self] in
            let image = await userWalletModel.walletImageProvider.loadSmallImage()

            // A wallet picked while this one was still loading keeps its own icon
            guard let self, selectedUserWalletModel?.userWalletId == userWalletModel.userWalletId else {
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

// MARK: - State

extension JointAccountJoinViewModel {
    enum State {
        case loading
        case loaded(Content)
        /// The link itself is no good — the only way out is to leave.
        case invalidInvite
        /// The invite may well be fine, so the user is offered another go at reading it.
        case loadFailed(isRetrying: Bool)
    }

    struct Content {
        let preview: JointAccountInvitePreview
        let accountIconViewData: AccountIconView.ViewData
        let title: AttributedString
        let subtitle: AttributedString
        let creatorName: String
        let isWalletSelectionAvailable: Bool
    }
}
