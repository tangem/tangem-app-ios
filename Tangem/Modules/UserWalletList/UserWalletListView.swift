//
//  UserWalletListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListView: View {
    @ObservedObject private var viewModel: UserWalletListViewModel

    static var sheetBackground: Color {
        if #available(iOS 14, *) {
            return Colors.Background.secondary
        } else {
            // iOS 13 can't convert named SwiftUI colors to UIColor
            return Color(hex: "F2F2F7")!
        }
    }

    private let listHorizontalPadding: Double = 16

    init(viewModel: UserWalletListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("user_wallet_list_title".localized)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                list()

                Group {
                    if !viewModel.isUnlocked {
                        TangemButton(title: viewModel.unlockAllButtonLocalizationKey, action: viewModel.unlockAllWallets)
                            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
                    }

                    TangemButton(title: "user_wallet_list_add_button", image: "tangemIconBlack", iconPosition: .trailing, action: viewModel.addUserWallet)
                        .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt3, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
                }
                .padding(.horizontal, listHorizontalPadding)
            }

            ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                    tryAgainAction: viewModel.tryAgain,
                                    requestSupportAction: viewModel.requestSupport)
        }
        .padding(.vertical, 16)
        .alert(item: $viewModel.error) {
            $0.alert
        }
        .background(Self.sheetBackground.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
    }
}

extension UserWalletListView {
    // MARK: - List

    @ViewBuilder
    private func list() -> some View {
        if #available(iOS 15, *) {
            List() {
                sections()
            }
            .listStyle(.insetGrouped)
            .background(Colors.Background.primary)
            .cornerRadius(14)
        } else {
            // Using ScrollView because we can't hide default separators in List on prior OS versions.
            // And since we don't use List we can't use onDelete for the swipe action either.
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    sections()
                }
            }
            .background(Colors.Background.primary)
            .cornerRadius(14)
            .padding(.horizontal, listHorizontalPadding)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func sections() -> some View {
        section("user_wallet_list_multi_header".localized, for: viewModel.multiCurrencyModels)
        section("user_wallet_list_single_header".localized, for: viewModel.singleCurrencyModels)
    }

    @ViewBuilder
    private func section(_ headerName: String, for viewModels: [UserWalletListCellViewModel]) -> some View {
        if !viewModels.isEmpty {
            header(name: headerName)

            ForEach(viewModels, id: \.userWalletId) { viewModel in
                cell(for: viewModel)

                if viewModel.userWalletId != viewModels.last?.userWalletId {
                    separator()
                }
            }
        }
    }

    // MARK: - Headers

    @ViewBuilder
    private func header(name: String) -> some View {
        if #available(iOS 15, *) {
            headerInternal(name: name)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        } else {
            headerInternal(name: name)
        }
    }

    @ViewBuilder
    private func headerInternal(name: String) -> some View {
        UserWalletListHeaderView(name: name)
    }

    // MARK: - Cells

    @ViewBuilder
    private func cell(for viewModel: UserWalletListCellViewModel) -> some View {
        if #available(iOS 15, *) {
            cellInternal(for: viewModel)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.blue)
                .swipeActions {
                    Button("common_delete") {
                        self.viewModel.deleteUserWallet(viewModel)
                    }
                    .tint(.red)

                    #warning("l10n")
                    Button("Rename") {
                        self.viewModel.editUserWallet(viewModel)
                    }
                    .tint(Colors.Icon.informative)
                }

        } else {
            cellInternal(for: viewModel)
        }
    }

    @ViewBuilder
    private func cellInternal(for viewModel: UserWalletListCellViewModel) -> some View {
        UserWalletListCellView(viewModel: viewModel)
            .contextMenu {
                Button {
                    self.viewModel.editUserWallet(viewModel)
                } label: {
                    HStack {
                        #warning("l10n")
                        Text("Rename")
                        Image(systemName: "pencil")
                    }
                }

                if #available(iOS 15, *) {
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

    // MARK: - Separators

    @ViewBuilder
    private func separator() -> some View {
        if #available(iOS 15, *) {
            EmptyView()
        } else {
            separatorInternal()
                .padding(.leading, 78)
        }
    }

    @ViewBuilder
    private func separatorInternal() -> some View {
        Separator(height: 0.5, padding: 0, color: Colors.Stroke.primary)
    }
}
