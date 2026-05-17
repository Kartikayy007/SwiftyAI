import type { ReactNode } from "react";
import { DocsShell } from "@/components/docs/docs-shell";
import { DocsOnThisPage } from "@/components/docs/docs-on-this-page";
import { sectionPaddingX } from "@/lib/layout-tokens";
import { cn } from "@/lib/utils";

export default function DocsLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <DocsShell>
      <main className="min-h-[calc(100vh-3.5rem)]">
        <div className={cn("flex gap-10 py-8", sectionPaddingX)}>
          <article className="min-w-0 flex-1">
            <div className="docs-content mx-auto max-w-3xl">{children}</div>
          </article>
          <DocsOnThisPage />
        </div>
      </main>
    </DocsShell>
  );
}
