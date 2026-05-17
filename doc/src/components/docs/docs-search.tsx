"use client";

import * as React from "react";
import Link from "next/link";
import { Search } from "lucide-react";
import { docsNavGroups } from "@/components/docs/docs-config";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";

const docs = docsNavGroups.flatMap((group) =>
  group.items.map((item) => ({
    ...item,
    group: group.title,
  }))
);

export function DocsSearch() {
  const [open, setOpen] = React.useState(false);
  const [query, setQuery] = React.useState("");

  const results = React.useMemo(() => {
    const normalized = query.trim().toLowerCase();

    if (!normalized) {
      return docs;
    }

    return docs.filter((item) => {
      const haystack = `${item.title} ${item.group} ${item.href}`.toLowerCase();
      return haystack.includes(normalized);
    });
  }, [query]);

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          <Button
            variant="outline"
            className="hidden h-9 w-52 justify-start gap-2 text-muted-foreground md:flex"
          />
        }
      >
        <Search className="h-4 w-4" />
        Search docs
      </SheetTrigger>
      <SheetContent side="right" className="w-full p-0 sm:max-w-md">
        <SheetHeader className="border-b px-4 py-4 text-left">
          <SheetTitle>Search docs</SheetTitle>
        </SheetHeader>
        <div className="p-4">
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search SwiftyAI docs"
            autoFocus
          />
        </div>
        <ScrollArea className="h-[calc(100vh-8.5rem)]">
          <div className="space-y-2 px-4 pb-6">
            {results.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className="block rounded-lg border p-3 transition-colors hover:bg-muted"
                >
                  <span className="font-medium">{item.title}</span>
                  <Badge variant="secondary" className="mt-2">
                    {item.group}
                  </Badge>
                </Link>
            ))}
            {results.length === 0 && (
              <p className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
                No matching docs pages.
              </p>
            )}
          </div>
        </ScrollArea>
      </SheetContent>
    </Sheet>
  );
}
