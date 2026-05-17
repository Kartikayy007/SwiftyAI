export const homeCards = [
  {
    tag: "FEATURED",
    date: "MAY 17, 2026",
    title: "SwiftyAI 1.0 — Native AI for Every Apple Platform",
    label: "SwiftyAI 1.0",
    description:
      "Native AI SDK for every Apple platform — streaming, tool calling, and multimodal from one Swift API.",
    href: "/docs/quickstart",
    accent: true,
  },
  {
    tag: "GUIDE",
    date: "MAY 12, 2026",
    title: "Stream Text in Real-Time with AsyncSequence",
    label: "Stream Text",
    description:
      "Wire model output into SwiftUI with AsyncSequence — token-by-token updates without blocking the main thread.",
    href: "/docs/stream-text",
    accent: false,
  },
  {
    tag: "GUIDE",
    date: "MAY 5, 2026",
    title: "Tool Calling — Let the Model Drive Your Swift Functions",
    label: "Tool Calling",
    description:
      "Expose Swift functions as tools so the model can call your app logic safely and predictably.",
    href: "/docs/tool-calling",
    accent: false,
  },
  {
    tag: "GUIDE",
    date: "APR 28, 2026",
    title: "SwiftUI Hooks for Reactive AI State",
    label: "SwiftUI Hooks",
    description:
      "Reactive hooks for generation state, errors, and streaming text — built for SwiftUI observation.",
    href: "/docs/swiftui-hooks",
    accent: false,
  },
] as const;

export type HomeCard = (typeof homeCards)[number];
