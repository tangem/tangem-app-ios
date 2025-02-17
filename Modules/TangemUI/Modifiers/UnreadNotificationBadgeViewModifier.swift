//
//  UnreadNotificationBadgeViewModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func unreadNotificationBadge(_ shouldShowBadge: Bool, badgeColor: Color) -> some View {
        modifier(UnreadNotificationBadgeViewModifier(shouldShowBadge: shouldShowBadge, badgeColor: badgeColor))
    }
}

struct UnreadNotificationBadgeViewModifier: ViewModifier {
    let shouldShowBadge: Bool
    let badgeColor: Color

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if shouldShowBadge {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .frame(width: 9, height: 9)
                            .offset(x: 3, y: -3)
                            .blendMode(.destinationOut)

                        Circle()
                            .fill(badgeColor)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -2)
                    }
                    .transition(.scale)
                }
            }
            .compositingGroup()
            .animation(.linear(duration: 0.1), value: shouldShowBadge)
    }
}

struct UnreadNotificationBadgeViewModifier_Previews: PreviewProvider {
    struct Preview: View {
        @State var showBadge = true

        var body: some View {
            Button("Button with badge") {
                showBadge.toggle()
            }
            .buttonStyle(.borderedProminent)
            .unreadNotificationBadge(showBadge, badgeColor: .red)
            .padding()
            .background(.black)
        }
    }

    static var previews: some View {
        Preview()
            .previewLayout(.sizeThatFits)
    }
}
