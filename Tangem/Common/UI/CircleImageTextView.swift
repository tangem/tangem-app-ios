//
//  CircleImageTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CircleImageTextView: View {
    var name: String
    var color: Color
    var size = CGSize(bothDimensions: 40.0)

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(color)
            Text(String(name.first ?? " "))
                .font(Font.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(Color.white)
        }
        .frame(size: size)
        .clipped()
    }
}

struct TokenImage_Previews: PreviewProvider {
    static var previews: some View {
        CircleImageTextView(name: "Aave (OLD)", color: .gray)
    }
}
