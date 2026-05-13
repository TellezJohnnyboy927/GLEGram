import Foundation

/// Provider that targets any OpenAI-Chat-Completions compatible endpoint.
///
/// Used for OpenAI itself, DeepSeek (`api.deepseek.com`) and xAI (`api.x.ai/v1`).
public final class MQAIOpenAIProvider: MQAIProvider {
    private let apiKey: String
    private let baseURL: URL
    private let urlSession: URLSession

    public init(apiKey: String, baseURL: URL, urlSession: URLSession) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    public func sendChatCompletion(
        model: MQAIModel,
        messages: [MQAIChatMessage],
        completion: @escaping (Result<String, MQAIProviderError>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model.id,
            "messages": messages.map { msg -> [String: String] in
                return [
                    "role": msg.role.rawValue,
                    "content": msg.content,
                ]
            },
        ]
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
                if let choices = json?["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let message = first["message"] as? [String: Any],
                   let content = message["content"] as? String
                {
                    completion(.success(content))
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
