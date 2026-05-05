function PlaceholderDoc({ title }: { title: string }) {
  return (
    <>
      <h1>{title}</h1>
      <p>Docs coming soon.</p>

      <h2 id="overview">Overview</h2>
      <h2 id="api">API</h2>
      <h2 id="example">Example</h2>
      <h2 id="notes">Notes</h2>
    </>
  );
}

function doc(title: string) {
  return {
    title,
    content: () => <PlaceholderDoc title={title} />,
  };
}

export const docsBySlug = {
  overview: doc("Overview"),
  "generate-text": doc("Generate Text"),
  "stream-text": doc("Stream Text"),
  tools: doc("Tools"),
  "generate-object": doc("Generate Object"),
  "provider-registry": doc("Provider Registry"),
  "swiftui-hooks": doc("SwiftUI Hooks"),
  mcp: doc("MCP"),
  telemetry: doc("Telemetry"),
} as const;

export type DocSlug = keyof typeof docsBySlug;

export function isDocSlug(slug: string): slug is DocSlug {
  return slug in docsBySlug;
}
