//
//  MultiWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemNFT
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MultiWalletMainContentView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            if let actionButtonsViewModel = viewModel.actionButtonsViewModel {
                ActionButtonsView(viewModel: actionButtonsViewModel)
            }

            ForEach(viewModel.bannerNotificationInputs) { input in
                NotificationView(input: input)
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.isScannerBusy)
            }

            ForEach(viewModel.tokensNotificationInputs) { input in
                NotificationView(input: input)
            }

            ForEach(viewModel.yieldModuleNotificationInputs) { input in
                NotificationView(input: input)
            }

            ForEach(viewModel.tangemPayNotificationInputs) { input in
                switch input.id {
                case TangemPayNotificationEvent.syncNeeded.id:
                    NotificationView(input: input)
                        .setButtonsLoadingState(to: viewModel.tangemPaySyncInProgress)

                default:
                    NotificationView(input: input)
                }
            }

            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
            if let viewModel = viewModel.tangemPayAccountViewModel {
                TangemPayAccountView(viewModel: viewModel)
            }

            listContent

            if let nftEntrypointViewModel = viewModel.nftEntrypointViewModel {
                NFTEntrypointView(viewModel: nftEntrypointViewModel)
            }

            if viewModel.isOrganizeTokensVisible {
                FixedSizeButtonWithLeadingIcon(
                    title: Localization.organizeTokensTitle,
                    icon: Assets.OrganizeTokens.filterIcon.image,
                    style: .default,
                    action: viewModel.onOpenOrganizeTokensButtonTap
                )
                .infinityFrame(axis: .horizontal)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.organizeTokensButton)
            }
        }
        .padding(.horizontal, 16)
        .onFirstAppear(perform: viewModel.onFirstAppear)
        .bindAlert($viewModel.error)
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoadingTokenList {
            TokenListLoadingPlaceholderView()
                .cornerRadiusContinuous(Constants.cornerRadius)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokensList)
        } else if viewModel.plainSections.isEmpty, viewModel.accountSections.isEmpty {
            emptyList
                .cornerRadiusContinuous(Constants.cornerRadius)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokensList)
        } else {
            VStack(spacing: 0.0) {
                accountsList

                makeTokensList(sections: viewModel.plainSections)
                    .modifyView { view in
                        // Don't apply `.cornerRadiusContinuous` modifier to this view on iOS 16.0 and above,
                        // this will cause clipping of iOS context menu previews in `TokenItemView` view
                        if #available(iOS 16.0, *) {
                            view
                        } else {
                            view.cornerRadiusContinuous(Constants.cornerRadius)
                        }
                    }
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.tokensList)
            }
        }
    }

    private var accountsList: some View {
        LazyVStack(spacing: 8.0) {
            ForEach(viewModel.accountSections) { accountSection in
                ExpandableAccountItemView(viewModel: accountSection.model) {
                    makeTokensList(sections: accountSection.items)
                }
            }
        }
    }

    private var emptyList: some View {
        MultiWalletTokenItemsEmptyView()
            .padding(.top, 96)
    }

    @available(iOS 16, *)
    private func tokenItemView(
        item: TokenItemViewModel,
        cornerRadius: CGFloat,
        roundedCornersVerticalEdge: TokenItemView.RoundedCornersVerticalEdge?,
        isFirstItem: Bool = false,
        promoBubbleViewModel: TokenItemPromoBubbleViewModel?
    ) -> some View {
        VStack(spacing: .zero) {
            if let promoBubbleViewModel {
                TokenItemPromoBubbleView(viewModel: promoBubbleViewModel, position: isFirstItem ? .top : .normal)
            }

            TokenItemView(
                viewModel: item,
                cornerRadius: cornerRadius,
                roundedCornersVerticalEdge: roundedCornersVerticalEdge
            )
            .overlay(alignment: .top) {
                trianglePointer.opacity(promoBubbleViewModel == nil ? 0 : 1)
            }
        }
    }

    private var trianglePointer: some View {
        Triangle()
            .rotation(Angle(degrees: 180))
            .fill(Colors.Control.unchecked)
            .frame(width: 12, height: 8)
    }

    private func makeTokensList(sections: [MultiWalletMainContentPlainSection]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(indexed: sections.indexed()) { sectionIndex, section in
                let cornerRadius = Constants.cornerRadius
                let hasTitle = section.model.title != nil

                if #available(iOS 16.0, *) {
                    let isFirstVisibleSection = hasTitle && sectionIndex == 0
                    let topEdgeCornerRadius = isFirstVisibleSection ? cornerRadius : nil

                    TokenSectionView(title: section.model.title, cornerRadius: topEdgeCornerRadius)
                } else {
                    TokenSectionView(title: section.model.title)
                }

                ForEach(indexed: section.items.indexed()) { itemIndex, item in
                    if #available(iOS 16.0, *) {
                        let isFirstItem = !hasTitle && sectionIndex == 0 && itemIndex == 0
                        let isLastItem = sectionIndex == sections.count - 1 && itemIndex == section.items.count - 1

                        let hasPromoBubble = viewModel.tokenItemPromoBubbleViewModel?.id == item.id
                        let promoBubbleViewModel = hasPromoBubble ? viewModel.tokenItemPromoBubbleViewModel : nil

                        let roundedEdges: TokenItemView.RoundedCornersVerticalEdge? = {
                            if isFirstItem {
                                return hasPromoBubble ? nil : (section.items.count == 1 ? .all : .topEdge)
                            }

                            if isLastItem {
                                return .bottomEdge
                            }

                            return nil
                        }()

                        tokenItemView(
                            item: item,
                            cornerRadius: cornerRadius,
                            roundedCornersVerticalEdge: roundedEdges,
                            isFirstItem: isFirstItem,
                            promoBubbleViewModel: promoBubbleViewModel
                        )
                    } else {
                        TokenItemView(viewModel: item, cornerRadius: cornerRadius)
                    }
                }
            }
        }
    }
}

// [REDACTED_TODO_COMMENT]
/*
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
         // accounts_fixes_needed_main
         let tokenSectionsAdapter = TokenSectionsAdapter(
             userTokensManager: userWalletModel.userTokensManager,
             optionsProviding: optionsManager,
             preservesLastSortedOrderOnSwitchToDragAndDrop: false
         )
         let nftFeatureLifecycleHandler = NFTFeatureLifecycleHandler()

         return MultiWalletMainContentViewModel(
             userWalletModel: userWalletModel,
             userWalletNotificationManager: FakeUserWalletNotificationManager(),
             tokensNotificationManager: FakeUserWalletNotificationManager(),
             bannerNotificationManager: nil,
             rateAppController: RateAppControllerStub(),
             tokenSectionsAdapter: tokenSectionsAdapter,
             tokenRouter: SingleTokenRoutableMock(),
             optionsEditing: optionsManager,
             nftFeatureLifecycleHandler: nftFeatureLifecycleHandler,
             coordinator: mainCoordinator
         )
     }()

     static var previews: some View {
         ScrollView {
             MultiWalletMainContentView(viewModel: viewModel)
         }
         .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
     }
 }
 */

// MARK: - Constants

private extension MultiWalletMainContentView {
    enum Constants {
        static let cornerRadius: CGFloat = 14.0
    }
}
