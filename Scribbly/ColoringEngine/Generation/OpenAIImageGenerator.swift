import Foundation

enum ImageGenerationError: LocalizedError {
    case missingAPIKey
    case network(Error)
    case api(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Add your OpenAI API key to Secrets.swift to create pictures."
        case .network(let error): "Couldn't reach the image service: \(error.localizedDescription)"
        case .api(let message): message
        case .decoding: "Got an unexpected response while creating the picture."
        }
    }
}

/// Generates coloring-book line art via OpenAI's image API (DALL-E 3).
enum OpenAIImageGenerator {
    private static let styleGuide = "children's coloring book line art, pure black thick clean outlines, large simple enclosed shapes, no shading, no grayscale, no crosshatching, no filled black areas, no text, centered composition, isolated subject"

    static func generatePage(subject: String) async throws -> Data {
        let key = Secrets.openAIAPIKey
        guard !key.isEmpty else { throw ImageGenerationError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            model: "dall-e-3",
            prompt: "\(subject), \(styleGuide)",
            size: "1024x1024",
            quality: "standard",
            n: 1,
            response_format: "b64_json"
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImageGenerationError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw ImageGenerationError.decoding }
        guard http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error.message
                ?? "The image service returned an error (\(http.statusCode))."
            throw ImageGenerationError.api(message)
        }
        guard let decoded = try? JSONDecoder().decode(ImageResponse.self, from: data),
              let first = decoded.data.first,
              let imageData = Data(base64Encoded: first.b64_json)
        else { throw ImageGenerationError.decoding }
        return imageData
    }

    private struct RequestBody: Encodable {
        let model, prompt, size, quality: String
        let n: Int
        let response_format: String
    }
    private struct ImageResponse: Decodable { let data: [ImageDatum] }
    private struct ImageDatum: Decodable { let b64_json: String }
    private struct ErrorResponse: Decodable { let error: ErrorDetail }
    private struct ErrorDetail: Decodable { let message: String }
}
