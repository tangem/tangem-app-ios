//
//  SwappingTokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingTokenIconView: View {
    private let state: State
    private var action: (() -> Void)?

    init(state: State) {
        self.state = state
    }

    private let imageSize = CGSize(width: 36, height: 36)
    private let mainContentSize = CGSize(width: 40, height: 40)
    private let chevronIconSize = CGSize(width: 9, height: 9)

    private var chevronYOffset: CGFloat {
        mainContentSize.height / 2 - chevronIconSize.height / 2
    }

    private var isTappable: Bool {
        action != nil
    }

    var body: some View {
        Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                mainContent
                    // chevron's space
                    .padding(.trailing, 12)

                Assets.chevronDownMini.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .frame(size: chevronIconSize)
                    // View have to keep size of the view same for both cases
                    .opacity(isTappable ? 1 : 0)
                    .offset(y: chevronYOffset)
            }
        }
        .disabled(!isTappable)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch state {
        case .loading:
            VStack(spacing: 2) {
                SkeletonView()
                    .frame(size: imageSize)
                    .cornerRadius(imageSize.height / 2)
                    .padding(.all, 2)

                SkeletonView()
                    .frame(width: 30, height: 12)
                    .cornerRadius(3)
            }

        case .notAvailable:
            VStack(spacing: 2) {
                Assets.emptyTokenList.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Colors.Icon.inactive)
                    .frame(size: imageSize)
                    .padding(.all, 2)

                Text("-")
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
        case .icon(let tokenIconInfo):
            VStack(spacing: 2) {
                TokenIcon(tokenIconInfo: tokenIconInfo, size: imageSize)
                    .padding(.all, 2)

                Text("BTC")
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
        }
    }
}

// MARK: - Setupable

extension SwappingTokenIconView: Setupable {
    func onTap(_ action: (() -> Void)?) -> Self {
        map { $0.action = action }
    }
}

struct SwappingTokenIcon_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SwappingTokenIconView(state: .loading)

            SwappingTokenIconView(state: .loading)
                .onTap {}

            SwappingTokenIconView(state: .notAvailable)
                .onTap {}

            SwappingTokenIconView(
                state: .icon(
                    TokenIconInfoBuilder().build(
                        from: .blockchain(.bitcoin(testnet: false)),
                        isCustom: false
                    )
                )
            )
            .onTap {}

            SwappingTokenIconView(
                state: .icon(
                    TokenIconInfoBuilder().build(
                        from: .blockchain(.bitcoin(testnet: false)),
                        isCustom: false
                    )
                )
            )
        }
    }
}

extension SwappingTokenIconView {
    enum State: Hashable {
        case loading
        case notAvailable
        case icon(TokenIconInfo)
    }
}
