import Link from "next/link";
import type { ReactNode } from "react";

function SummaryDoc({
  title,
  href,
  children,
}: {
  title: string;
  href: string;
  children: ReactNode;
}) {
  return (
    <>
      <h1>{title}</h1>
      <p>{children}</p>
      <p>
        Open the canonical guide at <Link href={href}>{href}</Link>.
      </p>
    </>
  );
}

function doc(title: string, href: string, summary: string) {
  return {
    title,
    content: () => (
      <SummaryDoc title={title} href={href}>
        {summary}
      </SummaryDoc>
    ),
  };
}

export const docsBySlug = {
  overview: doc("Overview", "/docs", "SwiftyAI is a Swift SDK for text, streaming, tools, objects, providers, SwiftUI state, MCP, and telemetry."),
  "generate-text": doc("Generate Text", "/docs/generate-text", "Use generateText for complete model responses with optional usage and finish metadata."),
  "stream-text": doc("Stream Text", "/docs/stream-text", "Use streamText when UI should update as chunks arrive."),
  tools: doc("Tools", "/docs/tools", "Define typed or dynamic tools that models can call during agent loops."),
  "generate-object": doc("Generate Object", "/docs/generate-object", "Decode model output into validated Swift objects."),
  "provider-registry": doc("Provider Registry", "/docs/provider-registry", "Resolve local custom provider model strings without global state."),
  "swiftui-hooks": doc("SwiftUI Hooks", "/docs/swiftui-hooks", "Use AIChat and AICompletion for observable SwiftUI state."),
  mcp: doc("MCP", "/docs/mcp", "Connect to MCP servers through a small transport-based client."),
  telemetry: doc("Telemetry", "/docs/telemetry", "Record latency, usage, finish reasons, and failures explicitly."),
} as const;

export type DocSlug = keyof typeof docsBySlug;

export function isDocSlug(slug: string): slug is DocSlug {
  return slug in docsBySlug;
}
