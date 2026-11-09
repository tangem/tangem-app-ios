//
//  ModalStatus+Slots.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ModalStatusExtraBottomSlot<Content: View>: View {
    let content: Content

    public var body: some View {
        VStack(spacing: 8) {
            content
        }
    }
}

public struct ModalStatusDetailsSlot<Content: View>: View {
    let content: Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
