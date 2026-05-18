//
//  TangemPayCardManagementView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct TangemPayCardManagementView: View {
    @ObservedObject var viewModel: TangemPayCardManagementViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Group {
                    if let renameVM = viewModel.cardRenameViewModel {
                        TangemPayCardRenameView(viewModel: renameVM)
                            .padding(.horizontal, 16)
                    } else {
                        cardDetailsCarousel
                        if viewModel.hasMultipleCards {
                            pageIndicator
                        }
                    }
                }
                .transition(.identity)

                if viewModel.cardRenameViewModel == nil {
                    if viewModel.isIssuing {
                        issuingBanner
                    } else if viewModel.isReissuing {
                        TangemPayReplacingCardBanner()
                            .padding(.horizontal, 16)
                    } else {
                        activeCardSections
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .safeAreaInset(edge: .bottom, content: {
            if let renameVM = viewModel.cardRenameViewModel {
                TangemPayCardRenameToolbarView(renameViewModel: renameVM)
            }
        })
        .toolbar {
            if let renameVM = viewModel.cardRenameViewModel {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: renameVM.close)
            }
        }
        .navigationBarBackButtonHidden(viewModel.cardRenameViewModel != nil)
        .animation(.easeInOut, value: viewModel.cardRenameViewModel != nil)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var activeCardSections: some View {
        if viewModel.shouldDisplayAddToApplePayGuide {
            Button(action: viewModel.openAddToApplePayGuide) {
                TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
            }
            .padding(.horizontal, 16)
        }

        TangemPayDailyLimitSectionView(
            state: viewModel.dailyLimitState,
            isFrozen: viewModel.freezingState.isFrozen,
            changeAction: viewModel.openChangeDailyLimit
        )
        .padding(.horizontal, 16)

        GroupedSection(viewModel.cardSettingsRows) {
            DefaultRowView(viewModel: $0)
        } header: {
            DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
    }

    private var issuingBanner: some View {
        TangemPayIssuingCardBanner()
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var cardDetailsCarousel: some View {
        if viewModel.hasMultipleCards {
            if #available(iOS 17.0, *) {
                PeekingCarouselView(
                    items: viewModel.cardDetailsItems,
                    selectedID: $viewModel.selectedCardId
                ) { item in
                    cardDetailsContent(for: item)
                }
            } else {
                legacyTabViewCarousel
            }
        } else if let item = viewModel.cardDetailsItems.first {
            cardDetailsContent(for: item)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func cardDetailsContent(for item: TangemPayCardManagementViewModel.CardDetailsItem) -> some View {
        switch item.content {
        case .issued(let detailsViewModel):
            TangemPayCardDetailsView(viewModel: detailsViewModel)
        case .issuing:
            TangemPayIssuingCardDetailsView()
        }
    }

    /// iOS 16 fallback — `PeekingCarouselView` requires iOS 17 scroll APIs.
    private var legacyTabViewCarousel: some View {
        TabView(selection: $viewModel.selectedCardId) {
            ForEach(viewModel.cardDetailsItems) { item in
                cardDetailsContent(for: item)
                    .tag(item.id as String?)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Constants.legacyCarouselHeight)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.cardDetailsItems) { item in
                let isSelected = item.id == viewModel.selectedCardId
                Capsule()
                    .fill(
                        isSelected
                            ? Colors.Text.primary1
                            : Colors.Text.tertiary.opacity(0.4)
                    )
                    .frame(width: isSelected ? 16 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
    }
}

private extension TangemPayCardManagementView {
    enum Constants {
        static let legacyCarouselHeight: CGFloat = 230
    }
}
