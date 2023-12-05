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
            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.isScannerBusy)
                    .transition(.notificationTransition)
            }

            ForEach(viewModel.tokensNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            tokensContent

            if viewModel.isOrganizeTokensVisible {
                FixedSizeButtonWithLeadingIcon(
                    title: Localization.organizeTokensTitle,
                    icon: Assets.OrganizeTokens.filterIcon.image,
                    action: viewModel.onOpenOrganizeTokensButtonTap
                )
                .infinityFrame(axis: .horizontal)
            }
        }
        .animation(.default, value: viewModel.notificationInputs)
        .animation(.default, value: viewModel.tokensNotificationInputs)
        .padding(.horizontal, 16)
        .bindAlert($viewModel.error)
    }

    @ViewBuilder
    private var tokensContent: some View {
        if viewModel.isLoadingTokenList {
            TokenListLoadingPlaceholderView()
                .cornerRadiusContinuous(Constants.cornerRadius)
        } else if viewModel.sections.isEmpty {
            emptyList
                .cornerRadiusContinuous(Constants.cornerRadius)
        } else {
            // Don't apply `.cornerRadiusContinuous` modifier to this view on iOS 17.0 and above,
            // this will cause clipping of iOS context menu previews in `TokenItemView` view
            if #available(iOS 17.0, *) {
                tokensList
            } else {
                tokensList
                    .cornerRadiusContinuous(Constants.cornerRadius)
            }
        }
    }

    private var emptyList: some View {
        VStack(spacing: 16) {
            Assets.emptyTokenList.image
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.mainEmptyTokensListMessage)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Regular.caption1,
                    color: Colors.Text.tertiary
                )
        }
        .padding(.top, 96)
        .padding(.horizontal, 48)
    }

    private var tokensList: some View {
        LazyVStack(spacing: 0) {
            ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, section in
                if #available(iOS 17.0, *) {
                    let isFirstVisibleSection = (section.model.title != nil && sectionIndex == 0)
                    let topEdgeCornerRadius = isFirstVisibleSection ? Constants.cornerRadius : nil

                    TokenSectionView(title: section.model.title, cornerRadius: topEdgeCornerRadius)
                } else {
                    TokenSectionView(title: section.model.title)
                }

                ForEach(indexed: section.items.indexed()) { itemIndex, item in
                    if #available(iOS 17.0, *) {
                        let isFirstItem = (section.model.title == nil && sectionIndex == 0 && itemIndex == 0)
                        let isLastItem = (sectionIndex == viewModel.sections.count - 1 && itemIndex == section.items.count - 1)
                        let cornerRadius = Constants.cornerRadius

                        if isFirstItem {
                            TokenItemView(viewModel: item, cornerRadius: cornerRadius, roundedCornersVerticalEdge: .topEdge)
                        } else if isLastItem {
                            TokenItemView(viewModel: item, cornerRadius: cornerRadius, roundedCornersVerticalEdge: .bottomEdge)
                        } else {
                            TokenItemView(viewModel: item, cornerRadius: cornerRadius, roundedCornersVerticalEdge: nil)
                        }
                    } else {
                        TokenItemView(viewModel: item, cornerRadius: Constants.cornerRadius)
                    }
                }
            }
        }
        .background(Colors.Background.primary.cornerRadiusContinuous(Constants.cornerRadius))
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static let viewModel: MultiWalletMainContentViewModel = {
        let repo = FakeUserWalletRepository()
        let mainCoordinator = MainCoordinator()
        let userWalletModel = repo.models.first!

        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        InjectedValues[\.tangemApiService] = FakeTangemApiService()

        let optionsManager = FakeOrganizeTokensOptionsManager(
            initialGroupingOption: .none,
            initialSortingOption: .dragAndDrop
        )
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
            tokenRouter: SingleTokenRoutableMock()
        )
    }()

    static var previews: some View {
        ScrollView {
            MultiWalletMainContentView(viewModel: viewModel)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Constants

private extension MultiWalletMainContentView {
    enum Constants {
        static let cornerRadius: CGFloat = 14.0
    }
}
