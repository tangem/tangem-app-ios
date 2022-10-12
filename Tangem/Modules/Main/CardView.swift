//
//  CardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardView: View {
    var image: UIImage?
    var cardSetLabel: String?

    @State private var size: CGSize = .zero
    private let walletImageAspectRatio = 1.5888252149

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
                    .padding(.vertical, verticalPadding)
            } else {
                Color.tangemGrayLight4
                    .transition(.opacity)
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, minHeight: size.width / walletImageAspectRatio, alignment: .center)
                    .cornerRadius(6)
                    .padding(.vertical, verticalPadding)
            }
            if let cardSetLabel = cardSetLabel {
                Text(cardSetLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                    .background(Color.gray)
                    .cornerRadius(14)
                    .offset(x: 24)

            }
        }
        .readSize { size = $0 }
    }

    private var verticalPadding: CGFloat {
        cardSetLabel == nil ? 6.0 : 16.0
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(image: UIImage(named: "twin"), cardSetLabel: "1 of 3")
    }
}
