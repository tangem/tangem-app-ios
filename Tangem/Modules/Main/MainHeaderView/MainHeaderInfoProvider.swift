//
//  MainHeaderInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainHeaderInfoProvider: AnyObject {
    var isUserWalletLocked: Bool { get }
    var isTokensListEmpty: Bool { get }
    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { get }
    var userWalletNamePublisher: AnyPublisher<String, Never> { get }
}
