var readyStateCheckInterval = setInterval(function() {
    if (document.readyState === "interactive") {
        clearInterval(readyStateCheckInterval);
        // setUserLocation();
        console.log('ready!');
    }
}, 10);
