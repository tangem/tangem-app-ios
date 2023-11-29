//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel

    var body: some View {
        SprinklrSupportChatView(viewModel: viewModel.sprinklrViewModel)
    }
}
