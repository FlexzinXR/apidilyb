import Foundation

public enum KeyValidationError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidRequest
    case invalidKey(message: String?)
    case unauthorized(message: String?)
    case server(statusCode: Int, message: String?)
    case invalidResponse
    case transport(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "La URL de validación no es válida."
        case .invalidRequest: return "La solicitud de validación no es válida."
        case .invalidKey(let message): return message ?? "La clave no es válida."
        case .unauthorized(let message): return message ?? "La solicitud no está autorizada."
        case .server(let statusCode, let message): return message ?? "El servidor respondió con HTTP \(statusCode)."
        case .invalidResponse: return "La respuesta del servidor no tiene un formato válido."
        case .transport(let underlying): return underlying.localizedDescription
        }
    }
}

public struct KeyValidationResult: Sendable {
    public let ok: Bool
    public let code: String?
    public let message: String?
    public let rawJSON: Data

    public init(ok: Bool, code: String?, message: String?, rawJSON: Data) {
        self.ok = ok
        self.code = code
        self.message = message
        self.rawJSON = rawJSON
    }
}

public final class KeyValidator: Sendable {
    public static let defaultEndpoint = URL(string: "https://shizukuapi-cjxbkcbz.manus.space/api/v1/keys/validate")!

    private let endpoint: URL
    private let session: URLSession

    public init(endpoint: URL = KeyValidator.defaultEndpoint, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    /// Valida una clave contra la API. `deviceId` debe ser generado y administrado por la app.
    public func validate(key: String, deviceId: String) async throws -> KeyValidationResult {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !deviceId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw KeyValidationError.invalidRequest
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(RequestBody(key: key, deviceId: deviceId))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw KeyValidationError.transport(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw KeyValidationError.invalidResponse
        }

        let payload = try? JSONDecoder().decode(ResponseBody.self, from: data)
        let message = payload?.message
        let code = payload?.code

        switch http.statusCode {
        case 200...299:
            guard let payload else { throw KeyValidationError.invalidResponse }
            return KeyValidationResult(ok: payload.ok, code: code, message: message, rawJSON: data)
        case 400:
            throw KeyValidationError.invalidRequest
        case 401, 403:
            throw KeyValidationError.unauthorized(message: message)
        case 404:
            throw KeyValidationError.invalidKey(message: message)
        default:
            throw KeyValidationError.server(statusCode: http.statusCode, message: message)
        }
    }

    private struct RequestBody: Encodable {
        let key: String
        let deviceId: String
    }

    private struct ResponseBody: Decodable {
        let ok: Bool
        let code: String?
        let message: String?
    }
}
