import Foundation

/// Anthropic Messages API (`POST /v1/messages`).
public final class MQAIAnthropicProvider: MQAIProvider {
    private let apiKey: String
    private let urlSession: URLSession
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    public init(apiKey: String, urlSession: URLSession) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    public func sendChatCompletion(
        model: MQAIModel,
        messages: [MQAIChatMessage],
        completion: @escaping (Result<String, MQAIProviderError>) -> Void
    ) {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Anthropic expects a separate `system` field and the remaining messages
        // alternating between `user` and `assistant`.
        let systemMessages = messages.filter { $0.role == .system }
        let nonSystem = messages.filter { $0.role != .system }
        let systemPrompt = systemMessages.map(\.content).joined(separator: "\n\n")

        var payload: [String: Any] = [
            "model": model.id,
            "max_tokens": 1024,
            "messages": nonSystem.map { msg -> [String: Any] in
                let role: String
                switch msg.role {
                case .user: role = "user"
                case .assistant: role = "assistant"
                case .system: role = "user"
                }
                return [
                    "role": role,
                    "content": msg.content,
                ]
            },
        ]
        if !systemPrompt.isEmpty {
            payload["system"] = systemPrompt
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(.underlying(error)))
            return
        }

        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.underlying(error)))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.http(status: -1, body: nil)))
                return
            }
            let body = data.flatMap { String(data: $0, encoding: .utf8) }
            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(.http(status: http.statusCode, body: body)))
                return
            }
            guard let data = data else {
                completion(.failure(.http(status: http.statusCode, body: nil)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let content = json?["content"] as? [[String: Any]],
                   let first = content.first,
                   let text = first["text"] as? String
                {
                    completion(.success(text))
                    return
                }
                completion(.failure(.http(status: http.statusCode, body: body)))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }
}
