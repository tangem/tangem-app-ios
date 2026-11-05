//
//  JointAccountInviteActivityItemSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import LinkPresentation
import UIKit
import TangemFoundation
import TangemLocalization

final class JointAccountInviteActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL

    private let accountName: String

    var message: String {
        Localization.jointAccountInviteMemberMessage(accountName, "").trimmed()
    }

    var shareMessage: String {
        Localization.jointAccountInviteMemberMessage(accountName, url.absoluteString)
    }

    init(accountName: String, url: URL) {
        self.accountName = accountName
        self.url = url
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        shareMessage
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        shareMessage
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
