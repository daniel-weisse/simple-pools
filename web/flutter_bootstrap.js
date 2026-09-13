{{flutter_js}}
{{flutter_build_config}}

async function prepareOfflineWorker() {
  if (!('serviceWorker' in navigator)) return false;
  const controlledOnLoad = navigator.serviceWorker.controller !== null;
  try {
    const registration = await navigator.serviceWorker.register(
      new URL('service-worker.js', document.baseURI), {updateViaCache: 'none'});
    // On hosts without COOP/COEP headers, let our worker supply them before
    // opening SQLite. A controlled page never reloads here, preventing loops
    // in browsers that cannot establish isolation through a service worker.
    if (window.crossOriginIsolated || controlledOnLoad) return false;
    await new Promise((resolve, reject) => {
      const worker = registration.installing || registration.waiting;
      const timeout = setTimeout(() => finish(new Error('Offline worker activation timed out')), 60000);
      function finish(error) {
        clearTimeout(timeout);
        navigator.serviceWorker.removeEventListener('controllerchange', controlled);
        worker?.removeEventListener('statechange', changed);
        error ? reject(error) : resolve();
      }
      function controlled() {
        if (navigator.serviceWorker.controller) finish();
      }
      function changed() {
        if (worker.state === 'redundant') finish(new Error('Offline worker installation failed'));
      }
      navigator.serviceWorker.addEventListener('controllerchange', controlled);
      worker?.addEventListener('statechange', changed);
      controlled();
      if (worker) changed();
    });
    window.location.reload();
    return true;
  } catch (error) {
    // Development builds have no generated worker; Drift can also use its
    // persistent fallback when service workers are unavailable.
    console.warn('Offline worker unavailable:', error);
    return false;
  }
}

prepareOfflineWorker().then(reloading => {
  if (reloading) return;
  return _flutter.loader.load({
    config: {canvasKitBaseUrl: 'canvaskit/'},
    onEntrypointLoaded: async function(engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    }
  });
});
