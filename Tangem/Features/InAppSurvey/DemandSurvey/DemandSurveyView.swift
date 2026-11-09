//
//  DemandSurveyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct DemandSurveyView: View {
    @ObservedObject var viewModel: DemandSurveyViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                header

                ForEach(viewModel.survey.questions, id: \.key) { question in
                    questionView(question)
                }
            }
            .padding(Layout.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(viewModel.isSubmitting)
        .footer {
            Footer(.buttons(primary: submitButton))
                .caption(AttributedString(Localization.surveyDemandFooter))
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(Localization.surveyDemandNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Subviews

private extension DemandSurveyView {
    var header: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            Text(Localization.surveyDemandTitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.surveyDemandSubtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    func questionView(_ question: InAppSurvey.Question) -> some View {
        VStack(alignment: .leading, spacing: Layout.questionSpacing) {
            VStack(alignment: .leading, spacing: Layout.labelSpacing) {
                if !question.isRequired {
                    Text(Localization.surveyDemandOptional)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                }

                Text(DemandSurveyTexts.question(for: question.key) ?? question.key)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                if let hint = DemandSurveyTexts.hint(for: question.key) {
                    Text(hint)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)

            WrappingHStack(alignment: .leading, horizontalSpacing: Layout.chipSpacing, verticalSpacing: Layout.chipSpacing) {
                ForEach(question.answerKeys, id: \.self) { answerKey in
                    DemandSurveyAnswerChip(
                        title: DemandSurveyTexts.answer(answerKey, for: question.key) ?? answerKey,
                        isSelected: viewModel.isSelected(answerKey, in: question),
                        action: { viewModel.select(answerKey, in: question) }
                    )
                }
            }
        }
    }

    var submitButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.surveyDemandButton,
            accessibilityLabel: nil,
            action: viewModel.submit
        )
        .loading(.spinner(if: viewModel.isSubmitting))
        .enabled(viewModel.canSubmit)
    }
}

// MARK: - Layout

private extension DemandSurveyView {
    enum Layout {
        static let padding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 8
        static let questionSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let chipSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        DemandSurveyView(viewModel: DemandSurveyViewModel(
            userWalletId: UserWalletId(value: Data(repeating: 0xAB, count: 32)),
            routable: DemandSurveyPreviewRoutable(),
            responsesService: DemandSurveyPreviewResponsesService()
        ))
    }
}

private final class DemandSurveyPreviewRoutable: DemandSurveyRoutable {
    func demandSurveyDidSubmit() {}
}

private struct DemandSurveyPreviewResponsesService: InAppSurveyResponsesService {
    func submit(answers: [String: String], surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws {}
    func isCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws -> Bool { false }
}
