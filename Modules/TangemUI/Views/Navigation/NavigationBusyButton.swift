//
//  NavigationBusyButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct NavigationBusyButton: View {
    private let isBusy: Bool
    private let color: UIColor
    private let image: Image
    private let action: () -> Void

    public init(isBusy: Bool, color: UIColor, imageName: ImageType, action: @escaping () -> Void) {
        self.isBusy = isBusy
        self.color = color
        image = imageName.image
        self.action = action
    }

    public init(isBusy: Bool, color: UIColor, systemImageName: String, action: @escaping () -> Void) {
        self.isBusy = isBusy
        self.color = color
        image = Image(systemName: systemImageName)
        self.action = action
    }

    public var body: some View {
        if isBusy {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(uiColor: color))
        } else {
            Button(action: action, label: {
                image
                    .foregroundColor(Color(color))
            })
        }
    }
}
