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
    @StateObject private var viewModel: RecentRecipientsViewModel

    init(viewModel: @autoclosure @escaping () -> RecentRecipientsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        RecentRecipientsContentView(
            recipients: viewModel.recipients,
            onRecipientTap: viewModel.onRecipientTap
        )
        .tangemSearchable(
            text: $viewModel.searchText,
            isActive: $viewModel.isSearchActive,
            prompt: Localization.commonSearch
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onChange(of: viewModel.isSearchActive, perform: viewModel.searchActiveDidChange(to:))
    }
}
