//
//  MultiWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletMainContentView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    private let notificationTransition: AnyTransition = .scale.combined(with: .opacity)

    var body: some View {
        VStack(spacing: 14) {
            if let settings = viewModel.missingDerivationNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        title: Localization.commonGenerateAddresses,
                        icon: .trailing(Assets.tangemIcon),
                        size: .notification,
                        isLoading: viewModel.isScannerBusy,
                        action: viewModel.deriveEntriesWithoutDerivation
                    ),
                ])
                .transition(notificationTransition)
            }

            if let settings = viewModel.missingBackupNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        title: Localization.buttonStartBackupProcess,
                        style: .secondary,
                        size: .notification,
                        action: viewModel.startBackupProcess
                    ),
                ])
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(notificationTransition)
            }

            tokensContent

            if viewModel.isOrganizeTokensVisible {
                FixedSizeButtonWithLeadingIcon(
                    title: Localization.organizeTokensTitle,
                    icon: Assets.OrganizeTokens.filterIcon.image,
                    action: viewModel.openOrganizeTokens
                )
                .infinityFrame(axis: .horizontal)
            }
        }
        .animation(.default, value: viewModel.missingDerivationNotificationSettings)
        .animation(.default, value: viewModel.notificationInputs)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .background(
            Color.clear
                .alert(item: $viewModel.error, content: { $0.alert })
        )
    }

    private var tokensContent: some View {
        Group {
            if viewModel.isLoadingTokenList {
                TokenListLoadingPlaceholderView()
            } else {
                if viewModel.sections.isEmpty {
                    emptyList
                } else {
                    tokensList
                }
            }
        }
        .cornerRadiusContinuous(14)
    }

    private var emptyList: some View {
        // [REDACTED_TODO_COMMENT]
        Text("To begin tracking your crypto assets and transactions, add tokens.")
            .multilineTextAlignment(.center)
            .style(
                Fonts.Regular.caption1,
                color: Colors.Text.tertiary
            )
            .padding(.top, 150)
            .padding(.horizontal, 48)
    }

    private var tokensList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.sections) { section in
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let title = section.title {
                        Text(title)
                            .style(
                                Fonts.Bold.footnote,
                                color: Colors.Text.tertiary
                            )
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                    }

                    ForEach(section.tokenItemModels) { item in
                        TokenItemView(viewModel: item)
                    }
                }
            }
        }
        .background(Colors.Background.primary)
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static var sectionProvider: TokenListInfoProvider = EmptyTokenListInfoProvider()
    static let viewModel: MultiWalletMainContentViewModel = {
        let repo = FakeUserWalletRepository()
        let mainCoordinator = MainCoordinator()
        let userWalletModel = repo.models.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        InjectedValues[\.tangemApiService] = FakeTangemApiService()
        sectionProvider = GroupedTokenListInfoProvider(
            userTokenListManager: userWalletModel.userTokenListManager,
            walletModelsManager: userWalletModel.walletModelsManager
        )
        return MultiWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            coordinator: mainCoordinator,
            sectionsProvider: sectionProvider,
            canManageTokens: userWalletModel.isMultiWallet
        )
    }()

    static var previews: some View {
        ScrollView {
            MultiWalletMainContentView(viewModel: viewModel)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
