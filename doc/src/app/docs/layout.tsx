import type { ReactNode } from "react";
import { DocsShell } from "@/components/docs/docs-shell";
import { DocsOnThisPage } from "@/components/docs/docs-on-this-page";
import { sectionPaddingX } from "@/lib/layout-tokens";
import { cn } from "@/lib/utils";
import { getGitHubStars } from "@/lib/github";

export default async function DocsLayout({
  children,
}: {
  children: ReactNode;
}) {
  const stars = await getGitHubStars();
  return (
    <DocsShell stars={stars}>
      <main className="min-h-[calc(100vh-3.5rem)]">
        <div className={cn("flex flex-col gap-6 py-6 sm:gap-8 sm:py-8 lg:flex-row lg:gap-10", sectionPaddingX)}>
          <article className="min-w-0 flex-1">
            <div className="docs-content mx-auto max-w-3xl">{children}</div>
          </article>
          <DocsOnThisPage />
        </div>
      </main>
    </DocsShell>
  );
}
