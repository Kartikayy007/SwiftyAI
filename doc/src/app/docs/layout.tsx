import type { ReactNode } from "react";
import { DocsShell } from "@/components/docs/docs-shell";

export default function DocsLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <DocsShell>
      <main className="min-h-[calc(100vh-3.5rem)]">
        <article className="min-w-0 px-5 py-8 md:px-10 lg:px-12">
          <div className="docs-content mx-auto max-w-3xl">{children}</div>
        </article>
      </main>
    </DocsShell>
  );
}
