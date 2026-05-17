"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, FileText, Search } from "lucide-react";
import { docsNavGroups } from "@/components/docs/docs-config";
import { Button } from "@/components/ui/button";
import {
  Command,
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import { cn } from "@/lib/utils";

function useModKeyLabel() {
  const [label, setLabel] = React.useState("⌘");

  React.useEffect(() => {
    const isMac =
      typeof navigator !== "undefined" &&
      /Mac|iPhone|iPad|iPod/.test(navigator.platform);
    setLabel(isMac ? "⌘" : "Ctrl");
  }, []);

  return label;
}

export function DocsSearch() {
  const [open, setOpen] = React.useState(false);
  const router = useRouter();
  const modKey = useModKeyLabel();

  React.useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "k" && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        setOpen((current) => !current);
      }
    };

    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, []);

  const navigate = React.useCallback(
    (href: string) => {
      setOpen(false);
      router.push(href);
    },
    [router]
  );

  return (
    <>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        className="shrink-0 md:hidden"
        aria-label="Search docs"
        onClick={() => setOpen(true)}
      >
        <Search className="h-4 w-4" />
      </Button>

      <Button
        type="button"
        variant="outline"
        onClick={() => setOpen(true)}
        className={cn(
          "hidden h-9 w-44 shrink-0 justify-between gap-2 px-3 text-muted-foreground md:flex lg:w-56",
          "border-foreground/20 bg-muted/20 shadow-none hover:bg-muted/40"
        )}
      >
        <span className="flex min-w-0 items-center gap-2">
          <Search className="h-4 w-4 shrink-0 opacity-60" />
          <span className="truncate text-sm">Search docs…</span>
        </span>
        <kbd className="pointer-events-none hidden h-5 shrink-0 items-center gap-0.5 rounded border border-foreground/15 bg-background/80 px-1.5 font-mono text-[10px] font-medium text-muted-foreground lg:inline-flex">
          <span>{modKey}</span>
          <span>K</span>
        </kbd>
      </Button>

      <CommandDialog
        open={open}
        onOpenChange={setOpen}
        title="Search documentation"
        description="Find a docs page by title or section"
        className="gap-0 overflow-hidden p-0 sm:max-w-xl"
        showCloseButton
      >
        <Command className="rounded-none bg-transparent p-0">
          <CommandInput placeholder="Search pages, topics, or paths…" />
          <CommandList className="max-h-[min(65vh,28rem)]">
            <CommandEmpty className="text-muted-foreground">
              No matching docs pages.
            </CommandEmpty>
            {docsNavGroups.map((group, index) => (
              <React.Fragment key={group.title}>
                {index > 0 ? <CommandSeparator className="mx-2" /> : null}
                <CommandGroup heading={group.title}>
                  {group.items.map((item) => (
                    <CommandItem
                      key={item.href}
                      value={`${item.title} ${group.title} ${item.href}`}
                      onSelect={() => navigate(item.href)}
                      className="mx-1 gap-3 rounded-md py-2.5"
                    >
                      <FileText className="size-4 shrink-0 text-muted-foreground" />
                      <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                        <span className="truncate font-medium">{item.title}</span>
                        <span className="truncate text-xs text-muted-foreground">
                          {group.title}
                        </span>
                      </div>
                      <ArrowRight className="size-3.5 shrink-0 opacity-0 transition-opacity group-data-selected/command-item:opacity-60" />
                    </CommandItem>
                  ))}
                </CommandGroup>
              </React.Fragment>
            ))}
          </CommandList>
          <div className="flex items-center justify-between gap-4 border-t border-foreground/10 bg-muted/30 px-3 py-2.5 text-[11px] text-muted-foreground">
            <span className="hidden sm:inline">Jump to any docs page</span>
            <div className="ml-auto flex items-center gap-3">
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-foreground/15 bg-background px-1 font-mono text-[10px]">
                  ↑↓
                </kbd>
                navigate
              </span>
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-foreground/15 bg-background px-1 font-mono text-[10px]">
                  ↵
                </kbd>
                open
              </span>
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-foreground/15 bg-background px-1 font-mono text-[10px]">
                  esc
                </kbd>
                close
              </span>
            </div>
          </div>
        </Command>
      </CommandDialog>
    </>
  );
}
