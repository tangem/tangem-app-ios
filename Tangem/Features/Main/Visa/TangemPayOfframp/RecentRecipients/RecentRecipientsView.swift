//
//  RecentRecipientsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct RecentRecipientsView: View {
    @ObservedObject var viewModel: RecentRecipientsViewModel

    var body: some View {
        RecentRecipientsContentView(
            recipients: viewModel.recipients,
            onRecipientTap: viewModel.onRecipientTap
        )
        .tangemSearchable(text: $viewModel.searchText, prompt: Localization.commonSearch)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}
