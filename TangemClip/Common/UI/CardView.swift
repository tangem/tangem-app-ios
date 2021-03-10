//
//  CardView.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardView: View {
    
    var image: UIImage?
    var width: CGFloat
    
    var currentCardNumber: Int?
    var cid: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: width, maxWidth: width, minHeight: 190, alignment: .center)
                    .padding(.vertical, 16.0)
            } else {
                Color.tangemTapGrayLight4
                    .opacity(0.5)
                    .frame(width: width, height: 180, alignment: .center)
                    .cornerRadius(6)
                    .padding(.vertical, 16.0)
            }
            Text(cid)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .background(Color.black)
                .cornerRadius(14)
                .offset(x: 24)
//            if let currentCardNumber = currentCardNumber {
//                Text(String(format: "wallet_twins_chip_format".localized, currentCardNumber))
//                    .font(.system(size: 14, weight: .bold))
//                    .foregroundColor(.white)
//                    .padding(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
//                    .background(Color.black)
//                    .cornerRadius(14)
//                    .offset(x: 24)     
//            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(image: UIImage(named: "twin"), width: UIScreen.main.bounds.width, currentCardNumber: 2, cid: "CB47000000007584")
    }
}
