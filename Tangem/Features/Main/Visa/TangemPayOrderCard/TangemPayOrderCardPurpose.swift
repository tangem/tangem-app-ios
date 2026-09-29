//
//  TangemPayOrderCardPurpose.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayOrderCardPurpose {
    case issue
    case reissue(sourceProductInstanceId: String)
}
