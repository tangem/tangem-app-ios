//
//  TangemButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemButton: View {
    enum IconPosition {
        case leading, trailing
    }
    
    let isLoading: Bool    
    let title: LocalizedStringKey
    var image: String = ""
    var systemImage: String = ""
    var size: ButtonSize = .small
    var iconPosition: IconPosition = .trailing
    let action: () -> Void
    
    @ViewBuilder
    var icon: some View {
        if !image.isEmpty {
            Image(image)
        } else if !systemImage.isEmpty {
            Image(systemName: systemImage)
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label:  {
            HStack(alignment: .center, spacing: 8) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    if iconPosition == .leading {
                        icon
                    }
                    Text(title)
                        .transition(.opacity)
                        .id("tangem_button_\(title)")
                    if iconPosition == .trailing {
                        icon
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(minWidth: size.value.width,
                   maxWidth: .infinity,
                   minHeight: size.value.height,
                   maxHeight: size.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
}

struct TangemVerticalButton: View {
    let isLoading: Bool
    let title: LocalizedStringKey
    let image: Image?
    let action: () -> Void
    
    init(isLoading: Bool, title: LocalizedStringKey, image: (() -> Image)?, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.title = title
        self.image = image?()
        self.action = action
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: nil, action: action)
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, image: String, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: { Image(image) }, action: action)
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: { Image(systemName: systemImage) }, action: action)
    }
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label:  {
            
            VStack(alignment: .center, spacing:0) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    image
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text(title)
                        .lineLimit(2)
                }
            }
            .padding(.all, 8)
            .frame(minWidth: ButtonSize.smallVertical.value.width - 0.1 * ButtonSize.smallVertical.value.width,
                   maxWidth: ButtonSize.smallVertical.value.width,
                   minHeight: ButtonSize.smallVertical.value.height,
                   idealHeight: ButtonSize.smallVertical.value.height,
                   maxHeight: ButtonSize.smallVertical.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
    
    
}

struct TangemLongButton: View {
    let isLoading: Bool
    let title: LocalizedStringKey
    let image: Image?
    let action: () -> Void
    
    init(isLoading: Bool, title: LocalizedStringKey, image: (() -> Image)?, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.title = title
        self.image = image?()
        self.action = action
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: nil, action: action)
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, image: String, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: { Image(image) }, action: action)
    }
    
    init(isLoading: Bool, title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, title: title, image: { Image(systemName: systemImage) }, action: action)
    }
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label: {
            HStack(alignment: .center, spacing: 8) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    Text(title)
                    Spacer()
                    image
                }
            }
            .padding(.horizontal, 16)
            .frame(minWidth: ButtonSize.big.value.width - 0.1*ButtonSize.big.value.width,
                   maxWidth: ButtonSize.big.value.width,
                   minHeight: ButtonSize.big.value.height,
                   maxHeight: ButtonSize.big.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
}

struct TangemButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TangemButton(isLoading: false,
                         title: "Recharge de portefeuille",
                         image: "scan") {}
                .buttonStyle(TangemButtonStyle(color: .black))
            
            TangemLongButton(isLoading: false,
                             title: "wallet_button_scan",
                             image: "scan") {}
                .buttonStyle(TangemButtonStyle(color: .black))
            
                HStack {
                    TangemVerticalButton(isLoading: true,
                                         title: "wallet_button_send",
                                         image: "scan") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(0)
                    
                    TangemVerticalButton(isLoading: false,
                                         title: "wallet_button_topup",
                                         image: "arrow.up") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(1)
                    TangemVerticalButton(isLoading: false,
                                         title: "wallet_button_scan",
                                         image: "arrow.right") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(0)
                }
                .padding(.horizontal, 8)
            
            
            
        }
        .environment(\.locale, .init(identifier: "fr"))
        .previewGroup()
    }
}
