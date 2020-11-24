//
//  BalanceView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

enum PayIdStatus: Equatable {
    case notCreated
    case created(payId: String)
    case notSupported
}

struct AddressDetailView: View {
    @State private(set) var showQr: Bool = false
    @Binding var showCreatePayID: Bool
    @EnvironmentObject var cardViewModel: CardViewModel
    
    var showPayIdBlock: Bool {
        switch cardViewModel.payId {
        case .notSupported:
            return false
        default:
            return true
        }
    }
    
    var isPayIdCreated: Bool {
        switch cardViewModel.payId {
        case .created:
            return true
        default:
            return false
        }
    }
    
    var payIdText: String {
        if case let .created(text) = cardViewModel.payId {
            return text
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AddressFormatter(address: cardViewModel.wallet?.address ?? "").truncated(prefixLimit: 12, suffixLimit: 4, delimiter: "**** ****"))
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .lineLimit(1)
                        .foregroundColor(Color.tangemTapGrayDark)
                    Button(action: {
                        if let url = self.cardViewModel.wallet?.exploreUrl {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }) {
                        HStack {
                            Text("wallet_address_button_explore")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                            Image ("chevron.right")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                        }
                    }
                }
                Spacer()
                Button(action: {
                    if let address = self.cardViewModel.wallet?.address {
                        UIPasteboard.general.string = address
                    }
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 46.0, height: 46.0, alignment: .center)
                            .foregroundColor(Color.tangemTapBgGray)
                        Image ("square.on.square")
                            .font(Font.system(size: 17.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                    }
                }
                Button(action: {
                    self.showQr = true
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 46.0, height: 46.0, alignment: .center)
                            .foregroundColor(Color.tangemTapBgGray)
                        Image ("qrcode")
                            .font(Font.system(size: 17.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                    }
                }
                .sheet(isPresented: $showQr) {
                    // VStack {
                    //    Spacer()
                    QRCodeView(title: String(format: "wallet_qr_title_format".localized, self.cardViewModel.wallet!.blockchain.displayName),
                        shareString: self.cardViewModel.wallet!.shareString)
                        .transition(AnyTransition.move(edge: .bottom))
                    //   Spacer()
                    // }
                    // .background(Color(red: 0, green: 0, blue: 0, opacity: 0.74))
                }
            }
            .padding(.horizontal, 24.0)
            .padding(.vertical, 16.0)
            if showPayIdBlock {
                Color.tangemTapGrayLight5
                    .frame(width: nil, height: 1.0, alignment: .center)
                    .padding(.horizontal, 24.0)
                    .padding(.top, 8.0)
                HStack {
                    Image ("payId")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 58.0, height: 18.0)
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
                                    .foregroundColor(Color.tangemTapGrayDark6)
                                Image ("chevron.right")
                                    .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark6)
                                
                            }
                        }
                    } else {
                        Text(payIdText)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemTapGrayDark)
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
    @State static var cardViewModel = CardViewModel(card: Card.testCard)
    @State static var showPayID = false
    
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            AddressDetailView(showCreatePayID: $showPayID)
            .environmentObject(cardViewModel)
        }
    }
}
