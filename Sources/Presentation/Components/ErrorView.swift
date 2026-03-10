import SwiftUI

/// 에러 상태 표시 뷰
struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(
        message: String = "오류가 발생했습니다",
        retryAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button {
                    retryAction()
                } label: {
                    Text("다시 시도")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview("With Retry") {
    ErrorView(message: "네트워크 오류") {
        print("Retry tapped")
    }
}

#Preview("Without Retry") {
    ErrorView(message: "데이터를 불러올 수 없습니다")
}
