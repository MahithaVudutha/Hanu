import Foundation

final class LocalCacheService {
    static let shared = LocalCacheService()

    private func url(for source: ScriptureSource) -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return dir?.appendingPathComponent("scriptures_\(source.rawValue).json")
    }

    func saveScriptures(_ scriptures: [Scripture], for source: ScriptureSource) {
        guard let url = url(for: source) else { return }
        do {
            let data = try JSONEncoder().encode(scriptures)
            try data.write(to: url, options: .atomic)
        } catch { }
    }

    func loadScriptures(for source: ScriptureSource) -> [Scripture] {
        guard let url = url(for: source), let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Scripture].self, from: data)) ?? []
    }
}

