//
//  ButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ButtonLayout {
    case small
    case big
    case smallVertical
    case thinHorizontal
    case wide
    case customWidth(CGFloat)
    case custom(size: CGSize)
    case flexible
    
    var size: CGSize? {
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
        case .flexible:
            return nil
        }
    }
    
    var alignment: Alignment {
        switch self {
        case .smallVertical:
            return .vertical
        default:
            return .horizontal
        }
    }
    
    private var defaultHeight: CGFloat {
        Constants.isSmallScreen ? 44 : 50
    }
}

extension ButtonLayout {
    enum Alignment {
        case vertical
        case horizontal
    }
}

enum ButtonColorStyle {
    case green
    case black
    case gray
    case transparentWhite
    case grayAlt
    
    var bgColor: Color {
        switch self {
        case .green: return .tangemGreen
        case .black: return .tangemGrayDark6
        case .gray: return .tangemGrayLight4
        case .transparentWhite: return .clear
        case .grayAlt: return .tangemBgGray
        }
    }
    
    var bgPressedColor: Color {
        switch self {
        case .green: return .tangemGreen1
        case .black: return .tangemGrayDark5
        case .gray, .grayAlt: return .tangemGrayDark
        case .transparentWhite: return .clear
        }
    }
    
    var fgColor: Color {
        switch self {
        case .transparentWhite, .grayAlt: return .tangemGrayDark6
        default: return .white
        }
    }
    
    var fgPressedColor: Color {
        switch self {
        case .transparentWhite:
            return .tangemGrayDark3
        default:
            return fgColor
        }
    }
    
    var indicatorColor: UIColor {
        switch self {
        case .transparentWhite, .grayAlt: return .tangemGrayDark6
        default: return .white
        }
    }
}

struct TangemButtonStyle: ButtonStyle {
    var colorStyle: ButtonColorStyle = .green
    var layout: ButtonLayout = .small
    var font: Font = .system(size: 17, weight: .semibold, design: .default)
    var isDisabled: Bool = false
    var isLoading: Bool = false

    @ViewBuilder private var loadingOverlay: some View {
        if isLoading  {
            ZStack {
                colorStyle.bgColor
                ActivityIndicatorView(color: colorStyle.indicatorColor)
            }
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder private var disabledOverlay: some View {
        if isDisabled  {
            Color.white.opacity(0.4)
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder private func label(for configuration: Configuration) -> some View {
        if layout.alignment == .vertical {
            VStack(alignment: .center, spacing: 0) {
                configuration.label
            }
            .padding(8)
        } else {
            HStack(alignment: .center, spacing: 0) {
                configuration.label
            }
            .padding(.horizontal, 8)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        label(for: configuration)
            .font(font)
            .foregroundColor(configuration.isPressed ? colorStyle.fgPressedColor : colorStyle.fgColor)
            .frame(width: layout.size?.width, height: layout.size?.height)
            .fixedSize()
            .background(configuration.isPressed ? colorStyle.bgPressedColor : colorStyle.bgColor)
            .overlay(loadingOverlay)
            .overlay(disabledOverlay)
            .cornerRadius(8)
            .allowsHitTesting(!isDisabled && !isLoading)
    }
}

//Wait for swift 5.5
//extension ButtonStyle where Self == TangemButtonStyle {
//    static var tangemStyle: TangemButtonStyle { .init() }
//}


struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 16.0) {
            TangemButton(title: "Tangem Wide button",
                         systemImage: "arrow.up",
                         action: {})
                .buttonStyle(TangemButtonStyle(layout: .wide))

            TangemButton(title: "Tangem custom button", action: {})
                .buttonStyle(TangemButtonStyle(layout: .custom(size: CGSize(width: 175,
                                                                            height: 44)),
                                               font: .system(size: 18)))
            
            TangemButton(title: "Tangem custom button", action: {})
                .buttonStyle(TangemButtonStyle(layout: .customWidth(234),
                                               font: .system(size: 18)))
            
            
            Button(action:{}){ Text("Tap in!") }
                .buttonStyle(TangemButtonStyle())

            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle(colorStyle: .black))

            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .green,
                                               layout: .big,
                                               isDisabled: true))

            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .black, isDisabled: true))
            
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite,
                                               layout: .flexible))
            
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite,
                                               layout: .flexible,
                                               isDisabled: true))
            
            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt,
                                               layout: .flexible,
                                               font: .system(size: 18)))
        }
    }
}
