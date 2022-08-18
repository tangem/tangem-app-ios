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
    @Binding var showQr: Bool
    @Binding var selectedAddressIndex: Int
    @Binding var showExplorerURL: URL?
    var walletModel: WalletModel

    let copyAddress: () -> Void

    var showAddressSelector: Bool {
        return walletModel.wallet.addresses.count > 1
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

                    ExploreButton(url: walletModel.exploreURL(for: selectedAddressIndex),
                                  urlBinding: $showExplorerURL)

                }

                Spacer()

                CircleActionButton(action: copyAddress,
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
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct AddressDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            AddressDetailView(showQr: .constant(false),
                              selectedAddressIndex: .constant(0),
                              showExplorerURL: .constant(nil),
                              walletModel: PreviewCard.v4.cardModel.walletModels!.first!,
                              copyAddress: {})
        }
    }
}
