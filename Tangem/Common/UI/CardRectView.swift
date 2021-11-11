//
//  CardRectVoiew.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardRectView: View {
    var withShadow = true
    var body: some View {
        ZStack {
            if withShadow {
                Rectangle()
                    .fill(Color.tangemBlue.opacity(0.1))
                   // .aspectRatio(1.86, contentMode: .fit)
                    .cornerRadius(22.0)
                    .offset(x: -12.0, y: 8.0)
                    .frame(width: 456, height: 244, alignment: .center)
            }
            Rectangle()
                .fill(Color.tangemBlue)
               // .aspectRatio(1.86, contentMode: .fit)
                .cornerRadius(22.0)
                .frame(width: 456, height: 244, alignment: .center)
            VStack(alignment: .trailing, spacing: 16.0) {
            Image("tangemLogo")
                .accentColor(Color.white)
            Text("**** **** **** ****")
                .font(Font.custom("Arial", size: 26.24))
                .fontWeight(.bold)
                .foregroundColor(Color(Color.RGBColorSpace.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7))
                .lineLimit(1)
            }
            .offset(x: 30.0, y: 50.0)
        }
    }
}

struct CardRectView_Previews: PreviewProvider {
    static var previews: some View {
        return CardRectView()
    }
}
