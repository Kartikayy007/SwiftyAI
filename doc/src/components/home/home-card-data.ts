export const homeCards = [
  {
    tag: "CORE",
    date: "",
    title: "Generate Text with any LLM provider in one call",
    label: "Text Generation",
    description:
      "Generate text from any LLM provider — streaming or one-shot — with a single native Swift API.",
    href: "/docs/generate-text",
    accent: true,
    snippet: `import SwiftyAI

let model = OpenAICompatibleProvider(
  baseURL: "https://api.openai.com/v1",
  apiKey: "...",
  model: "gpt-4o"
)

let response = try await generateText(
  model: model,
  prompt: "Draft a friendly push notification for a habit tracker."
)

print(response.text)`,
  },
  {
    tag: "MEDIA",
    date: "",
    title: "Generate Images from text prompts natively in Swift",
    label: "Image Generation",
    description:
      "Create images from text prompts using DALL·E or Stable Diffusion — returns a native Swift data object.",
    href: "/docs/image-generation",
    accent: false,
    snippet: `import SwiftyAI

let imageModel = OpenAICompatibleProvider(
  baseURL: "https://api.openai.com/v1",
  apiKey: "...",
  model: "gpt-image-1"
)

let response = try await generateImage(
  model: imageModel,
  prompt: "A clean app icon for a Swift package named SwiftyAI.",
  options: ImageGenerationOptions(size: .square1024, quality: .high)
)

let imageData = response.images.first?.data`,
  },
  {
    tag: "AUDIO",
    date: "",
    title: "Convert Text to Speech with one Swift call",
    label: "Speech",
    description:
      "Turn any string into natural-sounding audio. Choose voice, speed, and format — get back AVAudioPlayer-ready Data.",
    href: "/docs/audio",
    accent: false,
    snippet: `import SwiftyAI

let speechModel = OpenAICompatibleProvider(
  baseURL: "https://api.openai.com/v1",
  apiKey: "...",
  model: "gpt-4o-mini-tts"
)

let speech = try await generateSpeech(
  model: speechModel,
  text: "You can build and host many different types of applic...",
  options: SpeechOptions(voice: "alloy", format: .mp3)
)

try speech.data.write(to: outputURL)`,
  },
  {
    tag: "AUDIO",
    date: "",
    title: "Transcribe Audio to Text with Whisper",
    label: "Transcription",
    description:
      "Convert recorded or streamed audio into accurate text using Provider supported models — works with any AVAudioFile or Data.",
    href: "/docs/audio",
    accent: false,
    snippet: `import SwiftyAI

let transcriptionModel = OpenAICompatibleProvider(
  baseURL: "https://api.openai.com/v1",
  apiKey: "...",
  model: "gpt-4o-transcribe"
)

let audio = AIAudioInput(
  data: audioData,
  filename: "meeting.wav",
  mediaType: .wav
)

let transcript = try await transcribe(
  model: transcriptionModel,
  audio: audio
)

print(transcript.text)`,
  },
] as const;

export type HomeCard = (typeof homeCards)[number];
