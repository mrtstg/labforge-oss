<script lang="ts">
  import RFB from "@novnc/novnc/lib/rfb"
  import { onMount } from "svelte";

  let rfb: RFB | null = null
  let quality: number = 6
  let parent: HTMLElement;

  export let desktopCallback: (e: CustomEvent<{ name: string }>) => void;
  export let connectCallback: (state: boolean) => void
  export let url: string;
  export let onConnectCallback: () => Promise<void> = async () => {}
  export let onDisconnectCallback: () => Promise<void> = async () => {}

  onMount(() => {
    rfb = new RFB(parent, url)
    rfb.compressionLevel = 5
    rfb.qualityLevel = quality
    rfb.viewOnly = false
    rfb.dragViewport = false
    rfb.clipViewport = false
    rfb.scaleViewport = true

    rfb.addEventListener("desktopname", desktopCallback)
    rfb.addEventListener("connect", (_) => { connectCallback(true); onConnectCallback() })
    rfb.addEventListener("disconnect", (_) => { connectCallback(false); onDisconnectCallback() })

    return () => {
      if (rfb != null) {
        rfb.disconnect()
      }
    }
  })

  const sendCAD = () => {
    if (rfb != null) {
      rfb.sendCtrlAltDel()
    }
  }

  function delay(time: any) {
    return new Promise(resolve => setTimeout(resolve, time));
  }

  // taken from https://gist.github.com/byjg/a6378edb420a1c654c5f27bb494ca1c8
  const XK_Shift_L = 65505; // https://docs.rs/x11-dl/1.0.1/x11_dl/keysym/constant.XK_Shift_L.html
  const XK_Return = 65293;
  const sendString = function (shift_state: boolean, str: string[]) {
    var character = str.shift();
    if (character != undefined && rfb != null) {
      var code = character.charCodeAt(0);
      if (code === '\r'.charCodeAt(0)) {
        delay(50).then(_ => { sendString(shift_state, str) })
        return
      }
      if (code === '\n'.charCodeAt(0)) {
        rfb.sendKey(XK_Return, null);
        delay(50).then(_ => { sendString(shift_state, str) })
        return;
      }
      var needs_shift = character.match(/[A-Z!@#$%^&*()_+{}:\"<>?~|]/);
      if (needs_shift) {
        if (!shift_state) {
          rfb.sendKey(XK_Shift_L, null ,true);
          shift_state = true
        }
        delay(50).then(_ => {
          if (rfb != null) {
            rfb.sendKey(code, null);
          }
        })
      } else {
        if (shift_state) {
          rfb.sendKey(XK_Shift_L, null, false)
          shift_state = false
        }
        delay(50).then(_ => {
          if (rfb != null) {
            rfb.sendKey(code, null);
          }
        })
      }
      delay(200).then(_ => { sendString(shift_state, str) })
    }
  }

  const sendBuffer = () => {
    if (clipboard.length > 0 && clipboard.length < 1001) {
        if (rfb != null) {
          sendString(false, clipboard.split(''))
        }
    }
  }

  const sendFromClipboard = () => {
    navigator.clipboard.readText()
      .then(text => {
        if (rfb != null) {
          sendString(false, text.split(''))
        }
      })
      .catch(err => {
        console.error('Failed to read clipboard contents: ', err);
      });
  }

  let clipboard = ''
</script>

<div>
  <div class="flex flex-row items-center w-full">
    <button class="button" on:click={sendCAD}> Ctrl + Alt + Del </button>
    <input class="input" maxlength="1000" type="text" bind:value={clipboard}>
    <button class="button" on:click={sendBuffer}> Вставить </button>
    <button class="button" on:click={sendFromClipboard}> Вставить из буфера </button>
  </div>
  <div class="vnc-screen-container" bind:this={parent}></div>
</div>
