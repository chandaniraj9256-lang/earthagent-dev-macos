import Foundation

struct ProviderConfiguration: Codable, Equatable {
    var providerID: String?
    var providerName: String
    var modelName: String
    var baseURL: String

    static let empty = ProviderConfiguration(
        providerID: "nvidia",
        providerName: "NVIDIA NIM",
        modelName: "nvidia/llama-3.3-nemotron-super-49b-v1.5",
        baseURL: "https://integrate.api.nvidia.com/v1"
    )
}
