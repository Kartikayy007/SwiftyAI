import { HomePageShell } from "@/components/home/home-page-shell";
import { getGitHubStars } from "@/lib/github";

export default async function HomePage() {
  const stars = await getGitHubStars();
  return <HomePageShell stars={stars} />;
}
