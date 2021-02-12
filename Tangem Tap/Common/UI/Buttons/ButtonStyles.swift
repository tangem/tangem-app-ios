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
    case smallVertical
    case thinHorizontal
    
    var value: CGSize {
        switch self {
        case .small:
            return CGSize(width: 95.0, height: 56.0)
        case .big:
            return CGSize(width: 200.0, height: 56.0)
        case .smallVertical:
            return CGSize(width: 100.0, height: 56.0)
        case .thinHorizontal:
            return CGSize(width: 109, height: 32)
        }
    }
}

enum ButtonColorStyle {
    case green
    case black
    case gray
    
    var defaultColor: Color {
        switch self {
        case .green: return .tangemTapGreen
        case .black: return .tangemTapGrayDark6
        case .gray: return .tangemTapGrayLight4
        }
    }
    
    var pressedColor: Color {
        switch self {
        case .green: return .tangemTapGreen1
        case .black: return .tangemTapGrayDark6
        case .gray: return .tangemTapGrayDark
        }
    }
}

struct TangemButtonStyle: ButtonStyle {
    var color: ButtonColorStyle = .green
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(Font.custom("SairaSemiCondensed-Bold", size: 15.0))
            .foregroundColor(Color.white)
            .background(
                configuration.isPressed ?
                    color.pressedColor :
                    color.defaultColor
                )
            .cornerRadius(8)
            .overlay( !isDisabled ? Color.clear : Color.white.opacity(0.4))
    }
}

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 16.0) {
            Button(action:{}){
                Text("Tap in!")}
                .buttonStyle(TangemButtonStyle(color: .green))

            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle(color: .black))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .green, isDisabled: true))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .black, isDisabled: true))
        }
    }
}
