{{flutter_js}}
{{flutter_build_config}}

// Global error monitoring system
function showErrorUI(message) {
  const errorDiv = document.createElement('div');
  errorDiv.style.cssText = 'position:fixed;top:0;left:0;width:100%;max-height:50vh;overflow-y:auto;background:#d32f2f;color:#ffffff;padding:16px;box-sizing:border-box;font-family:monospace;font-size:14px;z-index:9999999;word-break:break-all;box-shadow:0 4px 10px rgba(0,0,0,0.3);';
  errorDiv.innerHTML = '<strong>[Runtime Error]</strong><br/>' + String(message);
  document.body.appendChild(errorDiv);
}

window.addEventListener('error', function(e) {
  showErrorUI(e.message || e.error || 'Unknown Window Error');
});

window.addEventListener('unhandledrejection', function(e) {
  showErrorUI(e.reason ? (e.reason.message || e.reason) : 'Unhandled Promise Rejection');
});

// Create and display loading indicator
const loadingDiv = document.createElement('div');
loadingDiv.id = 'loading';
loadingDiv.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;display:flex;justify-content:center;align-items:center;background-color:#ffffff;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;font-size:18px;color:#333333;z-index:999999;';
loadingDiv.textContent = 'Lade Berichtsheft App...';
document.body.appendChild(loadingDiv);

_flutter.loader.load({
  config: {
    forceSingleThreadedSkwasm: true,
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
