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
    <main className="min-h-[calc(100vh-3.5rem)]">
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
              Guide
            </Badge>
            <div className="docs-content">
              <Content />
            </div>
          </div>
        </div>
      </article>
    </main>
  );
}
