//
//  TwinIntroBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TwinIntroBackgroundView: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(.sRGB,
                            red: 222.0/255.0,
                            green: 222.0/255.0,
                            blue: 224.0/255.0,
                            opacity: 0.4))
            
            Ellipse()
                .fill(Color(.sRGB,
                            red: 220.0/255.0,
                            green: 220.0/255.0,
                            blue: 220.0/255.0,
                            opacity: 0.4))
                .padding(inset(for: 0.6))
            
            Ellipse()
                .fill(Color(.sRGB,
                            red: 217.0/255.0,
                            green: 217.0/255.0,
                            blue: 217.0/255.0,
                            opacity: 0.4))
                .padding(inset(for: 0.3))
        }
        .frame(size: size)
    }
    
    private func inset(for coeff: CGFloat) -> EdgeInsets {
        let width = coeff * 0.4 * size.width
        let height = coeff * 0.5 * size.height
        
        return .init(top: height,
                     leading: width,
                     bottom: height,
                     trailing: width)
    }
}

struct TwinIntroBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        TwinIntroBackgroundView(size: CGSize(width: 300 * 1.25, height: 300))
    }
}
