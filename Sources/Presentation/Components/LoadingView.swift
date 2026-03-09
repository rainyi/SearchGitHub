import SwiftUI

/// 로딩 상태 표시 뷰
struct LoadingView: View {
    let message: String

    init(message: String = "로딩 중...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    LoadingView(message: "검색 중...")
}
