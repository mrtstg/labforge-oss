<script lang="ts">
  import NoVnc from "./lib/NoVNC.svelte";

  let vmPort: string | null = null
  const parsedURL = new URL(document.URL)
  const vmPortMatch = parsedURL.pathname.match("\/vnc\/(.*)")

  if (vmPortMatch != null && vmPortMatch.length > 1) {
    vmPort = vmPortMatch[1]
  }

  const host = window.location.hostname;
  //const port = window.location.protocol == "https:" ? "443" : "80";
  const proto = window.location.protocol == "https:" ? "wss" : "ws";
  const url = proto + "://" + host + "/api/vm/" + vmPort + "/vnc";
</script>

{#if vmPort != null}
  <NoVnc
    url={url}
  />
{/if}
