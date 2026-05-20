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
                    } else {
                        TangemPayCardDetailsView(viewModel: viewModel.tangemPayCardDetailsViewModel)
                    }
                }
                .transition(.identity)

                if viewModel.cardRenameViewModel == nil {
                    if viewModel.isReissuing {
                        TangemPayReplacingCardBanner()
                    } else {
                        if viewModel.shouldDisplayAddToApplePayGuide {
                            Button(action: viewModel.openAddToApplePayGuide) {
                                TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                            }
                        }

                        TangemPayDailyLimitSectionView(
                            state: viewModel.dailyLimitState,
                            isFrozen: viewModel.freezingState.isFrozen,
                            changeAction: viewModel.openChangeDailyLimit
                        )

                        GroupedSection(viewModel.cardSettingsRows) {
                            DefaultRowView(viewModel: $0)
                        } header: {
                            DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .disabled(viewModel.isLoadingReissueFee)
        .overlay {
            if viewModel.isLoadingReissueFee {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    ActivityIndicatorView(
                        style: .large,
                        color: UIColor(Color.Tangem.Graphic.Neutral.tertiary)
                    )
                }
            }
        }
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
}
