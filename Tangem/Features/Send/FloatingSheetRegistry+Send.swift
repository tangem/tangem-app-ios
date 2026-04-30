//
//  FloatingSheetRegistry+Send.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerSendFloatingSheets() {
        register(ApproveFlowViewModel.self) { viewModel in
            ApproveFlowView(viewModel: viewModel)
        }

        register(SendFeeSelectorViewModel.self) { viewModel in
            SendFeeSelectorView(viewModel: viewModel)
        }

        register(SendSwapProvidersSelectorViewModel.self) { viewModel in
            SendSwapProvidersSelectorView(viewModel: viewModel)
        }

        register(HighPriceImpactWarningSheetViewModel.self) { viewModel in
            HighPriceImpactWarningSheetView(viewModel: viewModel)
        }

        register(RateInfoSheetViewModel.self) { viewModel in
            RateInfoSheetView(viewModel: viewModel)
        }

        register(OnrampOffersSelectorViewModel.self) { viewModel in
            OnrampOffersSelectorView(viewModel: viewModel)
        }

        register(OnrampKYCVerificationSheetViewModel.self) { viewModel in
            OnrampKYCVerificationSheetView(viewModel: viewModel)
        }

        register(BlockchainAccountInitializationViewModel.self) { viewModel in
            BlockchainAccountInitializationView(viewModel: viewModel)
        }
    }
}
