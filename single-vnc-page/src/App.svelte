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

  let errorsRow = 0;
  let exceptionsRow = 0;
  setInterval(() => {
    if (errorsRow == 5) {
      window.location.reload()
    }
    if (exceptionsRow == 10) {
      window.location.reload()
    }
    if (vmPort != null) {
      fetch("/api/deployment/vmport/access", { headers: { "X-VM-PORT": vmPort } }).then(resp => {
        if (resp.status >= 200 && resp.status <= 300) {
          errorsRow = 0;
        } else if (resp.status >= 400 && resp.status < 500) {
          errorsRow++;
        } else if (resp.status >= 500) {
          exceptionsRow++;
        }
      })
    }
  }, 5000)
</script>

{#if vmPort != null}
  <NoVnc
    url={url}
  />
{/if}
