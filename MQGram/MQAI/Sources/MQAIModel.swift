import Foundation

/// AI provider identifier used to route API calls.
public enum MQAIProviderKind: String, Codable, CaseIterable {
    case openAI
    case anthropic
    case google
    case deepSeek
    case xAI

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google"
        case .deepSeek: return "DeepSeek"
        case .xAI: return "xAI"
        }
    }

    /// Environment variable / UserDefaults key used to look up the API key.
    public var apiKeyStorageKey: String {
        switch self {
        case .openAI: return "mqai.apiKey.openai"
        case .anthropic: return "mqai.apiKey.anthropic"
        case .google: return "mqai.apiKey.google"
        case .deepSeek: return "mqai.apiKey.deepseek"
        case .xAI: return "mqai.apiKey.xai"
        }
    }
}

/// A model the user can select from the picker sheet.
public struct MQAIModel: Codable, Equatable, Hashable {
    public let id: String
    public let displayName: String
    public let provider: MQAIProviderKind

    public init(id: String, displayName: String, provider: MQAIProviderKind) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
    }
}

public enum MQAIModelCatalog {
    public static let all: [MQAIModel] = [
        MQAIModel(id: "gpt-5",                  displayName: "GPT-5",                 provider: .openAI),
        MQAIModel(id: "gpt-4o",                 displayName: "GPT-4o",                provider: .openAI),
        MQAIModel(id: "o3",                     displayName: "o3",                    provider: .openAI),
        MQAIModel(id: "gemini-2.5-flash",       displayName: "Gemini 2.5 Flash",      provider: .google),
        MQAIModel(id: "gemini-2.5-flash-lite",  displayName: "Gemini 2.5 Flash-Lite", provider: .google),
        MQAIModel(id: "gemini-2.5-pro",         displayName: "Gemini 2.5 Pro",        provider: .google),
        MQAIModel(id: "claude-3-7-sonnet-latest", displayName: "Claude 3.7 Sonnet",   provider: .anthropic),
        MQAIModel(id: "deepseek-chat",          displayName: "DeepSeek V3",           provider: .deepSeek),
        MQAIModel(id: "deepseek-reasoner",      displayName: "DeepSeek R1",           provider: .deepSeek),
        MQAIModel(id: "grok-4",                 displayName: "Grok 4",                provider: .xAI),
    ]

    public static var `default`: MQAIModel {
        // Match the screenshot's default selection.
        return all.first(where: { $0.id == "gemini-2.5-flash-lite" }) ?? all[0]
    }

    public static func model(for id: String) -> MQAIModel? {
        return all.first(where: { $0.id == id })
    }
}

public struct MQAIChatMessage: Codable, Equatable {
    public enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    public var id: UUID
    public var role: Role
    public var content: String
    public var date: Date

    public init(id: UUID = UUID(), role: Role, content: String, date: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.date = date
    }
}

public struct MQAIChatSession: Codable, Equatable {
    public var id: UUID
    public var title: String
    public var modelId: String
    public var messages: [MQAIChatMessage]
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "New chat",
        modelId: String,
        messages: [MQAIChatMessage] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.modelId = modelId
        self.messages = messages
        self.updatedAt = updatedAt
    }
}
