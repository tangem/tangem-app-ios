//
//  JointAccountMemberIconView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct JointAccountMemberIconView: View {
    let viewData: JointAccountMemberIconViewData
    let diameter: CGFloat

    var body: some View {
        switch viewData {
        case .member(let viewData):
            AddressBookContactNameIconView(viewData: viewData, size: diameter)
        case .vacant:
            JointAccountMemberCircle(state: .vacant, diameter: diameter)
        }
    }
}
