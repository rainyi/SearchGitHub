import Foundation

/// 앱의 네비게이션 경로를 정의하는 enum
enum AppRoute: Hashable {
    /// 저장소 상세 WebView
    case repositoryDetail(url: URL)
}
