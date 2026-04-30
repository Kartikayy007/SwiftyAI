import Link from "next/link";
import type { ComponentPropsWithoutRef, ReactNode } from "react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type CalloutProps = {
  title?: string;
  children: ReactNode;
};

function Callout({ title = "Note", children }: CalloutProps) {
  return (
    <Card className="my-6 border-orange-400/40 bg-orange-500/5">
      <CardHeader className="pb-3">
        <CardTitle className="text-base">{title}</CardTitle>
      </CardHeader>
      <CardContent className="text-sm text-muted-foreground">
        {children}
      </CardContent>
    </Card>
  );
}

function Step({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <Card className="my-5">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Badge className="bg-[var(--swift-orange)] text-black">Step</Badge>
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

function Related({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <Card className="my-8 border-dashed">
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Related docs</CardTitle>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

export function useMDXComponents(components: Record<string, unknown>) {
  return {
    a: (props: ComponentPropsWithoutRef<"a">) => {
      const href = props.href ?? "";

      if (href.startsWith("/")) {
        return <Link {...props} href={href} />;
      }

      return <a {...props} />;
    },
    Callout,
    Step,
    Related,
    ...components,
  };
}
