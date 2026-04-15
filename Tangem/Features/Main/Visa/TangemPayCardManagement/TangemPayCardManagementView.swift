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
                    if viewModel.shouldDisplayAddToApplePayGuide {
                        Button(action: viewModel.openAddToApplePayGuide) {
                            TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                        }
                    }

                    GroupedSection(viewModel.cardSettingsRows) {
                        DefaultRowView(viewModel: $0)
                    } header: {
                        DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .keyboardToolbar {
            if let renameVM = viewModel.cardRenameViewModel {
                TangemPayCardRenameToolbarView(renameViewModel: renameVM)
            }
        }
        .toolbar {
            if let renameVM = viewModel.cardRenameViewModel {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: renameVM.close)
            }
        }
        .navigationBarBackButtonHidden(viewModel.cardRenameViewModel != nil)
        .animation(.easeInOut, value: viewModel.cardRenameViewModel != nil)
    }
}
