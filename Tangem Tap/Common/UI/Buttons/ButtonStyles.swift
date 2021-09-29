//
//  ButtonView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ButtonSize {
    case small
    case big
    case smallVertical
    case thinHorizontal
    case wide
    case customWidth(CGFloat)
    case custom(size: CGSize)
    
    var value: CGSize {
        switch self {
        case .small:
            return CGSize(width: 95.0, height: defaultHeight)
        case .big:
            return CGSize(width: 200.0, height: defaultHeight)
        case .smallVertical:
            return CGSize(width: 100.0, height: defaultHeight)
        case .thinHorizontal:
            return CGSize(width: 109, height: 32)
        case .wide:
            return CGSize(width: UIScreen.main.bounds.width - 80, height: defaultHeight)
        case .customWidth(let width):
            return .init(width: width, height: defaultHeight)
        case .custom(let size):
            return size
        }
    }
    
    private var defaultHeight: CGFloat {
        Constants.isSmallScreen ? 44 : 56
    }
}

enum ButtonColorStyle {
    case green
    case black
    case gray
    case transparentWhite
    case grayAlt
    
    var defaultColor: Color {
        switch self {
        case .green: return .tangemTapGreen
        case .black: return .tangemTapGrayDark6
        case .gray: return .tangemTapGrayLight4
        case .transparentWhite: return .clear
        case .grayAlt: return .tangemTapBgGray
        }
    }
    
    var pressedColor: Color {
        switch self {
        case .green: return .tangemTapGreen1
        case .black: return .tangemTapGrayDark6
        case .gray, .grayAlt: return .tangemTapGrayDark
        case .transparentWhite: return .tangemTapGrayLight4
        }
    }
    
    var titleColor: Color {
        switch self {
        case .transparentWhite, .grayAlt: return .tangemTapGrayDark6
        default: return .white
        }
    }
}

struct TangemButtonStyle: ButtonStyle {
    var color: ButtonColorStyle = .green
    var font: Font = Font.custom("SairaSemiCondensed-Bold", size: 15.0)
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(font)
            .foregroundColor(color.titleColor)
            .background(
                configuration.isPressed ?
                    color.pressedColor :
                    color.defaultColor
                )
            .cornerRadius(8)
            .overlay( !isDisabled ? Color.clear : Color.white.opacity(0.4))
            .allowsHitTesting(!isDisabled)
    }
}

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 16.0) {
            TangemButton(isLoading: false,
                         title: "Tangem Wide button",
                         size: .wide,
                         action: {})
                .buttonStyle(TangemButtonStyle(color: .green, font: .system(size: 18), isDisabled: false))
            TangemButton(isLoading: false,
                         title: "Tangem custom button",
                         size: .custom(size: CGSize(width: 175, height: 44)),
                         action: {})
                .buttonStyle(TangemButtonStyle(color: .green, font: .system(size: 18), isDisabled: false))
            TangemButton(isLoading: false,
                         title: "Tangem custom button",
                         size: .customWidth(234),
                         action: {})
                .buttonStyle(TangemButtonStyle(color: .green, font: .system(size: 18), isDisabled: false))
            Button(action:{}){
                Text("Tap in!")}
                .buttonStyle(TangemButtonStyle(color: .green))

            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle(color: .black))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .green, isDisabled: true))
            
            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .black, isDisabled: true))
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .transparentWhite, isDisabled: false))
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .transparentWhite, isDisabled: true))
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(color: .grayAlt, font: .system(size: 18), isDisabled: false))
        }
    }
}
