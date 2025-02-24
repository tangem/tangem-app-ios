//
//  MarketsTokenDetailsLinksMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct MarketsTokenDetailsLinksMapper {
    private let defaultIcon = Assets.arrowRightUp

    let openLinkAction: (MarketsTokenDetailsLinks.LinkInfo) -> Void

    func mapToSections(_ links: MarketsTokenDetailsLinks?) -> [MarketsTokenDetailsLinkSection] {
        guard let links else {
            return []
        }

        var sections = [MarketsTokenDetailsLinkSection]()
        if let officialLinks = links.officialLinks, !officialLinks.isEmpty {
            sections.append(.init(section: .officialLinks, chips: mapLinksToChips(officialLinks)))
        }
        if let socialLinks = links.social, !socialLinks.isEmpty {
            sections.append(.init(section: .social, chips: mapLinksToChips(socialLinks)))
        }
        if let repositoryLinks = links.repository, !repositoryLinks.isEmpty {
            sections.append(.init(section: .repository, chips: mapLinksToChips(repositoryLinks)))
        }
        if let blockchainSiteLinks = links.blockchainSite, !blockchainSiteLinks.isEmpty {
            sections.append(.init(section: .blockchainSite, chips: mapLinksToChips(blockchainSiteLinks)))
        }

        return sections
    }

    private func mapLinksToChips(_ links: [MarketsTokenDetailsLinks.LinkInfo]) -> [MarketsTokenDetailsLinkChipsData] {
        links.compactMap(mapLinkToChips)
    }

    private func mapLinkToChips(_ linkInfo: MarketsTokenDetailsLinks.LinkInfo) -> MarketsTokenDetailsLinkChipsData? {
        let icon: ImageType = if let id = linkInfo.id {
           .init(name: id)
        } else {
            defaultIcon
        }

        let title = if let url = URL(string: linkInfo.title), let hostTitle = url.host {
            hostTitle
        } else {
            linkInfo.title
        }

        guard let url = URL(string: linkInfo.link), UIApplication.shared.canOpenURL(url) else {
            return nil
        }

        return .init(
            text: title,
            icon: .leading(icon),
            link: linkInfo.link,
            action: {
                openLinkAction(linkInfo)
            }
        )
    }
}
