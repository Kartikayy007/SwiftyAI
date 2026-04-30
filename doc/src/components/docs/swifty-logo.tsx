import { Sparkles } from "lucide-react";

export function SwiftyLogo() {
  return (
    <div className="flex items-center gap-2 font-semibold">
      <div className="flex h-8 w-8 items-center justify-center rounded-md bg-[var(--swift-orange)] text-black shadow-sm">
        <Sparkles className="h-4 w-4" />
      </div>
      <span>SwiftyAI</span>
    </div>
  );
}
