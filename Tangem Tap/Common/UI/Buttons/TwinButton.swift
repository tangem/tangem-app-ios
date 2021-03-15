//
//  TwinButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TwinButton: View {
    let leftImage: String
    let leftTitle: LocalizedStringKey
    let leftAction: () -> Void
    let leftIsDisabled: Bool
    
    let rightImage: String
    let rightTitle: LocalizedStringKey
    let rightAction: () -> Void
    let rightIsDisabled: Bool
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                
                Button(action: leftAction) {
                    HStack {
                        Text(leftTitle)
                        Image(leftImage)
                    }
                }
                .disabled(leftIsDisabled)
                .frame(width: (geo.size.width - 1)/2, height: 56)
                .overlay(!leftIsDisabled ? Color.clear : Color.white.opacity(0.4))
                
                Color.white
                    .opacity(0.3)
                    .frame(width: 1)
                    .padding(.vertical, 10)
                    .cornerRadius(0.5)

                Button(action: rightAction) {
                    HStack {
                        Text(rightTitle)
                        Image(rightImage)
                    }
                }
                .disabled(rightIsDisabled)
                .frame(width: (geo.size.width - 1)/2, height: 56)
                .overlay(!rightIsDisabled ? Color.clear : Color.white.opacity(0.4))

            }
            .frame(width: geo.size.width, height: 56)
            
        }
        .font(Font.custom("SairaSemiCondensed-Bold", size: 15.0))
        .foregroundColor(Color.white)
        .frame(height: 56)
        .background(Color.tangemTapGreen)
        .cornerRadius(8)
    }
}

struct TwinButton_Previews: PreviewProvider {
    static var previews: some View {
        TwinButton(leftImage: "arrow.up",
                   leftTitle: "Topup",
                   leftAction: {},
                   leftIsDisabled: false,
                   
                   rightImage: "arrow.right",
                   rightTitle: "Send",
                   rightAction: {},
                   rightIsDisabled: true)
            .padding()
    }
}
