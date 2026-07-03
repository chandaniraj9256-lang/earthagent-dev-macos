import Foundation

enum VoiceProviderCatalog {
    static let providers: [VoiceProviderProfile] = [
        VoiceProviderProfile(
            id: "macos",
            name: "macOS System Voice",
            baseURL: "",
            defaultModel: "system",
            defaultVoice: "system-default",
            models: ["system"],
            voices: ["system-default"],
            notes: "No API key required. Uses Apple's built-in speech synthesizer.",
            status: .working
        ),
        VoiceProviderProfile(
            id: "elevenlabs",
            name: "ElevenLabs",
            baseURL: "https://api.elevenlabs.io/v1",
            defaultModel: "eleven_multilingual_v2",
            defaultVoice: "JBFqnCBsd6RMkjVDRZzb",
            models: ["eleven_multilingual_v2", "eleven_turbo_v2_5", "eleven_flash_v2_5"],
            voices: ["JBFqnCBsd6RMkjVDRZzb", "21m00Tcm4TlvDq8ikWAM", "EXAVITQu4vr4xnSDxMaL"],
            notes: "Working TTS integration. Paste an ElevenLabs API key and voice ID.",
            status: .working
        ),
        VoiceProviderProfile(
            id: "openai",
            name: "OpenAI TTS",
            baseURL: "https://api.openai.com/v1",
            defaultModel: "gpt-4o-mini-tts",
            defaultVoice: "alloy",
            models: ["gpt-4o-mini-tts", "tts-1", "tts-1-hd"],
            voices: ["alloy", "ash", "ballad", "coral", "echo", "fable", "nova", "onyx", "sage", "shimmer", "verse"],
            notes: "Working OpenAI speech endpoint integration.",
            status: .working
        ),
        VoiceProviderProfile(
            id: "cartesia",
            name: "Cartesia",
            baseURL: "https://api.cartesia.ai",
            defaultModel: "sonic-2",
            defaultVoice: "paste-voice-id",
            models: ["sonic-2", "sonic"],
            voices: ["paste-voice-id"],
            notes: "Planned provider. API key settings are ready; playback wiring will be provider-specific.",
            status: .planned
        ),
        VoiceProviderProfile(
            id: "playht",
            name: "PlayHT",
            baseURL: "https://api.play.ht/api/v2",
            defaultModel: "PlayDialog",
            defaultVoice: "paste-voice-id",
            models: ["PlayDialog", "Play3.0-mini", "PlayHT2.0"],
            voices: ["paste-voice-id"],
            notes: "Planned provider. Needs PlayHT-specific user ID/header handling before enabling playback.",
            status: .planned
        ),
        VoiceProviderProfile(
            id: "azure",
            name: "Azure AI Speech",
            baseURL: "https://REGION.tts.speech.microsoft.com",
            defaultModel: "neural",
            defaultVoice: "en-US-JennyNeural",
            models: ["neural"],
            voices: ["en-US-JennyNeural", "en-US-GuyNeural", "en-US-AriaNeural"],
            notes: "Planned provider. Requires region-specific endpoint and Azure header handling.",
            status: .planned
        ),
        VoiceProviderProfile(
            id: "custom",
            name: "Custom / Local TTS",
            baseURL: "http://localhost:8880/v1",
            defaultModel: "local-tts",
            defaultVoice: "local-voice",
            models: ["local-tts"],
            voices: ["local-voice"],
            notes: "Planned provider for local gateways. Use macOS, ElevenLabs, or OpenAI for working playback now.",
            status: .planned
        )
    ]

    static func provider(id: String) -> VoiceProviderProfile {
        providers.first { $0.id == id } ?? providers[0]
    }
}
