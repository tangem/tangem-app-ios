//
//  BalanceAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct BalanceAddressViewModel {
    let state: WalletModel.State
    let wallet: Wallet
    let tokenItem: TokenItem
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let isTestnet: Bool
    let isDemo: Bool

    var blockchainText: String {
        if state.isNoAccount {
            return Localization.walletErrorNoAccount
        }

        if state.isBlockchainUnreachable {
            return Localization.warningNetworkUnreachableTitle
        }

        if hasTransactionInProgress {
            return Localization.walletBalanceTxInProgress
        }

        if state.isLoading {
            return Localization.walletBalanceLoading
        }

        return Localization.walletBalanceVerified
    }

    var image: String {
        state.errorDescription == nil
            && !hasTransactionInProgress
            && !state.isLoading ? "checkmark.circle" : "exclamationmark.circle"
    }

    var showAddressSelector: Bool {
        return wallet.addresses.count > 1
    }

    var qrReceiveMessage: String {
        // [REDACTED_TODO_COMMENT]
        let symbol = wallet.amounts[tokenItem.amountType]?.currencySymbol ?? wallet.blockchain.currencySymbol

        let currencyName: String
        if case .token(let token) = tokenItem.amountType {
            currencyName = token.name
        } else {
            currencyName = wallet.blockchain.displayName
        }

        return Localization.addressQrCodeMessageFormat(currencyName, symbol, wallet.blockchain.displayName)
    }

    var accentColor: Color {
        if state.errorDescription == nil,
           !hasTransactionInProgress,
           !state.isLoading {
            return .tangemGreen
        }
        return .tangemWarning
    }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }

    func exploreURL(for index: Int) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: wallet.addresses[index].value, token: tokenItem.token)
    }
}

struct BalanceAddressView: View {
    let viewModel: BalanceAddressViewModel
    var isRefreshing: Bool
    let showExplorerURL: (URL?) -> Void
    @State private var selectedAddressIndex: Int = 0

    var isSkeletonShown: Bool {
        viewModel.state.isLoading && !isRefreshing
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    if let errorDescription = viewModel.state.errorDescription {
                        Text(errorDescription)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(viewModel.accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(viewModel.fiatBalance)
                            .font(Font.system(size: 20.0, weight: .bold, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.middle)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .skeletonable(isShown: isSkeletonShown, size: CGSize(width: 70, height: 20), radius: 6)
                        Text(viewModel.balance)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemGrayDark)
                            .skeletonable(isShown: isSkeletonShown, size: CGSize(width: 100, height: 14), radius: 6)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                        Image(systemName: viewModel.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(viewModel.accentColor)
                            .frame(width: 10.0, height: 10.0)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        VStack(alignment: .leading) {
                            Text(viewModel.blockchainText)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(viewModel.accentColor)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                TokenIconView(viewModel: .init(tokenItem: viewModel.tokenItem))
                    .saturation(viewModel.isTestnet ? 0 : 1)
            }

            if viewModel.showAddressSelector {
                PickerView(contents: viewModel.addressNames, selection: $selectedAddressIndex)
                    .padding(.vertical, 16)
            }

            GeometryReader { geometry in
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        Image(uiImage: QrCodeGenerator.generateQRCode(from: viewModel.shareAddressString(for: selectedAddressIndex)))
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(width: geometry.size.width * 0.3)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.displayAddress(for: selectedAddressIndex))
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .lineLimit(3)
                                .truncationMode(.middle)
                                .foregroundColor(Color.tangemGrayDark)
                                .fixedSize(horizontal: false, vertical: true)

                            ExploreButton(
                                url: viewModel.exploreURL(for: selectedAddressIndex),
                                showExplorerURL: showExplorerURL
                            )

                            HStack {
                                RoundedRectButton(
                                    action: { copyAddress() },
                                    systemImageName: "doc.on.clipboard",
                                    title: Localization.commonCopy,
                                    withVerification: true
                                )
                                .accessibility(label: Text(Localization.commonCopyAddress))

                                RoundedRectButton(
                                    action: { showShareSheet() },
                                    systemImageName: "square.and.arrow.up",
                                    title: Localization.commonShare
                                )
                                .accessibility(label: Text(Localization.voiceOverShareAddress))
                            }
                        }
                        .frame(width: geometry.size.width * 0.7)
                    }
                }
            }
            .frame(height: 86)
            .padding(.bottom, 16)

            Text(viewModel.qrReceiveMessage)
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(6)
    }

    func showShareSheet() {
        Analytics.log(.buttonShareAddress)
        let address = viewModel.displayAddress(for: selectedAddressIndex)
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }

    private func copyAddress() {
        Analytics.log(.buttonCopyAddress)
        UIPasteboard.general.string = viewModel.displayAddress(for: selectedAddressIndex)
    }
}

struct BalanceAddressView_Previews: PreviewProvider {
    static var walletModel: WalletModel {
        let vm = PreviewCard.stellar.cardModel.walletModelsManager.walletModels.first!
        return vm
    }

    static var viewModel: BalanceAddressViewModel {
        .init(
            state: walletModel.state,
            wallet: walletModel.wallet,
            tokenItem: walletModel.tokenItem,
            hasTransactionInProgress: walletModel.hasPendingTransactions,
            name: walletModel.name,
            fiatBalance: walletModel.fiatBalance,
            balance: walletModel.balance,
            isTestnet: walletModel.isTestnet,
            isDemo: walletModel.isDemo
        )
    }

    static var previews: some View {
        ZStack {
            Color.gray
            ScrollView {
                BalanceAddressView(
                    viewModel: viewModel, isRefreshing: false, showExplorerURL: { _ in }
                )
                .padding()
            }
        }
        .previewGroup(devices: [.iPhone7])
    }
}
