//
//  CardRectVoiew.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardRectView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.tangemTapBlue.opacity(0.1))
                .frame(width: nil, height: 244.0, alignment: .center)
                .cornerRadius(22.0)
                .offset(x: -12.0, y: 8.0)
            Rectangle()
                .fill(Color.tangemTapBlue)
                .frame(width: nil, height: 244.0, alignment: .center)
                .cornerRadius(22.0)
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
        }.offset(x: -UIScreen.main.bounds.width/5.0)
    }
}

struct CardRectView_Previews: PreviewProvider {
    static var previews: some View {
        return CardRectView()
    }
}
