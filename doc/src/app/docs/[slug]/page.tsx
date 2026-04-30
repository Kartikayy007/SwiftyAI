import { notFound } from "next/navigation";
import { DocsPage } from "@/components/docs/docs-page";
import { docsBySlug, isDocSlug, type DocSlug } from "@/content/docs";

type DocsSlugPageProps = {
  params: Promise<{
    slug: string;
  }>;
};

export function generateStaticParams() {
  return (Object.keys(docsBySlug) as DocSlug[])
    .filter((slug) => slug !== "overview")
    .map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: DocsSlugPageProps) {
  const { slug } = await params;

  if (!isDocSlug(slug)) {
    return {};
  }

  const doc = docsBySlug[slug];

  if (!doc) {
    return {};
  }

  return {
    title: `${doc.title} - SwiftyAI Docs`,
  };
}

export default async function DocsSlugPage({ params }: DocsSlugPageProps) {
  const { slug } = await params;

  if (!isDocSlug(slug)) {
    notFound();
  }

  return <DocsPage slug={slug} />;
}
