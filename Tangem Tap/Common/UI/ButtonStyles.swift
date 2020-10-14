//
//  ButtonView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ButtonSize: CGFloat {
    case small
    case big
    
    var value: CGSize {
        switch self {
        case .small:
            return CGSize(width: 93.0, height: 56.0)
        case .big:
            return CGSize(width: 200.0, height: 56.0)
        }
    }
}

enum ButtonColorStyle {
    case green
    case black
}

struct TangemButtonStyle: ButtonStyle {
    var size: ButtonSize = .small
    var colorStyle: ButtonColorStyle = .green
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(Font.custom("SairaSemiCondensed-Bold", size: 15.0))
            .foregroundColor(Color.white)
			.frame(minWidth: size.value.width, maxWidth: .infinity, minHeight: size.value.height, maxHeight: size.value.height, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .background(
                configuration.isPressed ?
                (colorStyle == .green ? Color.tangemTapGreen1 : Color.tangemTapGrayDark4) :
                (colorStyle == .green ? Color.tangemTapGreen : Color.tangemTapGrayDark6))
            .cornerRadius(8)
            .overlay( !isDisabled ? Color.clear : Color.white.opacity(0.4))
            .fixedSize()
    }
}

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 16.0) {
            Button(action:{}){
                Text("Tap in!")}
                .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .green))
            
            
            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green, isDisabled: true))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .black, isDisabled: true))
        }
    }
}
