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

    var body: some View {
        VStack(spacing: 14) {
            if let settings = viewModel.missingDerivationNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        action: viewModel.didTapNotificationButton(with:action:),
                        actionType: .generateAddresses
                    ),
                ])
                .setButtonsLoadingState(to: viewModel.isScannerBusy)
                .transition(.scaleOpacity)
            }

            if let settings = viewModel.missingBackupNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        action: viewModel.didTapNotificationButton(with:action:),
                        actionType: .backupCard
                    ),
                ])
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.scaleOpacity)
            }

            ForEach(viewModel.tokensNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.scaleOpacity)
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
        .animation(.default, value: viewModel.tokensNotificationInputs)
        .padding(.horizontal, 16)
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
                TokenSectionView(title: section.model.title)

                ForEach(section.items) { item in
                    TokenItemView(viewModel: item)
                }
            }
        }
        .background(Colors.Background.primary)
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static let viewModel: MultiWalletMainContentViewModel = {
        let repo = FakeUserWalletRepository()
        let mainCoordinator = MainCoordinator()
        let userWalletModel = repo.models.first!

        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        InjectedValues[\.tangemApiService] = FakeTangemApiService()

        let optionsManager = OrganizeTokensOptionsManagerStub()
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return MultiWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            tokensNotificationManager: FakeUserWalletNotificationManager(),
            coordinator: mainCoordinator,
            tokenSectionsAdapter: tokenSectionsAdapter,
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
