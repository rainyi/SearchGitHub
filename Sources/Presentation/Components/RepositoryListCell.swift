import SwiftUI

struct RepositoryListCell: View {
    let repository: GitHubRepository

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with caching (uses URLCache.shared automatically)
            AsyncImage(url: repository.owner.avatarUrl) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                        )

                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(repository.owner.login)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let description = repository.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label("\(repository.stargazersCount)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let language = repository.language {
                        Label(language, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    List {
        RepositoryListCell(repository: .sample)
    }
}
