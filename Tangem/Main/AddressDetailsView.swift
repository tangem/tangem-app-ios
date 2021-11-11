//
//  BalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AddressDetailView: View {
    @Binding var showCreatePayID: Bool
    @Binding var showQr: Bool
    @Binding var selectedAddressIndex: Int
    var walletModel: WalletModel
    var payID: PayIdStatus
    
    var showPayIdBlock: Bool {
        switch payID {
        case .notSupported:
            return false
        default:
            return true
        }
    }
    
    var isPayIdCreated: Bool {
        switch payID {
        case .created:
            return true
        default:
            return false
        }
    }
    
    var showAddressSelector: Bool {
        return walletModel.wallet.addresses.count > 1
    }
    
    var payIdText: String {
        if case let .created(text) = payID {
            return text
        } else {
            return ""
        }
    }
    
    var pickerViews: [Text] {
        var views = [Text]()
        for (index, address) in walletModel.wallet.addresses.enumerated() {
            let textView = Text(address.localizedName).tag(index) as! Text
            views.append(textView)
        }
        
        return views
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            if showAddressSelector {
                PickerView(contents: walletModel.addressNames, selection: $selectedAddressIndex)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(walletModel.displayAddress(for: selectedAddressIndex))
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(Color.tangemGrayDark)
                    Button(action: {
                        if let url = walletModel.exploreURL(for: selectedAddressIndex) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }) {
                        HStack {
                            Text("wallet_address_button_explore")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemGrayDark6)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                            Image (systemName: "chevron.right")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemGrayDark6)
                        }
                    }
                }
                Spacer()
                CircleActionButton(action: {  UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex) },
                                   backgroundColor: .tangemBgGray,
                                   imageName: "square.on.square",
                                   isSystemImage: true,
                                   imageColor: .tangemGrayDark6,
                                   withVerification: true,
                                   isDisabled: false)
                    .accessibility(label: Text("voice_over_copy_address"))
                
                CircleActionButton(action: { self.showQr = true },
                                   backgroundColor: .tangemBgGray,
                                   imageName: "qrcode",
                                   isSystemImage: true,
                                   imageColor: .tangemGrayDark6,
                                   isDisabled: false)
                    .accessibility(label: Text("voice_over_show_address_qr"))
            }
            .padding(.horizontal, 24.0)
            .padding(.vertical, 16.0)
            if showPayIdBlock {
                Color.tangemGrayLight5
                    .frame(width: nil, height: 1.0, alignment: .center)
                    .padding(.horizontal, 24.0)
                    .padding(.top, 8.0)
                HStack {
                    Image ("payId")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96.0, height: 19.0)
                    Spacer(minLength: 8)
                    
                    if !isPayIdCreated {
                        Button(action: {
                            self.showCreatePayID = true
                        }) {
                            HStack {
                                Text("wallet_address_button_create_payid")
                                    .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .foregroundColor(Color.tangemGrayDark6)
                                Image (systemName: "chevron.right")
                                    .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                    .foregroundColor(Color.tangemGrayDark6)
                                
                            }
                        }
                    } else {
                        Text(payIdText)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemGrayDark)
                            .onTapGesture {
                                UIPasteboard.general.string = self.payIdText
                                //[REDACTED_TODO_COMMENT]
                        }
                    }
                }
                .padding(.horizontal, 24.0)
                .padding(.bottom, 16.0)
                .padding(.top, 17.0)
            }
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct AddressDetailView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly(for: .v4)
    @State static var cardViewModel = assembly.previewCardViewModel
    @State static var showPayID = false
    @State static var showQR = false
    @State static var addressIndex = 0
    
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            AddressDetailView(showCreatePayID: $showPayID,
                              showQr: $showQR,
                              selectedAddressIndex: $addressIndex,
                              walletModel: cardViewModel.walletModels!.first!,
                              payID: .notCreated)
        }
        .environmentObject(assembly.services.navigationCoordinator)
    }
}
