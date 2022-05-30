//
//  TangemSkeletonModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import SkeletonUI

extension View {
    @ViewBuilder func skeletonable(isShown: Bool, size: CGSize? = nil) -> some View {
        self.skeleton(with: isShown, size: size)
            .appearance(type: .gradient(.linear, color: .tangemSkeletonGray, background: .tangemSkeletonGray2, radius: 1, angle: .zero))
            .shape(type: .rounded(.radius(3, style: .circular)))
    }
}
