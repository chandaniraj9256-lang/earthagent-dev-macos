import Foundation

struct ProviderProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let baseURL: String
    let defaultModel: String
    let fallbackModels: [String]
    let notes: String

    static let custom = ProviderProfile(
        id: "custom",
        name: "Custom OpenAI-compatible",
        baseURL: "http://localhost:1234/v1",
        defaultModel: "local-model",
        fallbackModels: ["local-model"],
        notes: "Use this for LM Studio, Ollama gateways, vLLM, LiteLLM, or any OpenAI-compatible API."
    )
}
