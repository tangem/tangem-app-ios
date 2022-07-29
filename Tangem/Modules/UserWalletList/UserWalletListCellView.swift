//
//  UserWalletListCellView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListCellView: View {
    let model: UserWalletListCellViewModel

    var body: some View {
        HStack(spacing: 12) {
            if let image = model.cardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minHeight: 30, maxHeight: 30)
            } else {
                Color.tangemGrayLight4
                    .transition(.opacity)
                    .opacity(0.5)
                    .cornerRadius(3)
                    .frame(width: 50, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.account.name)
                    .font(Font.subheadline.bold)
                    .foregroundColor(Colors.Text.primary1)

                Text(model.subtitle)
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("4 013,12$")
                    .font(Font.subheadline)
                    .foregroundColor(Colors.Text.primary1)

                Text("12 tokens")
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
            }
        }
        .padding(16)
    }
}

struct UserWalletListCellView_Previews: PreviewProvider {
    static var previews: some View {
        UserWalletListCellView(model: .init(account: .wallet, subtitle: "3 Cards", isSelected: true))
    }
}
