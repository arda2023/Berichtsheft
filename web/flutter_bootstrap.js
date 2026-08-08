{{flutter_js}}
{{flutter_build_config}}

// Create and display loading indicator
const loadingDiv = document.createElement('div');
loadingDiv.id = 'loading';
loadingDiv.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;display:flex;justify-content:center;align-items:center;background-color:#ffffff;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;font-size:18px;color:#333333;z-index:999999;';
loadingDiv.textContent = 'Lade Berichtsheft App...';
document.body.appendChild(loadingDiv);

// Heuristics to detect iOS/iPadOS and Safari browser
const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
  (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
const isAppleDeviceOrSafari = isIOS || isSafari;

_flutter.loader.load({
  config: {
    forceSingleThreadedSkwasm: true,
    canvasKitForceCpuOnly: isAppleDeviceOrSafari,
    canvasKitMaximumSurfaces: 8,
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    if (loadingDiv && loadingDiv.parentNode) {
      loadingDiv.parentNode.removeChild(loadingDiv);
    }
  }
});
