//
//  NavbarDotsImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavbarDotsImage: View {
    var body: some View {
        Assets.verticalDots.image
            .offset(x: 11)
            .foregroundColor(Colors.Icon.primary1)
    }
}
