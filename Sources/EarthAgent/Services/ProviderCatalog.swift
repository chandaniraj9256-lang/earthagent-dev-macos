import Foundation

enum ProviderCatalog {
    static let providers: [ProviderProfile] = [
        ProviderProfile(
            id: "openai",
            name: "OpenAI",
            baseURL: "https://api.openai.com/v1",
            defaultModel: "gpt-4o-mini",
            fallbackModels: ["gpt-4o-mini", "gpt-4o", "gpt-4.1", "gpt-4.1-mini", "o4-mini"],
            notes: "Official OpenAI API."
        ),
        ProviderProfile(
            id: "nvidia",
            name: "NVIDIA NIM",
            baseURL: "https://integrate.api.nvidia.com/v1",
            defaultModel: "nvidia/llama-3.3-nemotron-super-49b-v1.5",
            fallbackModels: [
                "nvidia/nemotron-3-ultra-550b-a55b",
                "nvidia/nemotron-3-super-120b-a12b",
                "nvidia/nemotron-3-nano-30b-a3b",
                "nvidia/nvidia-nemotron-nano-9b-v2",
                "nvidia/llama-3.1-nemotron-ultra-253b-v1",
                "nvidia/llama-3.3-nemotron-super-49b-v1.5",
                "nvidia/llama-3.3-nemotron-super-49b-v1",
                "nvidia/llama-3.1-nemotron-nano-8b-v1",
                "nvidia/llama-3.1-nemotron-nano-4b-v1.1",
                "nvidia/llama-3.1-nemotron-70b-instruct",
                "nvidia/nemotron-mini-4b-instruct",
                "nvidia/nemotron-content-safety-reasoning-4b",
                "nvidia/llama-3.1-nemotron-safety-guard-8b-v3",
                "nvidia/llama-3.1-nemoguard-8b-content-safety",
                "nvidia/llama-3.1-nemoguard-8b-topic-control",
                "meta/llama-3.1-8b-instruct",
                "meta/llama-3.1-70b-instruct",
                "meta/llama-3.3-70b-instruct",
                "meta/llama-3.1-405b-instruct",
                "openai/gpt-oss-120b",
                "openai/gpt-oss-20b",
                "qwen/qwen3-coder-480b-a35b-instruct",
                "qwen/qwen3-5-122b-a10b",
                "qwen/qwen3-next-80b-a3b-instruct",
                "qwen/qwen3-next-80b-a3b-thinking",
                "qwen/qwq-32b",
                "mistralai/mixtral-8x7b-instruct-v0.1",
                "mistralai/mistral-large"
            ],
            notes: "OpenAI-compatible hosted NIM endpoint. Press Models to fetch the live model list for your NVIDIA key."
        ),
        ProviderProfile(
            id: "groq",
            name: "Groq",
            baseURL: "https://api.groq.com/openai/v1",
            defaultModel: "llama-3.1-8b-instant",
            fallbackModels: ["llama-3.1-8b-instant", "llama-3.3-70b-versatile", "openai/gpt-oss-120b", "openai/gpt-oss-20b"],
            notes: "Fast OpenAI-compatible inference."
        ),
        ProviderProfile(
            id: "gemini",
            name: "Google Gemini",
            baseURL: "https://generativelanguage.googleapis.com/v1beta/openai",
            defaultModel: "gemini-2.5-flash",
            fallbackModels: ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash", "gemini-1.5-flash"],
            notes: "Google's OpenAI-compatible Gemini endpoint."
        ),
        ProviderProfile(
            id: "mistral",
            name: "Mistral AI",
            baseURL: "https://api.mistral.ai/v1",
            defaultModel: "mistral-small-latest",
            fallbackModels: ["mistral-small-latest", "mistral-medium-latest", "mistral-large-latest", "codestral-latest"],
            notes: "Mistral chat completions API follows the OpenAI-style request shape."
        ),
        ProviderProfile(
            id: "deepseek",
            name: "DeepSeek",
            baseURL: "https://api.deepseek.com",
            defaultModel: "deepseek-v4-flash",
            fallbackModels: ["deepseek-v4-flash", "deepseek-v4-pro", "deepseek-chat", "deepseek-reasoner"],
            notes: "OpenAI-compatible DeepSeek endpoint."
        ),
        ProviderProfile(
            id: "openrouter",
            name: "OpenRouter",
            baseURL: "https://openrouter.ai/api/v1",
            defaultModel: "openai/gpt-4o-mini",
            fallbackModels: [
                "openai/gpt-4o-mini",
                "openai/gpt-4o",
                "anthropic/claude-3.5-sonnet",
                "google/gemini-2.5-flash",
                "meta-llama/llama-3.3-70b-instruct"
            ],
            notes: "One API for hundreds of models. Refresh models for the full list."
        ),
        ProviderProfile(
            id: "together",
            name: "Together AI",
            baseURL: "https://api.together.xyz/v1",
            defaultModel: "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
            fallbackModels: [
                "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
                "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
                "mistralai/Mixtral-8x7B-Instruct-v0.1"
            ],
            notes: "OpenAI-compatible endpoint for hosted open models."
        ),
        ProviderProfile(
            id: "fireworks",
            name: "Fireworks AI",
            baseURL: "https://api.fireworks.ai/inference/v1",
            defaultModel: "accounts/fireworks/models/llama-v3p1-8b-instruct",
            fallbackModels: [
                "accounts/fireworks/models/llama-v3p1-8b-instruct",
                "accounts/fireworks/models/llama-v3p1-70b-instruct",
                "accounts/fireworks/models/mixtral-8x7b-instruct"
            ],
            notes: "OpenAI-compatible Fireworks inference endpoint."
        ),
        ProviderProfile(
            id: "cerebras",
            name: "Cerebras",
            baseURL: "https://api.cerebras.ai/v1",
            defaultModel: "llama3.1-8b",
            fallbackModels: ["llama3.1-8b", "llama3.1-70b", "qwen-3-coder-480b"],
            notes: "OpenAI-compatible Cerebras inference."
        ),
        ProviderProfile(
            id: "xai",
            name: "xAI",
            baseURL: "https://api.x.ai/v1",
            defaultModel: "grok-3-mini",
            fallbackModels: ["grok-3-mini", "grok-3", "grok-4"],
            notes: "OpenAI-compatible xAI endpoint."
        ),
        ProviderProfile(
            id: "deepinfra",
            name: "DeepInfra",
            baseURL: "https://api.deepinfra.com/v1/openai",
            defaultModel: "meta-llama/Meta-Llama-3.1-8B-Instruct",
            fallbackModels: [
                "meta-llama/Meta-Llama-3.1-8B-Instruct",
                "meta-llama/Meta-Llama-3.1-70B-Instruct",
                "mistralai/Mixtral-8x7B-Instruct-v0.1"
            ],
            notes: "OpenAI-compatible hosted open model endpoint."
        ),
        .custom
    ]

    static func provider(id: String?) -> ProviderProfile {
        providers.first { $0.id == id } ?? providers.first ?? .custom
    }

    static func provider(matchingName name: String) -> ProviderProfile {
        providers.first { $0.name.caseInsensitiveCompare(name) == .orderedSame } ?? .custom
    }
}
