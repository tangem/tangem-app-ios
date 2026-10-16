//
//  JointAccountInviteActivityItemSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import LinkPresentation
import UIKit
import TangemLocalization

final class JointAccountInviteActivityItemSource: NSObject, UIActivityItemSource {
    private let url: URL
    private let accountName: String

    init(url: URL, accountName: String) {
        self.url = url
        self.accountName = accountName
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        Localization.jointAccountInviteShareTitle(accountName)
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = Localization.jointAccountInviteShareTitle(accountName)
        metadata.originalURL = url
        metadata.url = url
        metadata.iconProvider = UIImage.appIcon.map { NSItemProvider(object: $0) }

        return metadata
    }
}
