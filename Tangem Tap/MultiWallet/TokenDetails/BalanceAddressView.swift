//
//  BalanceAddressView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import EFQRCode
import BlockchainSdk

struct BalanceAddressView: View {
    @ObservedObject var walletModel: WalletModel
    var amountType: Amount.AmountType
    
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
            return .tangemTapGreen
        }
        return .tangemTapWarning
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
                            .foregroundColor(Color.tangemTapGrayDark6)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.middle)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(fiatBalance)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .lineLimit(1)
                            .foregroundColor(Color.tangemTapGrayDark)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                        Image(image)
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
                
                walletModel.getTokenItem(for: amountType).imageView
            }
            
            if showAddressSelector {
                PickerView(contents: walletModel.addressNames, selection: $selectedAddressIndex)
                    .padding(.vertical, 16)
            }
            
            HStack(alignment: .center) {
                Image(uiImage: self.getQrCodeImage(width: 300.0, height: 300.0))
                    .resizable()
                    .frame(width: 114, height: 114)
                    .aspectRatio(contentMode: .fit)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(walletModel.displayAddress(for: selectedAddressIndex))
                        .font(Font.system(size: 13.0, weight: .medium, design: .default))
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .foregroundColor(Color.tangemTapGrayDark)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: {
                        if let url = walletModel.exploreURL(for: selectedAddressIndex) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }}) {
                        HStack {
                            Text("wallet_address_button_explore")
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                            Image ("chevron.right")
                        }
                        .font(Font.system(size: 14.0, weight: .bold, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                    }
                    .padding(.bottom, 16)
                    
                    HStack {
                        RoundedRectButton(action: {
                                            UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex) },
                                          imageName: "doc.on.clipboard",
                                          title: "common_copy".localized,
                                          withVerification: true)
                        
                        RoundedRectButton(action: { showShareSheet() },
                                          imageName: "square.and.arrow.up",
                                          title: "common_share".localized)
                    }
                }
                Spacer()
            }
            
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
    
    private func getQrCodeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let padding: CGFloat = 0
        
        if let cgImage = EFQRCode.generate(content: walletModel.shareAddressString(for: selectedAddressIndex),
                                           size: EFIntSize(width: Int(width), height: Int(height)), backgroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0)) {
            return UIImage(cgImage: cgImage.cropping(to: CGRect(x: padding,
                                                                y: padding,
                                                                width: width - padding,
                                                                height: height-padding))!,
                           scale: 1.0,
                           orientation: .up)
        } else {
            return UIImage.imageWithSize(width: width, height: height, filledWithColor: UIColor.tangemTapBgGray )
        }
    }
}

struct BalanceAddressView_Previews: PreviewProvider {
    @State static var cardViewModel = CardViewModel.previewCardViewModel
    
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
            BalanceAddressView(
                walletModel: walletModel, amountType: .coin)
                .padding()
        }
    }
}
