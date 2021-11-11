//
//  NavigationBusyButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavigationBusyButton: View {
    var isBusy: Bool
    var color: UIColor
    var image: Image
    var action: () -> Void
    
    var body: some View {
        if isBusy {
            ActivityIndicatorView(isAnimating: true, style: .medium, color: color)
        } else {
            Button(action: action, label: {
                image
                    .foregroundColor(Color(color))
                    .frame(width: 44, height: 44)
            })
        }
    }
    
    init(isBusy: Bool, color: UIColor, imageName: String, action: @escaping () -> Void) {
        self.isBusy = isBusy
        self.color = color
        self.image = Image(imageName)
        self.action = action
    }
    
    init(isBusy: Bool, color: UIColor, systemImageName: String, action: @escaping () -> Void) {
        self.isBusy = isBusy
        self.color = color
        self.image = Image(systemName: systemImageName)
        self.action = action
    }
}
