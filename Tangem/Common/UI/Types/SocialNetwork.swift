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

    var url: URL? {
        switch self {
        case .telegram:
            if Locale.current.languageCode == LanguageCode.ru.rawValue {
                return URL(string: "https://t.me/tangem_ru")
            }

            return URL(string: "https://t.me/TangemCards")
        case .twitter:
            return URL(string: "https://twitter.com/tangem")
        case .facebook:
            return URL(string: "https://facebook.com/TangemCards/")
        case .instagram:
            return URL(string: "https://instagram.com/tangemcards")
        case .github:
            return URL(string: "https://github.com/tangem")
        case .youtube:
            return URL(string: "https://youtube.com/channel/UCFGwLS7yggzVkP6ozte0m1w")
        case .linkedin:
            return URL(string: "https://www.linkedin.com/company/tangem")
        }
    }
}
