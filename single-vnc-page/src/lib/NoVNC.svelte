<script lang="ts">
  import { onMount } from "svelte";
  import Rfb from "./RFB.svelte";

  let desktopName = ""
  let connected: boolean = false
  let quality: number = 7
  const initialReconnectDelay = 2000
  const maximumReconnectDelay = 30000
  let reconnectDelay = initialReconnectDelay
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null
  let mounted = false

  let key = 0

  export let getPowerCallback: () => Promise<string | null> = async () => { return null }
  //export let setPowerCallback: () => Promise<ErrorWrapper<VMPowerSwitchErrorKind> | string>

  export let controlPower: boolean = true
  export let showDesktopName: boolean = true
  export let showConnectionState: boolean = true
  export let url: string;
  export let onConnectCallback: () => Promise<void> = async () => {}
  export let onDisconnectCallback: () => Promise<void> = async () => {}

  const updateDesktop = (e: CustomEvent<{ name: string }>) => {
    desktopName = e.detail.name;
    document.title = e.detail.name;
  }

  const updateConnect = (state: boolean) => {
    connected = state
    if (state) {
      reconnectDelay = initialReconnectDelay
      clearReconnectTimer()
    } else {
      scheduleReconnect()
    }
  }

  const changeQuality = (delta: number) => {
    if (quality + delta > 0 && quality + delta < 10) {
      quality = quality + delta
    }
  }

  const clearReconnectTimer = () => {
    if (reconnectTimer != null) {
      clearTimeout(reconnectTimer)
      reconnectTimer = null
    }
  }

  // Recreate noVNC only after a real disconnect. Backoff avoids a reconnect
  // storm when the gateway or Proxmox node is unavailable for a longer time.
  const scheduleReconnect = () => {
    if (!mounted || connected || reconnectTimer != null) {
      return
    }
    const delay = reconnectDelay
    reconnectTimer = setTimeout(() => {
      reconnectTimer = null
      if (mounted && !connected) {
        key += 1
        reconnectDelay = Math.min(reconnectDelay * 2, maximumReconnectDelay)
      }
    }, delay)
  }

  onMount(() => {
    mounted = true

    return () => {
      mounted = false
      clearReconnectTimer()
    }
  })

  let powerPromise: Promise<string | null> | null = null
  if (controlPower) {
    powerPromise = getPowerCallback()
  }
</script>

<div class="vnc-container__wrapper">
  <div class="vnc-container">
    {#if showConnectionState}
      <div class="flex flex-row items-center justify-between text-slate w-full">
        {#if showDesktopName}
          <h3 class="text-xl font-semibold"> { showDesktopName ? (desktopName.length == 0 ? "Виртуальная машина" : desktopName) : "" } - { connected ? "подключено" : "отключено" } </h3>
        {:else}
          <h3 class="font-semibold"> { connected ? "Подключено" : "Отключено" } </h3>
        {/if}
      </div>
    {/if}
    {#key key}
      <Rfb desktopCallback={updateDesktop} connectCallback={updateConnect} url={url} onConnectCallback={onConnectCallback} onDisconnectCallback={onDisconnectCallback}/>
    {/key}
  </div>
</div>
