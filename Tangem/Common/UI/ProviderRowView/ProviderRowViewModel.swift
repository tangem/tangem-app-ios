//
//  ProviderRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct ProviderRowViewModel: Identifiable {
    var id: Int { provider.hashValue }

    let provider: Provider
    let titleFormat: TitleFormat

    var providerTitle: Title {
        switch titleFormat {
        case .prefixAndName:
            let text = Localization.expressByProvider(provider.name)
            let attributedString = NSMutableAttributedString(string: text, attributes: [
                .font: UIFonts.Regular.footnote,
                .foregroundColor: UIColor(Colors.Text.tertiary),
            ])

            if let range = text.range(of: provider.name) {
                attributedString.addAttributes(
                    [
                        .font: UIFonts.Regular.footnote,
                        .foregroundColor: UIColor(Colors.Text.primary1),
                    ],
                    range: NSRange(range, in: text)
                )
            }

            return .attributed(attributedString)

        case .name:
            return .text(provider.name)
        }
    }

    let isDisabled: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
    let detailsType: DetailsType?
    let tapAction: (() -> Void)?

    init(
        provider: Provider,
        titleFormat: TitleFormat,
        isDisabled: Bool,
        badge: Badge?,
        subtitles: [Subtitle],
        detailsType: DetailsType?,
        tapAction: (() -> Void)? = nil
    ) {
        self.provider = provider
        self.titleFormat = titleFormat
        self.isDisabled = isDisabled
        self.badge = badge
        self.subtitles = subtitles
        self.detailsType = detailsType
        self.tapAction = tapAction
    }
}

extension ProviderRowViewModel {
    enum Title {
        case text(String)

        @available(iOS, obsoleted: 15, message: "Should be replaced on AttributedString")
        case attributed(NSAttributedString)
    }

    enum TitleFormat {
        case prefixAndName
        case name
    }

    struct Provider: Hashable {
        let id: String
        let iconURL: URL?
        let name: String
        let type: String
    }

    enum Badge: String, Hashable {
        case permissionNeeded
        case bestRate
    }

    enum Subtitle: Hashable, Identifiable {
        var id: Int { hashValue }

        case text(String)
        case percent(String, signType: ChangeSignType)
    }

    enum DetailsType: Hashable {
        case selected
        case chevron
    }
}
