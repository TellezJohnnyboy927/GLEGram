import Foundation

/// Error returned by an AI provider when a request cannot complete.
public enum MQAIProviderError: LocalizedError {
    case missingAPIKey(MQAIProviderKind)
    case invalidURL
    case http(status: Int, body: String?)
    case decoding(Error)
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case let .missingAPIKey(provider):
            return "API key for \(provider.displayName) is not set. Open AI tab → profile icon → enter API key."
        case .invalidURL:
            return "Provider URL is invalid."
        case let .http(status, body):
            if let body = body, !body.isEmpty {
                return "Provider error (HTTP \(status)): \(body)"
            }
            return "Provider error (HTTP \(status))"
        case let .decoding(error):
            return "Failed to decode provider response: \(error.localizedDescription)"
        case let .underlying(error):
            return error.localizedDescription
        }
    }
}

/// Abstract interface every concrete provider implements.
public protocol MQAIProvider {
    /// Send chat history to the provider and return the assistant's reply text.
    func sendChatCompletion(
        model: MQAIModel,
        messages: [MQAIChatMessage],
        completion: @escaping (Result<String, MQAIProviderError>) -> Void
    )
}

/// Dispatches a chat completion to the correct concrete provider based on
/// the selected model's `provider` field.
public final class MQAIProviderDispatcher {
    public static let shared = MQAIProviderDispatcher()

    private let urlSession: URLSession
    private let storage: MQAIStorage

    public init(urlSession: URLSession = .shared, storage: MQAIStorage = .shared) {
        self.urlSession = urlSession
        self.storage = storage
    }

    public func sendChatCompletion(
        model: MQAIModel,
        messages: [MQAIChatMessage],
        completion: @escaping (Result<String, MQAIProviderError>) -> Void
    ) {
        guard let apiKey = storage.apiKey(for: model.provider) else {
            completion(.failure(.missingAPIKey(model.provider)))
            return
        }

        let provider: MQAIProvider
        switch model.provider {
        case .openAI:
            provider = MQAIOpenAIProvider(apiKey: apiKey, baseURL: URL(string: "https://api.openai.com/v1")!, urlSession: urlSession)
        case .deepSeek:
            provider = MQAIOpenAIProvider(apiKey: apiKey, baseURL: URL(string: "https://api.deepseek.com")!, urlSession: urlSession)
        case .xAI:
            provider = MQAIOpenAIProvider(apiKey: apiKey, baseURL: URL(string: "https://api.x.ai/v1")!, urlSession: urlSession)
        case .anthropic:
            provider = MQAIAnthropicProvider(apiKey: apiKey, urlSession: urlSession)
        case .google:
            provider = MQAIGoogleProvider(apiKey: apiKey, urlSession: urlSession)
        }

        provider.sendChatCompletion(model: model, messages: messages, completion: completion)
    }
}
