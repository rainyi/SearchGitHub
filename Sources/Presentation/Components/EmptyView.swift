import SwiftUI

/// 빈 상태 표시 뷰
struct EmptyView: View {
    let icon: String
    let title: String
    let subtitle: String?

    init(
        icon: String = "magnifyingglass",
        title: String = "검색 결과가 없습니다",
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("With Subtitle") {
    EmptyView(
        icon: "magnifyingglass",
        title: "검색 결과가 없습니다",
        subtitle: "다른 검색어를 입력해보세요"
    )
}

#Preview("Without Subtitle") {
    EmptyView(
        icon: "doc.text",
        title: "내용이 없습니다"
    )
}
