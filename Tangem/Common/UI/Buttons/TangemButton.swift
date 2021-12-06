//
//  TangemButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemButton: View {
    let title: LocalizedStringKey
    var image: String = ""
    var systemImage: String = ""
    var iconPosition: IconPosition = .leading
    var iconPadding: CGFloat = 8
    let action: () -> Void
    
    @ViewBuilder
    private var icon: some View {
        if !image.isEmpty {
            Image(image)
        } else if !systemImage.isEmpty {
            Image(systemName: systemImage)
        } else {
            EmptyView()
        }
    }
    
    private var hasImage: Bool {
        !image.isEmpty || !systemImage.isEmpty
    }
    
    @ViewBuilder
    private var label: some View {
        Text(title)
            .lineLimit(2)
            .transition(.opacity)
            .id("tangem_button_\(title)")
    }
    
    
    var body: some View {
        Button(action: action, label:  {
            if !hasImage {
                label
            } else {
                Group {
                    if iconPosition == .leading {
                        icon
                        Color.clear.frame(width: iconPadding, height: iconPadding)
                        label
                    } else {
                        label
                        Color.clear.frame(width: iconPadding, height: iconPadding)
                        icon
                    }
                }
            }
        })
    }
}

extension TangemButton {
    enum IconPosition {
        case leading, trailing
    }
    
    static func vertical(title: LocalizedStringKey,
                         image: String = "",
                         systemImage: String = "",
                         action: @escaping () -> Void) -> TangemButton {
        return TangemButton(title: title,
                            image: image,
                            systemImage: systemImage,
                            iconPosition: .leading,
                            iconPadding: 2,
                            action: action)
    }
}

struct TangemButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TangemButton(title: "Recharge de portefeuille", image: "scan") {}
                .buttonStyle(TangemButtonStyle(colorStyle: .black))
            
            TangemButton(title: "wallet_button_scan", image: "scan") {}
                .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                               layout: .big))
 
            HStack {
                TangemButton(title: "wallet_button_send",
                             image: "scan") {}
                    .buttonStyle(TangemButtonStyle(layout: .smallVertical,
                                                   isLoading: true))
                
                TangemButton.vertical(title: "wallet_button_topup",
                                      systemImage: "arrow.up") {}
                    .buttonStyle(TangemButtonStyle(layout: .smallVertical))
                
            
                TangemButton.vertical(title: "wallet_button_scan",
                                      systemImage: "arrow.right") {}
                    .buttonStyle(TangemButtonStyle(layout: .smallVertical))
                
            }
            .padding(.horizontal, 8)
            
        }
        .environment(\.locale, .init(identifier: "fr"))
        .previewGroup()
    }
}
