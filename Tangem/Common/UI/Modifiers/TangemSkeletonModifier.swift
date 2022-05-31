//
//  TangemSkeletonModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func skeletonable(isShown: Bool, size: CGSize) -> some View {
        modifier(SkeletonModifier(isShow: isShown, size: size, radius: 3))
    }
}

// MARK: Modifier for View

public struct SkeletonModifier: ViewModifier {
    private let isShow: Bool
    private let size: CGSize
    private let radius: CGFloat
    
    public init(isShow: Bool, size: CGSize, radius: CGFloat) {
        self.isShow = isShow
        self.size = size
        self.radius = radius
    }
    
    public func body(content: Content) -> some View {
        if isShow {
            SkeletonView()
                .frame(size: size)
                .cornerRadius(radius)
        } else {
            content
        }
    }
}

