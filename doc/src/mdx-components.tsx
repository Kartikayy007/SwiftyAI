import Link from "next/link";
import {
  isValidElement,
  type ComponentPropsWithoutRef,
  type ReactNode,
} from "react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { CopyCodeButton } from "@/components/docs/copy-code-button";

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

function getText(node: ReactNode): string {
  if (typeof node === "string" || typeof node === "number") {
    return String(node);
  }

  if (Array.isArray(node)) {
    return node.map(getText).join("");
  }

  if (isValidElement<{ children?: ReactNode }>(node)) {
    return getText(node.props.children);
  }

  return "";
}

function CodeBlock(props: ComponentPropsWithoutRef<"pre">) {
  const code = getText(props.children).trimEnd();

  return (
    <div className="group relative">
      <CopyCodeButton code={code} />
      <pre {...props} />
    </div>
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
    pre: CodeBlock,
    Callout,
    Step,
    Related,
    ...components,
  };
}
