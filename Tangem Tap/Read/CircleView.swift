//
//  CircleView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CircleView: View {
    var body: some View {
        Circle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color(Color.RGBColorSpace.sRGB, red: 0.0, green: 0.133, blue: 0.831, opacity: 0.1),
                                                             Color(Color.RGBColorSpace.sRGB, red: 0.0, green: 0.133, blue: 0.831, opacity: 0.05)]), startPoint: UnitPoint(x: 0.25, y: 0.5), endPoint: UnitPoint(x: 0.75, y: 0.5)))
            .rotationEffect(Angle(degrees: 135))
            .aspectRatio(contentMode: .fit)
    }
}

struct CircleView_Previews: PreviewProvider {
    static var previews: some View {
        return CircleView()
    }
}
