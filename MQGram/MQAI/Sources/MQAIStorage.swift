import Foundation

/// UserDefaults-backed persistence for MQAI: API keys, selected model, chat history.
///
/// Stored in the shared app suite so the data survives upgrades and is
/// available to share extensions if needed later.
public final class MQAIStorage {
    public static let shared = MQAIStorage()

    private let defaults: UserDefaults
    private let sessionsKey = "mqai.sessions.v1"
    private let selectedModelKey = "mqai.selectedModel.v1"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - API keys

    public func apiKey(for provider: MQAIProviderKind) -> String? {
        let value = defaults.string(forKey: provider.apiKeyStorageKey)
        if let value = value, !value.isEmpty {
            return value
        }
        return nil
    }

    public func setApiKey(_ key: String?, for provider: MQAIProviderKind) {
        if let key = key, !key.isEmpty {
            defaults.set(key, forKey: provider.apiKeyStorageKey)
        } else {
            defaults.removeObject(forKey: provider.apiKeyStorageKey)
        }
    }

    // MARK: - Selected model

    public var selectedModel: MQAIModel {
        get {
            if let id = defaults.string(forKey: selectedModelKey),
               let model = MQAIModelCatalog.model(for: id)
            {
                return model
            }
            return MQAIModelCatalog.default
        }
        set {
            defaults.set(newValue.id, forKey: selectedModelKey)
        }
    }

    // MARK: - Sessions / history

    public func loadSessions() -> [MQAIChatSession] {
        guard let data = defaults.data(forKey: sessionsKey) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MQAIChatSession].self, from: data)) ?? []
    }

    public func saveSessions(_ sessions: [MQAIChatSession]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(sessions) {
            defaults.set(data, forKey: sessionsKey)
        }
    }

    public func upsertSession(_ session: MQAIChatSession) {
        var sessions = loadSessions()
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        sessions.sort { $0.updatedAt > $1.updatedAt }
        saveSessions(sessions)
    }

    public func deleteSession(id: UUID) {
        var sessions = loadSessions()
        sessions.removeAll(where: { $0.id == id })
        saveSessions(sessions)
    }
}
