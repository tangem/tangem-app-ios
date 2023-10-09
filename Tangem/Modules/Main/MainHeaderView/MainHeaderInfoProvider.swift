//
//  MainHeaderInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainHeaderInfoProvider: AnyObject {
    var cardHeaderImage: ImageType? { get }
    var isUserWalletLocked: Bool { get }
    var isTokensListEmpty: Bool { get }
    var userWalletNamePublisher: AnyPublisher<String, Never> { get }
}
