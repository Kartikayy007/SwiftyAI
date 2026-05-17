import Image from "next/image";

export function SwiftyLogo() {
  return (
    <div className="flex items-center gap-2 font-semibold">
      <Image
        src="/swiftyAIlogo.png"
        alt="SwiftyAI"
        width={32}
        height={32}
        className="rounded-md"
      />
      <span>SwiftyAI</span>
    </div>
  );
}
