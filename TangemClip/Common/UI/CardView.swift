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
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(image: UIImage(named: "twin"), width: UIScreen.main.bounds.width)
    }
}
