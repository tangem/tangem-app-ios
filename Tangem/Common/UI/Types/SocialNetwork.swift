//
//  SocialNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum SocialNetwork: Hashable, CaseIterable, Identifiable {
    var id: Int { hashValue }

    case telegram
    case twitter
    case facebook
    case instagram
    case github
    case youtube
    case linkedin

    var icon: Image {
        switch self {
        case .telegram:
            return Assets.SocialNetwork.telegram
        case .twitter:
            return Assets.SocialNetwork.twitter
        case .facebook:
            return Assets.SocialNetwork.facebook
        case .instagram:
            return Assets.SocialNetwork.instagram
        case .github:
            return Assets.SocialNetwork.gitHub
        case .youtube:
            return Assets.SocialNetwork.youTube
        case .linkedin:
            return Assets.SocialNetwork.linkedIn
        }
    }
}
