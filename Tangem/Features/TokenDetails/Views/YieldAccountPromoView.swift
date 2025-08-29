//
//  YieldAccountPromoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct YieldAccountPromoView: View {
    
    // MARK: - Properties
    
    private let annualYield = "5.1"
    
    // MARK: - Sub Views

    private var background: some View {
        Colors.Background.primary.ignoresSafeArea()
    }

    private var topLogo: some View {
        ZStack {
            Circle()
                .foregroundStyle(Colors.Icon.accent.opacity(0.1))
                .frame(size: .init(bothDimensions: 72))

            Assets.YieldAccount.yieldPromoTopLogo.image
                .resizable()
                .renderingMode(.template)
                .frame(size: .init(bothDimensions: 34))
                .foregroundStyle(Colors.Icon.accent)
        }
    }

    private var title: some View {
        Text("Earn \(annualYield)% yearly").style(Fonts.Bold.title1, color: Colors.Text.primary1)
    }

    private var pillInfoButton: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Text("Aave • Variable Interest Rate").style(Fonts.Bold.caption1, color: Colors.Text.secondary)

                Image(systemName: "info.circle")
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Colors.Control.unchecked)
            .clipShape(Capsule())
        }
    }

    private var benefitsStack: some View {
        VStack(spacing: 24) {
            BenefitRow(
                icon: Assets.YieldAccount.yieldPromoLightning.image,
                title: "Cash out instantly",
                subtitle: "Send, swap, or sell your funds instantly, anytime you want."
            )

            BenefitRow(
                icon: Assets.YieldAccount.yieldPromoSync.image,
                title: "Your balance works automatically",
                subtitle: "Every top‑up of your account will be lended to Aave automatically."
            )

            BenefitRow(
                icon: Assets.YieldAccount.yieldPromoGuard.image,
                title: "Decentralized and self-custodial",
                subtitle: "Aave is trusted by millions worldwide. Total lended value is $10.4B. "
            )
        }
    }

    private var tosAndPrivacy: some View {
        VStack(spacing: 2) {
            Text("By using service, you agree with provider")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            HStack(spacing: 4) {
                Text(.init("[Terms of Use](https://www.google.es/)")).style(Fonts.Regular.footnote, color: Colors.Text.accent)

                Text("and").style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Text(.init("[Privacy Policy](https://www.bbc.com/)")).style(Fonts.Regular.footnote, color: Colors.Text.accent)
            }
        }
    }

    private var continueButton: some View {
        Button(action: {}) {
            Text(Localization.commonContinue)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.tangemStyle)
    }
    
    // MARK: - View Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: .zero) {
                Spacer()

                topLogo.padding(.bottom, 20)

                title.padding(.bottom, 12)

                pillInfoButton.padding(.bottom, 32)

                benefitsStack.padding(.horizontal, 40)

                Spacer()

                tosAndPrivacy.padding(.bottom, 16)

                continueButton
                    .padding(.bottom, 6)
                    .padding(.horizontal, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localization.commonClose) {
                    UIApplication.dismissTop()
                }
                .foregroundColor(Colors.Text.primary1)
            }
        }
    }
}

private extension YieldAccountPromoView {
    struct BenefitRow: View {
        let icon: Image
        let title: String
        let subtitle: String
        
        private var iconView: some View {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: 24))
                .contentShape(Rectangle())
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                
                iconView
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    Text(subtitle).style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    YieldAccountPromoView()
}
