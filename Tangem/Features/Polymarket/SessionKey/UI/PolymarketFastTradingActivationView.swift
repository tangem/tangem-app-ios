//
//  PolymarketFastTradingActivationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketFastTradingActivationView: View {
    @ObservedObject var viewModel: PolymarketFastTradingActivationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                OnboardingHero(image: Assets.Polymarket.fastTradingHero, tint: .short, scrollSpace: Constants.scrollSpace)

                content
            }
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            PolymarketTopBar(onClose: { viewModel.handleViewAction(.close) })
                .padding(.top, Constants.topBarTopPadding)
        }
        .footer { activationFooter }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .bindAlert($viewModel.alert)
        .modal(
            isPresented: $viewModel.isFAQPresented,
            size: .full,
            navigation: .title(PolymarketFastTradingStrings.title),
            content: { PolymarketFastTradingFAQView() }
        )
        .onAppear { viewModel.handleViewAction(.onAppear) }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PolymarketFastTradingStrings.infoTitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Constants.contentHorizontalPadding)
                .padding(.vertical, Constants.blockVerticalPadding)

            PolymarketFastTradingInfoTiles(onDurationInfo: { viewModel.handleViewAction(.openFAQ) })

            VStack(spacing: 0) {
                ForEach(indexed: Self.sections, id: \.1) { index, section in
                    PolymarketTextSection(title: section.title, text: section.text, isSeparated: index > 0)
                }
            }
            .padding(.horizontal, Constants.contentHorizontalPadding)
        }
    }

    // MARK: - Footer

    private var activationFooter: Footer {
        let button = SigningActionButtonView(
            type: viewModel.signingButtonType,
            title: viewModel.buttonTitle,
            isLoading: viewModel.isProcessing,
            isDisabled: viewModel.isButtonDisabled,
            action: { viewModel.handleViewAction(.authorize) }
        )

        return Footer(.signingButton(button))
            .caption(viewModel.pendingChangeNotice.map { AttributedString($0) })
            .showFade()
    }
}

// MARK: - Content

private extension PolymarketFastTradingActivationView {
    static var sections: [PolymarketFastTradingStrings.Section] {
        [
            PolymarketFastTradingStrings.whatItIs,
            PolymarketFastTradingStrings.whatItCanDo,
            PolymarketFastTradingStrings.whatItCantDo,
            PolymarketFastTradingStrings.youAreInControl,
        ]
    }

    enum Constants {
        static let scrollSpace = "polymarketFastTradingActivationScroll"
        static let topBarTopPadding: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 24
        static let blockVerticalPadding: CGFloat = 12
    }
}

// MARK: - Previews

#if DEBUG
private extension PolymarketFastTradingActivationViewModel {
    static func preview(
        sessionKeys: [PolymarketSessionKey] = [],
        localKeyAddress: String? = nil,
        signingButtonType: SigningActionButtonViewType = .requiredNFCInteraction
    ) -> PolymarketFastTradingActivationViewModel {
        PolymarketFastTradingActivationViewModel(
            service: PolymarketFastTradingPreviewService(sessionKeys: sessionKeys, localKeyAddress: localKeyAddress),
            signingButtonType: signingButtonType,
            onClose: {}
        )
    }
}

private typealias PreviewKey = PolymarketFastTradingPreviewService

#Preview("Offer") {
    PolymarketFastTradingActivationView(viewModel: .preview())
}

#Preview("Hold to confirm") {
    PolymarketFastTradingActivationView(viewModel: .preview(signingButtonType: .holdToConfirm))
}

#Preview("Reactivate: this device's key expired") {
    PolymarketFastTradingActivationView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(
            address: "0x1",
            deviceName: "iPhone 16 Air",
            deviceId: PreviewKey.thisDeviceId,
            status: .expired,
            validUntil: Date().addingTimeInterval(-24 * 60 * 60)
        )],
        localKeyAddress: "0x1"
    ))
}

#Preview("Extend: this device's key expires soon") {
    PolymarketFastTradingActivationView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(
            address: "0x1",
            deviceName: "iPhone 16 Air",
            deviceId: PreviewKey.thisDeviceId,
            status: .active,
            validUntil: Date().addingTimeInterval(12 * 24 * 60 * 60)
        )],
        localKeyAddress: "0x1"
    ))
}

#Preview("Change in progress on another device") {
    PolymarketFastTradingActivationView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x2", deviceName: "iPhone XR", status: .pending)]
    ))
}
#endif
