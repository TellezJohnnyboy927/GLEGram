import Foundation

/// Google Gemini provider (`v1beta/models/<id>:generateContent`).
public final class MQAIGoogleProvider: MQAIProvider {
    private let apiKey: String
    private let urlSession: URLSession

    public init(apiKey: String, urlSession: URLSession) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    public func sendChatCompletion(
        model: MQAIModel,
        messages: [MQAIChatMessage],
        completion: @escaping (Result<String, MQAIProviderError>) -> Void
    ) {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model.id):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Gemini uses `contents` with role: "user" / "model"; system instructions
        // are passed separately. Merge any system messages into systemInstruction.
        let systemMessages = messages.filter { $0.role == .system }
        let nonSystem = messages.filter { $0.role != .system }
        let systemPrompt = systemMessages.map(\.content).joined(separator: "\n\n")

        var payload: [String: Any] = [
            "contents": nonSystem.map { msg -> [String: Any] in
                let role = (msg.role == .assistant) ? "model" : "user"
                return [
                    "role": role,
                    "parts": [["text": msg.content]],
                ]
            },
        ]
        if !systemPrompt.isEmpty {
            payload["systemInstruction"] = [
                "parts": [["text": systemPrompt]],
            ]
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
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let first = candidates.first,
                   let content = first["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String
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
