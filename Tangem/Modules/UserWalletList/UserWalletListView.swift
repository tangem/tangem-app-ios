//
//  UserWalletListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListView: ResizableSheetView {
    @ObservedObject private var viewModel: UserWalletListViewModel

    static var sheetBackground: Color {
        if #available(iOS 14, *) {
            return Colors.Background.secondary
        } else {
            // iOS 13 can't convert named SwiftUI colors to UIColor
            return Color(hex: "F2F2F7")!
        }
    }

    init(viewModel: UserWalletListViewModel) {
        self.viewModel = viewModel
    }

    func setResizeCallback(_ callback: @escaping ResizeCallback) {
        viewModel.bottomSheetHeightUpdateCallback = callback
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                #warning("l10n")
                Text("My wallets")
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        #warning("l10n")
                        section("Multi-currency", for: viewModel.multiCurrencyModels)

                        #warning("l10n")
                        section("Single-currency", for: viewModel.singleCurrencyModels)
                    }
                }
                .background(Colors.Background.primary)
                .cornerRadius(14)

                #warning("l10n")
                TangemButton(title: "Add new wallet", image: "tangemIconBlack", iconPosition: .trailing) {
                    viewModel.addUserWallet()
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt3, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
            }

            ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                    tryAgainAction: viewModel.tryAgain,
                                    requestSupportAction: viewModel.requestSupport)
        }
        .padding(16)
        .alert(item: $viewModel.error) {
            $0.alert
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private func section(_ header: String, for models: [CardViewModel]) -> some View {
        if !models.isEmpty {
            UserWalletListHeaderView(name: header)

            ForEach(0 ..< models.count, id: \.self) { i in
                cell(for: models[i])

                if i != (models.count - 1) {
                    Separator(height: 0.5, padding: 0, color: Colors.Stroke.primary)
                        .padding(.leading, 78)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for model: CardViewModel) -> some View {
        UserWalletListCellView(model: model, isSelected: viewModel.selectedUserWalletId == model.userWallet.userWalletId) { userWallet in
            viewModel.onUserWalletTapped(userWallet)
        }
        .contextMenu {
            Button {
                viewModel.editUserWallet(model.userWallet)
            } label: {
                HStack {
                    Text("Rename")
                    Image(systemName: "pencil")
                }
            }

            if #available(iOS 15.0, *) {
                Button(role: .destructive) {
                    viewModel.deleteUserWallet(model.userWallet)
                } label: {
                    deleteButtonLabel()
                }
            } else {
                Button {
                    viewModel.deleteUserWallet(model.userWallet)
                } label: {
                    deleteButtonLabel()
                }
            }
        }
    }

    @ViewBuilder
    private func deleteButtonLabel() -> some View {
        HStack {
            Text("Delete")
            Image(systemName: "trash")
        }
    }
}
