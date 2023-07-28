//
//  CardHeaderInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol CardHeaderInfoProvider: AnyObject {
    var cardHeaderImage: ImageType? { get }
    var isCardLocked: Bool { get }
    var cardNamePublisher: AnyPublisher<String, Never> { get }
}
