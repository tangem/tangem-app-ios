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

enum PayIdStatus {
    case notCreated
    case created(payId: String)
    case notSupported
}

struct AddressDetailView: View {
    var address: String
    var payId: PayIdStatus
    var exploreURL: URL
    @Binding var detailsViewModel: DetailsViewModel
    
    var showPayIdBlock: Bool {
        switch payId {
        case .notSupported:
            return false
        default:
            return true
        }
    }
    
    var isPayIdCreated: Bool {
        switch payId {
        case .created:
            return true
        default:
            return false
        }
    }
    
    var payIdText: String {
        if case let .created(text) = payId {
            return text
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(AddressFormatter(address: address).truncated(prefixLimit: 12, suffixLimit: 4, delimiter: "**** ****"))
                        .font(Font.system(size: 11.0))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .foregroundColor(Color.tangemTapDarkGrey)
                    Button(action: {
                        UIApplication.shared.open(self.exploreURL, options: [:], completionHandler: nil)
                    }) {
                        HStack {
                            Text("addressDetails_button_explore")
                                .font(Font.system(size: 11.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapBlack)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                            Image ("chevron.right")
                                .font(Font.system(size: 11.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapBlack)
                        }
                    }
                }
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = self.address
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 46.0, height: 46.0, alignment: .center)
                            .foregroundColor(Color.tangemTapBgGray)
                        Image ("square.on.square")
                            .font(Font.system(size: 18.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapBlack)
                    }
                }
                Button(action: {
                    self.detailsViewModel.showQr = true
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 46.0, height: 46.0, alignment: .center)
                            .foregroundColor(Color.tangemTapBgGray)
                        Image ("qrcode")
                            .font(Font.system(size: 18.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapBlack)
                    }
                }
            }
            .padding(.horizontal, 24.0)
            .padding(.vertical, 16.0)
            
            if showPayIdBlock {
                Color.tangemTapLightGray
                    .frame(width: nil, height: 1.0, alignment: .center)
                    .padding(.horizontal, 24.0)
                    .padding(.top, 8.0)
                HStack {
                    Image ("payId")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 58.0, height: 18.0)
                    Spacer()
                    
                    if !isPayIdCreated {
                        Button(action: {
                            self.detailsViewModel.showCreatePayid = true
                        }) {
                            HStack {
                                Text("addressDetails_button_createPayid")
                                    .font(Font.system(size: 11.0, weight: .bold, design: .default))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .foregroundColor(Color.tangemTapBlack)
                                Image ("chevron.right")
                                    .font(Font.system(size: 11.0, weight: .bold, design: .default))
                                    .foregroundColor(Color.tangemTapBlack)
                                
                            }
                        }
                    } else {
                        Text(payIdText)
                            .font(Font.system(size: 11.0))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                            .foregroundColor(Color.tangemTapDarkGrey)
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
    @State static var model = DetailsViewModel()
    
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            AddressDetailView(
                address: "0x12341234nkb231kj4lj12h3g4khj12v4k123",
                payId: .created(payId: "jana$payid.tangem.com"),
                exploreURL: URL(string: "https://www.apple.com")!,
                detailsViewModel: $model)
        }
    }
}
