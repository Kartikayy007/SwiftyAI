import { DocsShell } from "@/components/docs/docs-shell";
import { pageSections } from "@/components/docs/docs-config";

export default function DocsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <DocsShell>
      <main className="grid min-h-[calc(100vh-3.5rem)] grid-cols-1 xl:grid-cols-[minmax(0,1fr)_240px]">
        <article className="min-w-0 px-5 py-8 md:px-10 lg:px-12">
          <div className="docs-content mx-auto max-w-3xl">{children}</div>
        </article>

        <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] border-l px-6 py-8 xl:block">
          <p className="text-sm font-medium">On this page</p>
          <nav className="mt-4 space-y-2 text-sm text-muted-foreground">
            {pageSections.map((section) => (
              <a
                key={section}
                href={`#${section.toLowerCase().replaceAll(" ", "-")}`}
                className="block transition-colors hover:text-foreground"
              >
                {section}
              </a>
            ))}
          </nav>
        </aside>
      </main>
    </DocsShell>
  );
}
