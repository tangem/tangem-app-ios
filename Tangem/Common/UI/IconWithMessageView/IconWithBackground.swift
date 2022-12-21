//
//  IconWithBackground.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct IconWithBackground: View {
    private let icon: ImageType
    private let settings: Settings

    init(
        icon: ImageType,
        settings: Settings = .init(backgroundColor: Colors.Button.secondary,
                                   padding: 14,
                                   cornerRadius: 16)
    ) {
        self.icon = icon
        self.settings = settings
    }

    var body: some View {
        icon.image
            .roundedBackground(with: settings.backgroundColor,
                               padding: settings.padding,
                               radius: settings.cornerRadius)
    }
}

extension IconWithBackground {
    struct Settings {
        let backgroundColor: Color
        let padding: CGFloat
        let cornerRadius: CGFloat
    }
}

struct ReferralPointIcon_Previews: PreviewProvider {
    static var previews: some View {
        IconWithBackground(icon: Assets.discount)
    }
}
