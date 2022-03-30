//
//  BalanceAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct BalanceAddressView: View {
    @ObservedObject var walletModel: WalletModel
    var amountType: Amount.AmountType
    @Binding var showExplorerURL: URL?
    @State private var selectedAddressIndex: Int = 0
    
    var blockchainText: String {
        if walletModel.state.isNoAccount {
            return "wallet_error_no_account".localized
        }
        
        if walletModel.state.isBlockchainUnreachable {
            return "wallet_balance_blockchain_unreachable".localized
        }
        
        if walletModel.wallet.hasPendingTx(for: amountType) {
            return "wallet_balance_tx_in_progress".localized
        }
        
        if walletModel.state.isLoading {
            return "wallet_balance_loading".localized
        }
        
        return "wallet_balance_verified".localized
    }
    
    var image: String {
        walletModel.state.errorDescription == nil
        && !walletModel.wallet.hasPendingTx(for: amountType)
        && !walletModel.state.isLoading ? "checkmark.circle" : "exclamationmark.circle"
    }
    
    var showAddressSelector: Bool {
        return walletModel.wallet.addresses.count > 1
    }
    
    var accentColor: Color {
        if walletModel.state.errorDescription == nil
            && !walletModel.wallet.hasPendingTx(for: amountType)
            && !walletModel.state.isLoading {
            return .tangemGreen
        }
        return .tangemWarning
    }
    
    var balance: String {
        walletModel.getBalance(for: amountType)
    }
    
    var fiatBalance: String {
        walletModel.getFiatBalance(for: amountType)
    }
    
    var body: some View {
        VStack {
            HStack (alignment: .top) {
                VStack (alignment: .leading, spacing: 8) {
                    if let errorDescription = walletModel.state.errorDescription {
                        Text(errorDescription)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(balance)
                            .font(Font.system(size: 20.0, weight: .bold, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.middle)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(fiatBalance)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemGrayDark)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                        Image(systemName: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(accentColor)
                            .frame(width: 10.0, height: 10.0)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        VStack(alignment: .leading) {
                            Text(blockchainText)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(accentColor)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                TokenIconView(with: amountType, blockchain: walletModel.wallet.blockchain)
                    .saturation(walletModel.isTestnet ? 0 : 1)
                    .frame(width: 40, height: 40, alignment: .center)
            }
            
            if showAddressSelector {
                PickerView(contents: walletModel.addressNames, selection: $selectedAddressIndex)
                    .padding(.vertical, 16)
            }
                
            
            GeometryReader { geometry in
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        Image(uiImage: QrCodeGenerator.generateQRCode(from: walletModel.shareAddressString(for: selectedAddressIndex)))
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(width: geometry.size.width * 0.3)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(walletModel.displayAddress(for: selectedAddressIndex))
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .lineLimit(3)
                                .truncationMode(.middle)
                                .foregroundColor(Color.tangemGrayDark)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            ExploreButton(url: walletModel.exploreURL(for: selectedAddressIndex),
                                          urlBinding: $showExplorerURL)
                            
                            HStack {
                                RoundedRectButton(action: { UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex) },
                                                  systemImageName: "doc.on.clipboard",
                                                  title: "common_copy".localized,
                                                  withVerification: true)
                                    .accessibility(label: Text("voice_over_copy_address"))
                                
                                RoundedRectButton(action: { showShareSheet() },
                                                  systemImageName: "square.and.arrow.up",
                                                  title: "common_share".localized)
                                    .accessibility(label: Text("voice_over_share_address"))
                            }
    
                        }
                        .frame(width: geometry.size.width * 0.7)
                    }
                    
                }
            }
            .frame(height: 86)
            .padding(.bottom, 16)
            
            Text(walletModel.getQRReceiveMessage(for: amountType))
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark)
            
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(6)
    }
    
    func showShareSheet() {
        let address = walletModel.displayAddress(for: selectedAddressIndex)
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
}

struct BalanceAddressView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly(for: .stellar)
    
    @State static var cardViewModel = assembly.previewCardViewModel
    
    static var walletModel: WalletModel {
        let vm = cardViewModel.walletModels!.first!
        vm.state = .failed(error: "Failed to load. Internet connection is unnreachable")
        vm.state = .idle
        vm.balanceViewModel = BalanceViewModel(isToken: false,
                                               hasTransactionInProgress: true,
                                               state: .idle,
                                               name: "Ethereum smart contract token",
                                               fiatBalance: "$3.45",
                                               balance: "0.67538451 BTC",
                                               secondaryBalance: "",
                                               secondaryFiatBalance: "",
                                               secondaryName: "")
        return vm
    }
    
    static var previews: some View {
        ZStack {
            Color.gray
            ScrollView {
                BalanceAddressView(
                    walletModel: walletModel, amountType: .coin, showExplorerURL: .constant(nil))
                    .padding()
            }
        }
        .previewGroup(devices: [.iPhone7])
    }
}
