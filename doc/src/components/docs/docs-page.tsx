import { notFound } from "next/navigation";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { pageSections } from "@/components/docs/docs-config";
import { docsBySlug, isDocSlug } from "@/content/docs";

export function DocsPage({ slug }: { slug: string }) {
  if (!isDocSlug(slug)) {
    notFound();
  }

  const doc = docsBySlug[slug];

  if (!doc) {
    notFound();
  }

  const Content = doc.content;

  return (
    <main className="grid min-h-[calc(100vh-3.5rem)] grid-cols-1 xl:grid-cols-[minmax(0,1fr)_240px]">
      <article className="min-w-0 px-5 py-8 md:px-10 lg:px-12">
        <div className="mx-auto max-w-3xl">
          <Breadcrumb className="mb-8">
            <BreadcrumbList>
              <BreadcrumbItem>
                <BreadcrumbLink href="/docs">Docs</BreadcrumbLink>
              </BreadcrumbItem>
              <BreadcrumbSeparator />
              <BreadcrumbItem>
                <BreadcrumbPage>{doc.title}</BreadcrumbPage>
              </BreadcrumbItem>
            </BreadcrumbList>
          </Breadcrumb>

          <div className="mb-8 space-y-4">
            <Badge variant="outline" className="border-orange-400/50">
              Scaffold
            </Badge>
            <div className="docs-content">
              <Content />
            </div>
          </div>

          <Card className="border-dashed">
            <CardContent className="p-6 text-sm text-muted-foreground">
              This route is ready for SDK documentation content.
            </CardContent>
          </Card>
        </div>
      </article>

      <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] border-l px-6 py-8 xl:block">
        <p className="text-sm font-medium">On this page</p>
        <nav className="mt-4 space-y-2 text-sm text-muted-foreground">
          {pageSections.map((section) => (
            <a
              key={section}
              href={`#${section.toLowerCase()}`}
              className="block transition-colors hover:text-foreground"
            >
              {section}
            </a>
          ))}
        </nav>
      </aside>
    </main>
  );
}
