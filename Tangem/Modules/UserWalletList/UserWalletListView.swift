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
                Text("user_wallet_list_title".localized)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        section("user_wallet_list_multi_header".localized, for: viewModel.multiCurrencyModels)
                        section("user_wallet_list_single_header".localized, for: viewModel.singleCurrencyModels)
                    }
                }
                .background(Colors.Background.primary)
                .cornerRadius(14)

                if !viewModel.isUnlocked {
                    TangemButton(title: viewModel.unlockAllButtonLocalizationKey, action: viewModel.unlockAllWallets)
                        .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
                }

                TangemButton(title: "user_wallet_list_add_button", image: "tangemIconBlack", iconPosition: .trailing, action: viewModel.addUserWallet)
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
        .background(Self.sheetBackground.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private func section(_ header: String, for viewModels: [UserWalletListCellViewModel]) -> some View {
        if !viewModels.isEmpty {
            UserWalletListHeaderView(name: header)

            ForEach(viewModels, id: \.userWalletId) { viewModel in
                cell(for: viewModel)

                if viewModel.userWalletId != viewModels.last?.userWalletId {
                    Separator(height: 0.5, padding: 0, color: Colors.Stroke.primary)
                        .padding(.leading, 78)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for viewModel: UserWalletListCellViewModel) -> some View {
        UserWalletListCellView(viewModel: viewModel)
            .contextMenu {
                Button {
                    self.viewModel.editUserWallet(viewModel)
                } label: {
                    HStack {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }
                }

                if #available(iOS 15.0, *) {
                    Button(role: .destructive) {
                        self.viewModel.deleteUserWallet(viewModel)
                    } label: {
                        deleteButtonLabel()
                    }
                } else {
                    Button {
                        self.viewModel.deleteUserWallet(viewModel)
                    } label: {
                        deleteButtonLabel()
                    }
                }
            }
    }

    @ViewBuilder
    private func deleteButtonLabel() -> some View {
        HStack {
            Text("common_delete")
            Image(systemName: "trash")
        }
    }
}
