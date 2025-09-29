<script lang="ts">
  import { onMount } from "svelte";
  import Rfb from "./RFB.svelte";

  let desktopName = ""
  let connected: boolean = false
  let quality: number = 7
  let timeoutId: number | null = null

  let key = {}

  export let getPowerCallback: () => Promise<string | null> = async () => { return null }
  //export let setPowerCallback: () => Promise<ErrorWrapper<VMPowerSwitchErrorKind> | string>

  export let controlPower: boolean = true
  export let showDesktopName: boolean = true
  export let url: string;
  export let onConnectCallback: () => Promise<void> = async () => {}
  export let onDisconnectCallback: () => Promise<void> = async () => {}

  const updateDesktop = (e: CustomEvent<{ name: string }>) => {
    desktopName = e.detail.name;
    document.title = e.detail.name;
  }

  const updateConnect = (state: boolean) => {
    connected = state
  }

  const changeQuality = (delta: number) => {
    if (quality + delta > 0 && quality + delta < 10) {
      quality = quality + delta
    }
  }

  const connectRFB = () => {
    key = {}
  }

  onMount(() => {
    setInterval(() => {
      if (!connected) {
        connectRFB()
      }
    }, 2000)

    return () => {
      if (timeoutId != null) {
        clearInterval(timeoutId)
      }
    }
  })

  let powerPromise: Promise<string | null> | null = null
  if (controlPower) {
    powerPromise = getPowerCallback()
  }
</script>

<div class="vnc-container__wrapper">
  <div class="vnc-container">
    <div class="flex flex-row items-center justify-between text-slate w-full">
      {#if showDesktopName}
        <h3 class="text-xl font-semibold"> { showDesktopName ? (desktopName.length == 0 ? "Виртуальная машина" : desktopName) : "" } - { connected ? "подключено" : "отключено" } </h3>
      {:else}
        <h3 class="font-semibold"> { connected ? "Подключено" : "Отключено" } </h3>
      {/if}
    </div>
    {#key key}
      <Rfb desktopCallback={updateDesktop} connectCallback={updateConnect} url={url} onConnectCallback={onConnectCallback} onDisconnectCallback={onDisconnectCallback}/>
    {/key}
  </div>
</div>
